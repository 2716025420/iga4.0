shader_type canvas_item;
varying vec4 item_tint;
void vertex(){item_tint=COLOR;}
void fragment(){
	vec4 c=texture(TEXTURE,UV);
	float g=dot(c.rgb,vec3(.299,.587,.114));
	COLOR=vec4(vec3(g)*.65+.2,c.a)*item_tint;
}
