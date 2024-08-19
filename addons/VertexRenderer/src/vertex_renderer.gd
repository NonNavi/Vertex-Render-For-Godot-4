@tool
extends Node

enum LIGHT_TYPE{
	OMNI = 1,
	SPOT = 2,
	DIRECT = 3,
	RECT = 4
}

class PackedLight:
	var position : Vector3
	var orientation : Vector3
	@warning_ignore("shadowed_global_identifier")
	var range : float = 1.0
	var attenuation : float = 1.0
	var strength : float = 1.0
	var angle : float = 0.0 # ONlY USED FOR SPOTLIGHTS
	var angle_attenuation : float = 0.0 # ONLY USED FOR SPOTLIGHTS
	var type : LIGHT_TYPE = LIGHT_TYPE.OMNI
	var color : Color = Color.WHITE

##Updates the shader every [method _process] call.
var real_time : bool = true
##Skips [method _add_nodes_to_group], if this is enabled the user will need to manually put the lights in the Light group.
var skip_ready : bool = false

signal gather_lights_finished
signal environment_updated
signal create_image_array_finished
signal create_layered_texture_finished
signal pass_to_rendering_server_finished

func _process(_delta):
	if Engine.is_editor_hint() or real_time:
		call_thread_safe("update_shader")
	await pass_to_rendering_server_finished
func _ready():
	process_thread_group = ProcessThreadGroup.PROCESS_THREAD_GROUP_SUB_THREAD
	
	get_tree().node_added.connect(_on_node_added)
	if skip_ready:
		_add_nodes_to_group()
	update_shader()

func _add_nodes_to_group():
	var nodes = get_children(true)
	for node in nodes:
		if node is Light3D:
			node.add_to_group("Light")
func _on_node_added(node : Node):
	if not(node is Light3D):
		return
	node.add_to_group("Light")

func update_shader():
	if Engine.is_editor_hint():
		update_environment(get_tree().edited_scene_root)
	else:
		update_environment(get_tree().current_scene)
	await environment_updated
	var packedLights = _gather_lights()
	await gather_lights_finished
	
	for pckLight in packedLights:
		if pckLight == null:
			break
	var imageArray = _create_image_array(packedLights)
	await create_image_array_finished
	
	var texture = _create_layered_texture(imageArray)
	await create_layered_texture_finished
	
	if texture:
		RenderingServer.global_shader_parameter_set("scene_lightmap",texture)
		RenderingServer.global_shader_parameter_set("scene_lightmap_count",imageArray.size() - 1)
		pass_to_rendering_server_finished.emit()

func update_environment(node : Node):
	var environment : Environment
	
	var ambient_color : Color
	var minimum_light : float = 0.0
	
	if node is Node3D:
		environment = node.get_world_3d().environment
	elif node is WorldEnvironment:
		if node.environment != null:
			environment = node.environment
	
	if environment:
		ambient_color = environment.background_color
		minimum_light = environment.background_energy_multiplier
		if environment.background_mode == Environment.BG_SKY:
			ambient_color = environment.ambient_light_color
			minimum_light = environment.ambient_light_energy
		
		
		RenderingServer.global_shader_parameter_set("ambient_light_color",Vector3(ambient_color.r,ambient_color.g,ambient_color.b))
		RenderingServer.global_shader_parameter_set("minimum_light",ambient_color.v * minimum_light)
	
	call_deferred("emit_signal","environment_updated")
#Takes all the nodes inside the "Light" group and extracts the information and makes a PackedLight out of that
func _gather_lights() -> Array[PackedLight]:
	var lights := get_tree().get_nodes_in_group("Light")
	var r : Array[PackedLight] = []
	for light in lights:
		if (light is Light3D):
			if light.visible:
				var light_orientation = light.global_basis * Vector3.FORWARD
				var packedLight = PackedLight.new()
				packedLight.position = light.global_position
				packedLight.orientation = light_orientation
				packedLight.strength = light.light_energy
				packedLight.color = light.light_color
				
				if light is OmniLight3D:
					packedLight.range = light.omni_range
					packedLight.attenuation = light.omni_attenuation
					packedLight.type = LIGHT_TYPE.OMNI
				elif light is SpotLight3D:
					packedLight.range = light.spot_range
					packedLight.attenuation = light.spot_attenuation
					#Translate degrees to units
					packedLight.angle = cos(deg_to_rad(light.spot_angle));
					packedLight.angle_attenuation = cos(deg_to_rad(light.spot_angle)) + (cos(deg_to_rad(light.spot_angle)) * (light.spot_angle_attenuation))
					packedLight.type = LIGHT_TYPE.SPOT
				elif light is DirectionalLight3D:
					packedLight.range = -1
					packedLight.attenuation = light.light_indirect_energy
					packedLight.type = LIGHT_TYPE.DIRECT
				
				r.append(packedLight)
	call_deferred("emit_signal","gather_lights_finished")
	return r
#Using the result of _gather_lights, the data is stored inside an image array.
#[0,0] holds - positional data in RGB and Strength in ALPHA
#[1,0] holds - color data in RGB and Range in ALPHA
#[0,1] holds - local forward direction in RGB and Type in ALPHA
#[1,1] holds - angle in R, angle attenuation in G, and attenuation in B, Alpha is unused.
func _create_image_array(packedLights : Array[PackedLight]) -> Array[Image]:
	var imgArray : Array[Image] = []
	
	if packedLights.is_empty():
		var image : Image = Image.create(2,2,false,Image.FORMAT_RGBAF)
		image.set_pixel(0,0,Color(Color.BLACK,0.0))
		image.set_pixel(1,0,Color(Color.BLACK,0.0))
		image.set_pixel(0,1,Color(Color.BLACK,0.0))
		image.set_pixel(1,1,Color(Color.BLACK,0.0))
		imgArray=[image]
		call_deferred("emit_signal","create_image_array_finished")
		return imgArray
	
	for pckLight in packedLights:
		var image : Image = Image.create(2,2,false,Image.FORMAT_RGBAF)
		if pckLight == null:
			image.set_pixel(0,0,Color(Color.BLACK,0.0))
			image.set_pixel(1,0,Color(Color.BLACK,0.0))
			image.set_pixel(0,1,Color(Color.BLACK,0.0))
			image.set_pixel(1,1,Color(Color.BLACK,0.0))
		else:
			image.set_pixel(0,0,Color(pckLight.position.x,pckLight.position.y,pckLight.position.z,pckLight.strength))
			image.set_pixel(1,0,Color(pckLight.color,pckLight.range))
			image.set_pixel(0,1,Color(pckLight.orientation.x,pckLight.orientation.y,pckLight.orientation.z,float(pckLight.type)))
			image.set_pixel(1,1,Color(pckLight.angle,pckLight.angle_attenuation,pckLight.attenuation,0.0))
		imgArray.append(image)
	call_deferred("emit_signal","create_image_array_finished")
	return imgArray
# Creates a layered texture this texture is the texture uploaded to the scene_lightmap shader global
func _create_layered_texture(imageArray : Array[Image]) -> ImageTextureLayered:
	if imageArray.is_empty():
		return
	
	var texture = Texture2DArray.new()
	var err = texture.create_from_images(imageArray)
	if err != OK:
		print_debug(error_string(err))
		call_deferred("emit_signal","create_layered_texture_finished")
		return null
	call_deferred("emit_signal","create_layered_texture_finished")
	return texture
