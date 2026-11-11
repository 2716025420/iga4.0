shader_type canvas_item;
uniform vec3 source_x;
uniform vec3 source_y;
uniform vec3 source_w;
uniform vec2 corner_a;
uniform vec2 corner_b;
uniform vec2 corner_c;
uniform vec2 corner_d;
uniform bool erase_nav_frames=false;
uniform int plate_count=0;
uniform vec4 plates[24];
varying vec4 item_tint;
float side(vec2 a,vec2 b,vec2 p){ return (b.x-a.x)*(p.y-a.y)-(b.y-a.y)*(p.x-a.x); }
void vertex(){ item_tint=COLOR; }
void fragment(){
	vec2 p=UV*vec2(1920.0,1080.0);
	vec3 q=vec3(p,1.0);
	vec2 source=vec2(dot(source_x,q),dot(source_y,q))/dot(source_w,q);
	float inside=step(0.0,side(corner_a,corner_b,p))*step(0.0,side(corner_b,corner_c,p))*step(0.0,side(corner_c,corner_d,p))*step(0.0,side(corner_d,corner_a,p));
	vec2 native_source=source*vec2(1672.0/1920.0,941.0/1080.0);
	float content=0.0;
	for(int i=0;i<24;i++){
		if(i>=plate_count){break;}
		vec4 r=plates[i];
		float radius=min(10.0,min(r.z,r.w)*0.25);
		vec2 distance_to_box=abs(native_source-r.xy-r.zw*0.5)-r.zw*0.5+radius;
		float distance_to_edge=length(max(distance_to_box,vec2(0.0)))+min(max(distance_to_box.x,distance_to_box.y),0.0)-radius;
		content=max(content,1.0-smoothstep(-0.8,0.8,distance_to_edge));
	}
	// CanvasItem uses straight alpha. Multiplying RGB by the mask as well
	// darkens antialiased edges twice, producing a second dark border.
	vec4 color=texture(TEXTURE,source/vec2(1920.0,1080.0))*item_tint;
	// Navigation skins are drawn once by the live buttons. Remove their baked
	// copies from the common rail so scaling and hover cannot double the rim.
	if(erase_nav_frames && native_source.x>=156.0 && native_source.x<=352.0){
		float row=floor((native_source.y-204.0)/71.0);
		float row_y=native_source.y-204.0-row*71.0;
		if(row>=0.0 && row<6.0 && row_y<=70.0){
			color=texture(TEXTURE,vec2(155.0,native_source.y)/vec2(1672.0,941.0))*item_tint;
		}
	}
	color.a*=inside*content;
	COLOR=color;
}
