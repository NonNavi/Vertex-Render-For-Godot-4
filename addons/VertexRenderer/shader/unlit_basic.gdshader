shader_type spatial;

render_mode unshaded; // You can add any render_mode flags before the include, except for world_vertex_coords
#include "vertex_shader.gdshaderinc"

uniform sampler2D color_sample : source_color,filter_linear;
uniform vec3 tint : source_color = vec3(1.0);

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
	ALBEDO = texture(color_sample,uv).rgb * tint.rgb;
	ALBEDO *= COLOR.rgb * shader_result;
}
