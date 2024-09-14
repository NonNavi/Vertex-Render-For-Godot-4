@tool
extends EditorPlugin

const SOURCE_PATH := "res://addons/VertexRenderer/"

const SCENE_LIGHTMAP_PLACEHOLDER := preload("res://addons/VertexRenderer/scene_lightmap_placeholder.res")
const SINGLETON_PATH := SOURCE_PATH + "src/vertex_renderer.gd"
const SHADER_GLOBALS := {
	"scene_lightmap":[RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2DARRAY,SCENE_LIGHTMAP_PLACEHOLDER],
	"scene_lightmap_count":[RenderingServer.GLOBAL_VAR_TYPE_INT,0],
	"ambient_light_color":[RenderingServer.GLOBAL_VAR_TYPE_VEC3,Vector3.ZERO],
	"minimum_light":[RenderingServer.GLOBAL_VAR_TYPE_FLOAT,0.0],
}

func _enter_tree() -> void:
	add_autoload_singleton("VertexRenderer",SINGLETON_PATH)
	
	var globals = RenderingServer.global_shader_parameter_get_list()
	for key in SHADER_GLOBALS.keys():
		if not(key in globals):
			RenderingServer.global_shader_parameter_add(key,SHADER_GLOBALS[key][0],SHADER_GLOBALS[key][1])
	ProjectSettings.save()

func _exit_tree() -> void:
	remove_autoload_singleton("VertexRenderer")
