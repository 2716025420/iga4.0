shader_type canvas_item;
render_mode unshaded;

uniform sampler2D blink_texture : source_color, filter_linear;
uniform float elapsed = 0.0;
uniform float strength = 1.0;
uniform vec2 gaze = vec2(0.0);
uniform float blink : hint_range(0.0, 1.0) = 0.0;
varying vec4 portrait_tint;

void vertex() {
 portrait_tint = COLOR;
}

float oval(vec2 uv, vec2 center, vec2 radius) {
 vec2 q = (uv-center)/radius;
 return exp(-dot(q,q)*2.0);
}

void fragment() {
 vec2 uv = UV;
 float breath = sin(elapsed*1.32);
 float head = oval(uv,vec2(0.328,0.225),vec2(0.16,0.235));
 float torso = oval(uv,vec2(0.305,0.435),vec2(0.15,0.215));
 float braid = oval(uv,vec2(0.271,0.385),vec2(0.045,0.20));
 float tips = oval(uv,vec2(0.421,0.240),vec2(0.045,0.16));
 // Smooth weights fade out before the chair and lower body. No whole-sprite bob.
 float upper = 1.0-smoothstep(0.52,0.70,uv.y);
 vec2 shift = vec2(0.0);
 shift.y += breath*(0.0013*head+0.0011*torso);
 shift.x += sin(elapsed*0.71)*0.0007*head;
 shift += gaze*head*vec2(0.0022,0.0012);
 shift.x += sin(elapsed*1.05+uv.y*7.0)*0.0014*(braid+tips);
 uv -= shift*upper*strength;
 vec4 original = texture(TEXTURE,uv);
 vec4 closed = texture(blink_texture,uv);
 // Blend only the eye/glasses region; generated changes elsewhere never appear.
 float eyes = smoothstep(0.265,0.292,uv.x)*(1.0-smoothstep(0.385,0.410,uv.x));
 eyes *= smoothstep(0.151,0.176,uv.y)*(1.0-smoothstep(0.273,0.302,uv.y));
 COLOR = mix(original,closed,blink*eyes)*portrait_tint;
}
