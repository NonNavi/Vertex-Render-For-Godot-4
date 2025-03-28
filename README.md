# Vertex-Render for Godot 4.x
 Vertex rendering reimplemented for Godot 4.x,  Godot 4.4 fixed Vertex Rendering making this addon unnecessary for Godot 4.4 onwards, however the addon allows for extra usability;

## DISCLAIMER
 This addon is a work in progress and changes to the shader include may occur in the future, I recommend using shaders with the render flag "unshaded" as they're the most consistent, and
 wont change much with future updates to the addon.

## How to use
 Extract the *addons* folder and add it to your project, once the files are added, go to *ProjectSettings > Plugins* and enable *VertexRenderer*, once this is done reload your project.
 The plugin should automatically add the shader globals necessary for the shader include to work, as well as the Singleton. The plugin should automatically add any Light3D type nodes into the Light group, even at runtime.

 For the new rendering to work, all your materials would need to be ShaderMaterials, inside ***"res://addons/VertexRenderer/shader/"*** you'll find ***vertex_shader.gdshaderinc*** 
 alongside sample shaders to get you an idea in how to implement your own shaders, you can also check out ***vertex_shader.gdshaderinc*** to see the what definitions might suit your needs.<br> 
 check the [Custom Code](https://github.com/NonNavi/Vertex-Render-For-Godot-4?tab=readme-ov-file#custom-code) section for more info on that.
 
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
this will serve more as documentation and somewhere to come back, to know how to make the shader work.
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
SSIL, ReflectionProbes, etc. and such, you'll need to change your code a bit to accomodate for that.
```GLSL
shader_type spatial;

//Without this the renderer wont work.
#include "addons/VertexRenderer/shader/vertex_shader.gdshaderinc"

void fragment(){
	// Your code here...
   }
// We override the light function to give it our own lighting information
// this can caused blocky outline outside the light range if done incorrectly or the mesh poly count is low.. 
void light(){
	DIFFUSE_LIGHT = shader_result;
}
```
- ### Vertex Code
*vertex_shader.gdshaderinc* uses the vertex pass function for all the shading, so custom code is impossible without a special definition, ***#define CUSTOM_CODE*** will tell the shader include
to change the way it works, this can be forced if your prefer it but changes to your shader code need to be made.
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
vertex_shade needs, VERTEX for position, NORMAL for orientation and MODEL_MATRIX for transformation, the shader is made to take into account local space vertex coordinates, and as such we need the
MODEL_MATRIX to transform the local space postion and orientation to world space.

- ### World Vertex Coords
In the case that you need to make a shader that requires the render flag **world_vertex_coords** use the definition **WORLD_SPACE_COORDINATES** and add the render flag **world_vertex_coords**,
no more custom code is needed on top of the basics already discussed, **WORLD_SPACE_COORDINATES** will tell the include to skip the transformation process entirely, this is an example of a shader that uses said definition.
```GLSL
shader_type spatial;

#define CUSTOM_VERTEX // Not necessary, used here just for demostration.
#define WORLD_SPACE_COORDINATES // Changes how Light sources are calculated to ignore matrix transformations.

// we need to add "world_vertex_coords" otherwise the lighting will mismatch.
render_mode world_vertex_coords,unshaded;
#include "vertex_shader.gdshaderinc"

void vertex(){
	ShaderResult shade;
	// We still need to pass a value for the 3rd argumentm however it wont be used so you can pass any value here it wont matter.
	shade = vertex_shade(VERTEX,NORMAL,MODEL_MATRIX);
	shader_result = shade.result;

	// Your code...
}
```
If you need a more practical use of the world_vertex_coords render flag check the sample shader *lit_vertex.gdshader* inside the "shader" folder.

 ## Known Issues
 - ### Everything is black/unshaded at runtime
 Check your Debugger log, and check for any shader global related errors or warnings, if that is the case, reload your project.<br>
 If your error is not related to missing shder globals, consider reporting it [here](https://github.com/NonNavi/Vertex-Render-For-Godot-4/issues).
 - ### My scene looks too bright.
 When you make a new scene the engine will create a DirectionalLight3D with it, you can get rid of this node by adding a DirectionalLight3D yourself and then removing it or simply hidding it.
 
 Keep in mind that if your scene has no light sources and you come from a scene that does, the lighting information will be carried over the new scene, in theory the singleton should
 take care of updating the lightmap when a new scene loads ( note: this only happens automatically if VertexRenderer.real_time is true), you can force the update by adding a Light3D node to the scene.
 
 - ### All lights are missing at runtime
 Lights should be part of the "Light" group, otherwise they wont be taken into account, *vertex_renderer.gd* should intercept new nodes and add them to the Light group and update the lightmap everyframe,
 this only happens automatically if VertexRenderer.real_time is true ( is true by default. ), otherwise VertexRenderer.update_shader() should be called to update the lightmap.

 - ### New lights are not updating
 The shader include has a **MAX_LIGHT** constant, this can be changed if necessary.

 - ### Negative attenuation makes everything else black
This is an issue in the vertex_render.gd script, values are not capped, I recommend not going below zero for OmniLights

 - ### Big pixels surrounding my light sources
This issue is caused by shaders that override DIFFUSE_LIGHT/SPECULAR_LIGHT in the light function of the shader, since we're changing the way the light behaves without telling the engine, graphical errors like this are common, you can mitigate this by 
checking the shader of the material that presents this error and revise the light function, this is very apparent with low poly models and big light sources.
Make sure it's behaviour lines up with what was discussed at [Custom Code](https://github.com/NonNavi/Vertex-Render-For-Godot-4?tab=readme-ov-file#custom-code)

 - ### Weird lighting on imported scene/model
Make sure the origins of the objects are correct and are close to the mesh, this applies with rotation and scale as well.

## Side Note
- If you're not planning in using effects like SSAO or SSIL, I suggest adding **render_mode unshaded**, this however will make Ambient light behave differently.

