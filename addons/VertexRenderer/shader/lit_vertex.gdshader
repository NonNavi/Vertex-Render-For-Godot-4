shader_type spatial;

#define CUSTOM_VERTEX
#include "vertex_shader.gdshaderinc"

uniform sampler2D color_sample : source_color,filter_linear;
uniform vec3 tint : source_color = vec3(1.0);

uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);

uniform vec2 uv_scroll = vec2(0.0);

uniform sampler2D noise_sample : hint_default_black,filter_linear;

varying vec3 final_color;
varying float final_brightness;
void vertex(){
	ShaderResult shade;
	shade = vertex_shade(VERTEX,NORMAL);
	
	final_brightness = shade.brightness;
	final_color = shade.color;
	
	vertex_color = COLOR;
	
	COLOR.rgb = shade.result;
	
	float offset = texture(noise_sample,UV).r;
	VERTEX += NORMAL * offset;
}

void fragment(){
	vec2 uv = (UV + uv_offset) * uv_scale;
	if(uv_scroll != vec2(0.0)){
		uv += uv_scroll * (TIME * 0.01);
	}
	
	if(texture(color_sample,uv).a < 0.25){
		discard;
	}
	
	ALBEDO = texture(color_sample,uv).rgb * tint.rgb;
	ALBEDO *= COLOR.rgb * vertex_color.rgb;
}


void light(){
	DIFFUSE_LIGHT = vec3(final_color) * final_brightness;
}

