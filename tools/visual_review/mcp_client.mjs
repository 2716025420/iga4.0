import {client,connect} from './school_mcp.mjs';
import fs from 'node:fs';
await connect();
try {
  if(process.argv[2]==='list') console.log(JSON.stringify((await client.listTools()).tools.filter(t=>!process.argv[3]||t.name.match(process.argv[3]))));
  else {
    const input=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
    for(const call of (Array.isArray(input)?input:[input])) {
      const result=await client.callTool(call,undefined,{timeout:60000});
      if(call.output) fs.writeFileSync(call.output,JSON.stringify(result));
      if(call.capture) {
        fs.mkdirSync(call.capture.substring(0,call.capture.lastIndexOf('/')),{recursive:true});
        const img=result.content?.find(c=>c.type==='image');
        if(img) fs.writeFileSync(call.capture,Buffer.from(img.data,'base64'));
        for(const item of result.content??[]) if(item.type==='text') {
          try {const data=JSON.parse(item.text); const path=data.absolute_path??data.file_path??data.path??data.saved_path; if(path && fs.existsSync(path)) fs.copyFileSync(path,call.capture);} catch {}
        }
      }
      console.log(JSON.stringify({...result,content:result.content?.map(c=>c.type==='image'?{type:'image',saved:call.capture}:c)}));
      if(call.delay) await new Promise(r=>setTimeout(r,call.delay));
    }
  }
} finally {await client.close();}
