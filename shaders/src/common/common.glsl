// #extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_texture_lod : enable
#extension GL_ARB_arrays_of_arrays : enable

#include "/src/common/constants.glsl"
#include "/src/common/framebuffer.glsl"
#include "/src/common/globals.glsl"
#include "/src/common/settings.glsl"
#include "/src/common/uniforms.glsl"

// Noise Texture
uniform sampler2D noisetex;
