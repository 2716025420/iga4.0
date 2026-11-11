import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {pathToFileURL} from 'node:url';

// Resolve an existing installation. Never download a server or open a second editor.
function resolveServer() {
  const relative='node_modules/@npgamedev/godot-mcp-server/dist/index.js';
  const candidates=[process.env.GODOT_MCP_SERVER_ENTRY,path.join(process.cwd(),relative)].filter(Boolean);
  const caches=[process.env.npm_config_cache,
    path.join(os.homedir(),'AppData/Local/npm-cache'),path.join(os.homedir(),'.npm')].filter(Boolean);
  for(const cache of caches) {
    const root=path.join(cache,'_npx');
    if(!fs.existsSync(root)) continue;
    const folders=fs.readdirSync(root,{withFileTypes:true}).filter(x=>x.isDirectory())
      .map(x=>path.join(root,x.name)).sort((a,b)=>fs.statSync(b).mtimeMs-fs.statSync(a).mtimeMs);
    for(const folder of folders) candidates.push(path.join(folder,relative));
  }
  const found=candidates.find(file=>fs.existsSync(file));
  if(!found) throw new Error('No installed Godot MCP server. Set GODOT_MCP_SERVER_ENTRY to its dist/index.js.');
  return path.resolve(found);
}
const server=resolveServer();
let sdkRoot;
for(let directory=path.dirname(server);;directory=path.dirname(directory)) {
  const candidate=path.join(directory,'@modelcontextprotocol/sdk/dist/esm/client');
  if(fs.existsSync(path.join(candidate,'index.js'))) {sdkRoot=candidate;break;}
  if(path.dirname(directory)===directory) break;
}
if(!sdkRoot) throw new Error('The installed Godot MCP server has no adjacent MCP SDK.');
const {Client}=await import(pathToFileURL(path.join(sdkRoot,'index.js')).href);
const {StdioClientTransport}=await import(pathToFileURL(path.join(sdkRoot,'stdio.js')).href);
export const client=new Client({name:'iga-local-review',version:'2.0'});
const transport=new StdioClientTransport({command:process.execPath,args:[server],env:{...process.env,GODOT_MCP_CONFIG_VERSION:'1',GODOT_MCP_PROJECT_PATH:process.cwd()},stderr:'pipe'});
export const read=path=>fs.readFileSync(path,'utf8');
export async function connect(){await client.connect(transport);}
export async function call(name,args={}) {
  const raw=await client.callTool({name,arguments:args},undefined,{timeout:60000});
  const message=raw.content?.find(c=>c.type==='text')?.text??'';
  let result;
  try {result=JSON.parse(message);} catch {throw new Error(name+': '+(message||'MCP returned no JSON result'));}
  if(raw.isError||result.success===false||result.valid===false) throw new Error(name+': '+JSON.stringify(result));
  return result;
}
export async function write(path,content){const r=await call('script_write',{file_path:'res://'+path,content});console.log(path,JSON.stringify(r));}
export async function edit(path,old_string,new_string){const r=await call('script_edit',{file_path:'res://'+path,old_string,new_string});console.log(path,JSON.stringify(r));}
export const expression=async(code,scope_path)=>(await call('execute_code',{code,...(scope_path?{scope_path}:{})})).result;
export const sleep=ms=>new Promise(r=>setTimeout(r,ms));
export async function waitFor(code,scope){for(let i=0;i<100;i++){if(await expression(code,scope))return;await sleep(80);}throw new Error('Timeout '+code);}
export async function click(code,scope){const c=await expression(code+'.get_global_rect().get_center()',scope),t=await expression("{'scale':get_viewport().get_final_transform().get_scale(),'origin':get_viewport().get_final_transform().origin}");await call('input_simulate',{events:{event_type:'click',event_data:{position:{x:c.x*t.scale.x+t.origin.x,y:c.y*t.scale.y+t.origin.y}},delay_after_ms:170}});}
export async function key(keycode){await call('input_simulate',{events:[{event_type:'key',event_data:{keycode,pressed:true},delay_after_ms:50},{event_type:'key',event_data:{keycode,pressed:false},delay_after_ms:170}]});}
export async function capture(name,outputDirectory='.godot/visual-review'){await sleep(220);const r=await call('runtime_screenshot',{image_response_mode:'disk'});fs.mkdirSync(outputDirectory,{recursive:true});const target=path.resolve(outputDirectory,name+'.png');fs.copyFileSync(r.path,target);return target;}
