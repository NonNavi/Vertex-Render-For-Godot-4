shader_type spatial;

#define CUSTOM_VERTEX
#define WORLD_SPACE_COORDINATES

render_mode world_vertex_coords;
#include "vertex_shader.gdshaderinc"

uniform sampler2D color_sample : source_color,filter_linear;
uniform vec3 tint : source_color = vec3(1.0);

uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);

uniform vec2 uv_scroll = vec2(0.0);

uniform sampler2D noise_sample : hint_default_black,filter_linear;

void vertex(){
	ShaderResult shade;
	shade = vertex_shade(VERTEX,NORMAL,MODEL_MATRIX);
	
	final_brightness = shade.brightness;
	final_color = shade.color;
	
	shader_result = shade.result;
	float offset = texture(noise_sample,UV).r;
	VERTEX += NORMAL * offset;
	
	// Round vertex position with 4 decimals
	VERTEX = floor(VERTEX) + round(fract(VERTEX) * 4.0) * 0.25;
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
	ALBEDO *= COLOR.rgb;
}


void light(){
	DIFFUSE_LIGHT = shader_result;
}

