shader_type spatial;

#include "vertex_shader.gdshaderinc"

uniform sampler2D color_sample : source_color,filter_linear;
uniform vec3 tint : source_color = vec3(1.0);

group_uniforms PBR;// The shader is compatible with PBR effects except for NormalMaps.
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float specular : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;


uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);

uniform vec2 uv_scroll = vec2(0.0);
void fragment(){
	vec2 uv = (UV + uv_offset) * uv_scale;
	if(uv_scroll != vec2(0.0)){
		uv += uv_scroll * (TIME * 0.01);
	}
	
	if(texture(color_sample,uv).a < 0.25){
		discard;
	}
	ROUGHNESS = roughness;
	SPECULAR = specular;
	METALLIC = metallic;
	
	
	ALBEDO = texture(color_sample,uv).rgb * tint.rgb;
	ALBEDO *= COLOR.rgb;
}

void light(){
	DIFFUSE_LIGHT = shader_result;
}
