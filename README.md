# Vertex-Render for Godot 4
 Vertex rendering reimplemented for Godot 4

 ## How to use

 The plugin should automatically add the shader globals necessary for the shader include to work, as well as the Singleton.<br>
 When adding the plugin reload the scene, this will reload the Script used for gathering the lighting information.

### Changing scenes

Since there's no scene_changed signal built-in, the Singleton doesnt have a way to know when a scene has changed and *if* it should re-scan the scene nodes for Light3D type nodes,
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
- inderect energy
this last one is used like angular distance, diffusing the light and making the light expand more.

### Ambient light

as long as you dont add **render_mode unshaded**, to your shader using the shader include, *Ambient light* should behave like it does normally although a bit more muted,
if you are using the *Sky mode* for the *Environment* background, ambient color and energy is changed from the *Background* tab to the *Ambient Light* tab.
If you feel like the Sky light is too dim, I recommend changing *Color* in *Ambient light* (ambient_light_color) to a neutral grey.


 ## Known Issues
 - ### All lights are missin at runtime
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

