# OptiFine Shaders

This is my take at developing a Minecraft shaderpack completely from scratch. That means no code is taken from existing shaderpacks so you might encounter both good and poor quality solutions applied here. By implementing all the functionality myself, I hope to learn everything about physically based shading in games.

## Important Note

The tagged version 0.0.1 is a previous in-dev snapshot that happened to work without many errors of the shaderpack. However it is not quite ready for production and the codebase has been completely reworked since then.

## Features and Bugs

My shaderpack has the following range o features:
- Physically Based Shading Model (Described [Here](https://learnopengl.com))
- Transmittance and Volumetric Light Absorbance Physics
- Screen Space Reflections
- Screen Space Ambient Occlusion
- Variable Penumbra Smooth Shadows
- Colored Shadows
- Automatic Eye Exposure Adaptation
- Gradient-Based Procedural Sky System
- LabPBR RP support
- Artificial PBR Parameters for Vanilla Textures

Keep in mind that most of those features might not work as expected and will have visible artifacts, mainly due to the lack of temporal filtering.

I would like to implement some of the following at some point in the future:
- Simple Water Fog
- Waving Water Surface
- Waving Foliage
- Temporal Anti-Aliasing (should help with smooth shadows and SSAO)
- (Temporal?) Denoising of Reflections (TAA might not be enough to both work well and avoid excessive smearing)
- Water Caustics
- Bloom
- Fake Shaded Clouds (GTA 5 alike?)
- A User-Friendly Configuration Menu
- Volumetric Clouds
- Volumetric Height Fog
- Volumetric Water Fog
- Customized Shaders for Nether/End Dimensions
- Motion Blur
- Depth of Field

Currently known bugs and design flaws:
- Fake height fog is too bright underground.
- Reflections look horrible underwater (lack of water fog makes it even worse).
- Distorted shadows have visible artifacts at certain angles and for long shadows.
- When the shadows fade at a distance, leaves with fake SSS (with disabled cosine factor) are left completely unshaded.
- High roughness SSR results in unrealistic blue-ish fresnel effect (mainly visible on leaves where roughness is about 0.6).
- The hash function sometimes reveals itself due of the lack of fract() on input (adding it breaks nighttime stars for some reason).
- The subsurface PBR property remains mostly useless and is only used to enable fake SSS for foliage over the 0.5 threshold.
- World border is incorrectly rendered using mixed GBuffer data from both the border pass and the terrain pass.
- Water is not visible behind clear glass due to it being draw with transmittance instead of using the alpha test.
