shader_type spatial;
render_mode unshaded;
#include "vertex_shader.gdshaderinc"

uniform sampler2D reflector_sample : source_color,filter_linear;
uniform vec3 tint : source_color = vec3(1.0);

uniform vec2 uv_reflector_offset = vec2(0.0);
uniform vec2 uv_reflector_scale = vec2(1.0);

void fragment(){
	vec2 proj_uv = vec2(NORMAL.x / 2.0 + 0.5, (-NORMAL.y) / 2.0 + 0.5) * uv_reflector_scale + uv_reflector_offset;
	ALBEDO = texture(reflector_sample,proj_uv).rgb * vertex_color.rgb;
	ALBEDO *= (COLOR.rgb);
}