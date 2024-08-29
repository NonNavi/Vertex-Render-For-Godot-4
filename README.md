# Vertex-Render for Godot 4
 Vertex rendering reimplemented for Godot 4

## DISCLAIMER
 This addon is a work in progress and changes to the shader include may occur in the future, I recommend using shaders with the render flag "unshaded" as they're the most consistent, and
 wont change much with future updates to the addon.

## How to use
 Extract the *addons* folder and add it to your project, once the files are added, go to *ProjectSettings > Plugins* and enable *VertexRenderer*, once this is done reload your project.
 The plugin should automatically add the shader globals necessary for the shader include to work, as well as the Singleton.<br>
 When adding the plugin reload the scene, this will reload the Script used for gathering the lighting information.

 For the new rendering to work, all your materials would need to be ShaderMaterials, inside ***"res://addons/VertexRenderer/shader/"*** you'll find ***vertex_shader.gdshaderinc*** 
 alongside sample shaders to get you an idea in how to implement your own shaders, you can also check out ***vertex_shader.gdshaderinc*** to see the what definitions might suit your needs.<br> 
 check the [Custom Code](https://github.com/NonNavi/Vertex-Render-For-Godot-4?tab=readme-ov-file#custom-code) section for more info on that.

### Changing scenes

Since there's no *scene_changed* signal built-in, the Singleton doesnt have a way to know when a scene has changed and *if* it should re-scan the scene nodes for Light3D type nodes,
so you have to let ***VertexRenderer*** know when to scan for nodes to add to the *Ligth* group, this is only necessary if you dont manually add the Light nodes to the "Light" group,
use *update_nodes_group* to re-scan the scene nodes, take into account that this will have a performance hit the larger the amount of nodes in the scene.

### SpotLights & OmniLights

Most of the parameters of the light are taken into account, such as:
- position
- rotation
- energy
- color
- angle **spotlights only*
- angle attenuation **spotlights only*
- attenuation
- range
  
### DirctionalLight

DirctionalLights behave differently than OmniLights and Spotlights,
only the following parameters are taken into account:
- position
- rotation
- color
- energy
- inderect energy<br>
this last one is used like angular distance, diffusing the light and making the light expand more.

### Ambient light

as long as you dont add **render_mode unshaded**, to your shader using the shader include, *Ambient light* should behave like it does normally although a bit more muted,
if you are using the *Sky mode* for the *Environment* background, ambient color and energy is changed from the *Background* tab to the *Ambient Light* tab.
If you feel like the Sky light is too dim, I recommend changing *Color* in *Ambient light* (ambient_light_color) to a neutral grey.

## Custom Code.
- ### Basic Code
Before we can start to make our own shaders we need to cover the basics of the shader, sample shaders are provided, 
this will serve more as documentation and somewhere to come back to know how to make the shader work.
```GLSL
shader_type spatial;
//We can add this before or after we include the vertex shader.
render_mode unshaded;

//Without this the renderer wont work.
#include "addons/VertexRenderer/shader/vertex_shader.gdshaderinc"

void fragment(){
	// Your code here...
	
	// The result of the shading process is stored in shader_result
	// We need to multiply the Shader result to the ALBEDO to make the shading visible. 
	ALBEDO *= shader_result;
   }
```
- ### Built-in Pixel Shading compatibility
I recommend sticking to using unshaded shaders, as they're the most stable, however in case you need the shader to use more complicated graphical effects like, SSAO,
SSIL, SDFGI, SSR, ReflectionProbes, Hemishperic Ambient Light and such, you'll need to change your code a bit to accomodate for that.
```GLSL
shader_type spatial;

//Without this the renderer wont work.
#include "addons/VertexRenderer/shader/vertex_shader.gdshaderinc"

void fragment(){
	// Your code here...
   }
// We override the light function to give it our own light information, this can caused blocky light sources if done incorrectly. 
void light(){
	DIFFUSE_LIGHT = shader_result;
}
```
- ### Vertex Code
*vertex_shader.gdshaderinc* uses the vertex pass function for all the shading, so custom code is impossible without a special definition, ***#define CUSTOM_CODE*** will tell the shader include
to change the way it works, this can be forced if your prefer it but changes to your shader code need to be made for the Vertex Renderer to work.
```GLSL
shader_type spatial;

// We define CUSTOM_VERTEX to let the include know we want to use custom vertex code
#define CUSTOM_VERTEX

render_mode unshaded;
#include "addons/VertexRenderer/shader/vertex_shader.gdshaderinc"

void vertex(){
 	ShaderResult shader; // Struct to store the result of vertex_shade
	
 	// vertex_shade, this function does the same as the regular vertex function,
 	// however it will return a ShaderResult struct.
	shader = vertex_shade(VERTEX,NORMAL,MODEL_MATRIX);
	
	shader_result= shader.result;
   }
```
We need to pass the MODEL_MATRIX so the Vertex position and Normal are translated from local space to world space, In the case that you need to make a shader that requires the render flag
**world_vertex_coords** use the definition **WORLD_SPACE_COORDINATES** and add the render flag **world_vertex_coords**, no more custom code needed to make it work, this is an example of a shader that uses said definition.
```GLSL
shader_type spatial;

#define CUSTOM_VERTEX
#define WORLD_SPACE_COORDINATES // Changes how Light sources are calculated to ignore matrix transformations.

// we need to add "world_vertex_coords" otherwise the lighting will mismatch.
render_mode world_vertex_coords,unshaded;
#include "vertex_shader.gdshaderinc"

void vertex(){
	ShaderResult shade;
	// We still need to pass a value for the 3rd argumentm however it wont be used so you can pass any value here it wont matter.
	shade = vertex_shade(VERTEX,NORMAL,MODEL_MATRIX);
	shader_result = shade.result;

	// for this example I made the shader round it's position to the nearest 4 decimal number, I need the *world_space_coords* render flag so it stay on the grid
	// Round vertex position with 4 decimals
	VERTEX = floor(VERTEX) + round(fract(VERTEX) * 4.0) * 0.25;
}
```
This are the *BASICS* for your code to have the result of the Shader, the important part is the *ShaderResult* struct and the *vertex_shade* function, the *ShaderResult* is a struct
so it stores more data than the result of the shading process.
```GLSL
struct ShaderResult{
	lowp vec3 result; // Final result of the Shader
	lowp float brightness; // Final brightness of the Shader
	lowp vec3 color; // Final color of the Shader
};
```
ShaderResult stores 3 values, in case you need the Brightness or Color for your code, This values can be retrieved normally with "final_color" and "final_brightness".

 ## Known Issues
 - ### Everything is black/unshaded at runtime
 Check your Debugger log, and check for any shader global related errors or warnings, if that is the case, reload your project.<br>
 If your error is not related to missing shder globals, consider reporting it [here](https://github.com/NonNavi/Vertex-Render-For-Godot-4/issues).
 - ### My scene looks too bright.
 Keep in mind that if your scene has no light sources and you come from a scene that does, the lighting information will be carried over the new scene, in theory the singleton should
 take care of updating the lightmap when a new scene loads ( note: this only happens automatically inside the editor, check [Changing Scene](https://github.com/NonNavi/Vertex-Render-For-Godot-4?tab=readme-ov-file#changing-scenes) ),
 you can force the update by adding a Light3D node to the scene.
 - ### All lights are missing at runtime
 Lights should be part of the "Light" group, otherwise they wont be taken into account, *vertex_renderer.gd* should intercept new nodes and add them to the Light group,
 when the you run your project *vertex_renderer.gd* will scan for all nodes inside the scene and add them to the group, however this only happens when *update_nodes_group* is called
 refer to [Changing Scenes](https://github.com/NonNavi/Vertex-Render-For-Godot-4?tab=readme-ov-file#changing-scenes) for more information on that.
 - ### New lights are not updating
 The shader include has a **MAX_LIGHT** constant, this can be changed if necessary
 - ### Negative attenuation makes everything else black
This is an issue in the vertex_render.gd script, values are not capped, I recommend not going below zero for OmniLights
 - ### Big pixels surrounding my light sources
This issue is caused by the light function, since we're changing the way the light behaves without telling the engine, graphical errors like this are common, you can mitigate this by 
checking the shader of the material that presents this error and revise the light function, this is very apparent with low poly models and big light sources with high attenuation values.
Make sure it's behaviour lines up with what was discussed at [Custom Code](https://github.com/NonNavi/Vertex-Render-For-Godot-4?tab=readme-ov-file#custom-code)
 - ### Weird lighting on imported scene/model
Make sure the origins of the objects are correct and are close to the mesh, this applies with rotation and scale as well.

## Recommendations for your Project
- If you're not planning in using effects like SSAO or SSIL, I suggest adding **render_mode unshaded**, this however will make Ambient light behave differently.
- I recommend adding the Light's to the Light group manually, make it so is a Global Group and adding the nodes to the group is easier.

