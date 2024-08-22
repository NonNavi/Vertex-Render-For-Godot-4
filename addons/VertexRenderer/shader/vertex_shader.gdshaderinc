#ifndef USE_LOCAL_COORDS
render_mode world_vertex_coords;
#endif

varying vec4 vertex_color;
#ifdef RETRIEVE_BRIGHTNESS
varying float final_brightness;
#endif
#ifdef RETRIEVE_COLOR
varying vec3 final_color;
#endif

const int MAX_LIGHTS = 128;

uniform float light_scale : hint_range(0.0, 10.0) = 1.0;

global uniform sampler2DArray scene_lightmap : repeat_disable,filter_nearest; // Uploaded via a node at scene _ready
global uniform int scene_lightmap_count; // Uploaded via node at scene _ready
global uniform vec3 ambient_light_color;
global uniform float minimum_light;

const int TYPE_OMNILIGHT = 1;
const int TYPE_SPOTLIGHT = 2;
const int TYPE_DIRECT = 3;
const int TYPE_RECT = 4; // Unused

struct Light{
	lowp vec3 color;
	highp vec3 orientation;
	highp vec3 position;
	lowp float strength;
	lowp float attenuation;
	
	lowp float angle;
	lowp float angle_attenuation;
	mediump float range;
	lowp int type;
};
#ifdef CUSTOM_VERTEX
struct ShaderResult{
	lowp vec3 result;
	lowp float brightness;
	lowp vec3 color;
};
#endif

float calculate_brightness(Light light,vec3 normal,vec3 vertex){
	float distance_from_vertex = 1.0 - min(distance(light.position,vertex) / light.range,1.0); // simple linear falloff
	vec3 light_dir = normalize(light.position - vertex); // get direction of the vertex
	float brightness = clamp((dot(normal,light_dir)) * distance_from_vertex,0.0,1.0);
	brightness = pow(brightness,light.attenuation);
	float attenuation = 1.0 / (1.0 + light.attenuation * distance_from_vertex * (distance_from_vertex * distance_from_vertex));
	
	return brightness * attenuation;
}
float calculate_brightness_direct(Light light,vec3 normal){
	vec3 biased_light = mix(-light.orientation,normal,light.attenuation / 16.0);
	return max(dot(normal,biased_light),0.0);
}
// Main source https://learnopengl.com/Lighting/Light-casters
float calculate_brightness_spotlight(Light light,vec3 normal,vec3 vertex){
	vec3 light_dir = normalize(light.position - vertex); // Vector3 pointing to the light
	float theta = dot(light_dir,-light.orientation);
	float epsilon   = light.angle - light.angle_attenuation;
	float intensity = 1.0 - clamp((theta - light.angle_attenuation) / epsilon, 0.0, 1.0);    
	
	
	float distance_from_vertex = 1.0 - min(distance(light.position,vertex) / light.range,1.0); // simple linear falloff
	float brightness = clamp((dot(normal,light_dir)) * distance_from_vertex,0.0,1.0);
	brightness = pow(brightness,light.attenuation);
	float attenuation = 1.0 / (1.0 + light.attenuation * distance_from_vertex * (distance_from_vertex * distance_from_vertex));
	
	
	if(theta > light.angle){
		return intensity * (brightness * attenuation);
	}
	return 0.0;
}

// Fetch the data from the texture array
Light create_light(int idx){
	Light light;
	float idxTextArr = (float(idx) / float(scene_lightmap_count));
	
	light.position = texture(scene_lightmap,vec3(vec2(0.0,0.0),idxTextArr)).rgb;
	light.strength = texture(scene_lightmap,vec3(vec2(0.0,0.0),idxTextArr)).a;
	light.color = texture(scene_lightmap,vec3(vec2(1.0,0.0),idxTextArr)).rgb;
	light.range = texture(scene_lightmap,vec3(vec2(1.0,0.0),idxTextArr)).a;
	
	
	light.orientation = texture(scene_lightmap,vec3(vec2(0.0,1.0),idxTextArr)).rgb;
	light.type = int(texture(scene_lightmap,vec3(vec2(0.0,1.0),idxTextArr)).a);
	
	light.angle = texture(scene_lightmap,vec3(vec2(1.0,1.0),idxTextArr)).r;
	light.angle_attenuation = texture(scene_lightmap,vec3(vec2(1.0,1.0),idxTextArr)).g;
	light.attenuation = max(texture(scene_lightmap,vec3(vec2(1.0,1.0),idxTextArr)).b,0.0);
	return light;
}
#ifdef CUSTOM_VERTEX
ShaderResult vertex_shade(vec3 vertex,vec3 normal){
	ShaderResult result;
	// Direct light
	
	
	result.brightness = 0.0;
	result.color = vec3(0.0);
	Light light;
	//Main light cycle
	for(int i = 0;i < MAX_LIGHTS;i++){
		if(i > scene_lightmap_count){
			break;
		}
		light = create_light(i * scene_lightmap_count);
		float current_brightness = 0.0;
		switch(light.type){
			case TYPE_OMNILIGHT:
				current_brightness = calculate_brightness(light,normal,vertex);
				break;
			case TYPE_DIRECT:
				current_brightness = calculate_brightness_direct(light,normal);
				break;
			case TYPE_SPOTLIGHT:
				current_brightness = calculate_brightness_spotlight(light,normal,vertex);
				break;
			default:
				current_brightness = calculate_brightness(light,normal,vertex);
				break;
		}
		current_brightness *= light.strength;
		result.brightness = result.brightness + current_brightness;
		result.color = result.color + (light.color * current_brightness);
	}
	result.color = clamp(result.color,vec3(0.0),vec3(1.0));
	result.color += ambient_light_color * minimum_light;
	result.brightness = clamp(result.brightness,minimum_light,256.0);
	
	result.result = clamp((result.color * result.brightness) * light_scale,vec3(0.0),vec3(256.0));
	return result;
}
#endif

#ifndef CUSTOM_VERTEX
void vertex() {
	vertex_color = COLOR;
	// Direct light
	lowp float v_brightness = 0.0;
	lowp vec3 v_color = vec3(0.0);
	
	Light light;
	//Main light cycle
	for(int i = 0;i < MAX_LIGHTS;i++){
		if(i > scene_lightmap_count){
			break;
		}
		light = create_light(i * scene_lightmap_count);
		float current_brightness = 0.0;
		switch(light.type){
			case TYPE_OMNILIGHT:
				current_brightness = calculate_brightness(light,NORMAL,VERTEX);
				break;
			case TYPE_DIRECT:
				current_brightness = calculate_brightness_direct(light,NORMAL);
				break;
			case TYPE_SPOTLIGHT:
				current_brightness = calculate_brightness_spotlight(light,NORMAL,VERTEX);
				break;
			default:
				current_brightness = calculate_brightness(light,NORMAL,VERTEX);
				break;
		}
		current_brightness *= light.strength;
		v_brightness = v_brightness + current_brightness;
		v_color = v_color + (light.color * current_brightness);
	}
	v_color = clamp(v_color,vec3(0.0),vec3(1.0));
	v_color += ambient_light_color * minimum_light;
	v_brightness = clamp(v_brightness,minimum_light,256.0);
	
	#ifdef RETRIEVE_BRIGHTNESS
	final_brightness = clamp(v_brightness * light_scale,0.0,1.0);
	#endif
	#ifdef RETRIEVE_COLOR
	final_color = clamp(v_color * light_scale,0.0,256.0);
	#endif
	COLOR.rgb = clamp((v_color * v_brightness) * light_scale,vec3(0.0),vec3(256.0));
}
#endif