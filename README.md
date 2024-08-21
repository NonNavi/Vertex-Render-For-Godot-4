# Vertex-Render for Godot 4
 Vertex rendering reimplemented for Godot 4

 ## How to use
 Extract the *addons* folder and add it to your project, once the files are added, go to *ProjectSettings > Plugins* and enable *VertexRenderer*, once this is done reload your project.
 The plugin should automatically add the shader globals necessary for the shader include to work, as well as the Singleton.<br>
 When adding the plugin reload the scene, this will reload the Script used for gathering the lighting information.
 
 Inside ***"res://addons/VertexRenderer/shader/"*** you'll find **vertex_shader.gdshaderinc** alongside sample shaders to get you an idea in how to implement your own shaders, you can also check out
 **vertex_shader.gdshaderinc** to see the what definitions might suit your needs, check the [Custom Code](https://github.com/NonNavi/Vertex-Render-For-Godot-4/edit/main/README.md#custom-code) section for more info on that.

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

### Custom Code.
- ### Basic needs
- ### Vertex Code
*vertex_shader.gdshaderinc* uses the vertex pass function for all the shading, so custom code is impossible without a special definition, ***#define CUSTOM_CODE*** will tell the shader include
to change the way it works, this can be forced if your prefer it but changes to your shader code need to be made for the Vertex Renderer to work.
```GLSL
shader_type spatial;

// We define CUSTOM_VERTEX to let the include know we want to use custom vertex code
#define CUSTOM_VERTEX
#include "addons/VertexRenderer/shader/vertex_shader.gdshaderinc"

void vertex(){
 ShaderResult shader; // Struct to store the result of vertex_shade

 // vertex_shade, this function does the same as the regular vertex function,
 // however it will return a ShaderResult struct.

 shader = vertex_shade(VERTEX,NORMAL);

	vertex_color = COLOR;
	COLOR.rgb = shader.result;
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
ShaderResult stores 3 values, in case you need the Brightness or Color for your code, but you dont want to override the Vertex function you can use:
```GLSL
#define RETRIEVE_BRIGHTNESS
#define RETRIEVE_COLOR

void fragment(){
  final_brightness; // Float, Final brightness from the shading process
  final_color; // Vec3, Final color from the shading process
}
```
instead, this will add *final_brightness* and *final_color* to be used.

 ## Known Issues
 - ### Everything is black/unshaded at runtime
 Check your Debugger log, and check for any shader global related errors or warnings, if that is the case, reload your project.<br>
 If your error is not related to missing shder globals, consider reporting it [here](https://github.com/NonNavi/Vertex-Render-For-Godot-4/issues).
 - ### All lights are missing at runtime
 Lights should be part of the "Light" group, otherwise they wont be taken into account, *vertex_renderer.gd* should intercept new nodes and add them to the Light group, when the 
 
 - ### New lights are not updating

 The shader include has a **MAX_LIGHT** constant, this can be changed if necessary
 - ### Negative attenuation makes everything else black

This is an issue in the vertex_render.gd script, values are not capped, I recommend not going below zero for OmniLights
 - ### Weird lighting on imported scene/model

Make sure the origins of the objects are correct and are close to the mesh, this applies with rotation and scale as well.

## Recommendations for your Project

- If you're not planning in using effects like SSAO or SSIL, I suggest adding **render_mode unshaded**, this however will make Ambient light behave differently.
- I recommend adding the Light's to the Light group manually, make it so is a Global Group and adding the nodes to the group is easier.

