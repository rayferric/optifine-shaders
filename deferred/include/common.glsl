//
// SSAO
// Bloom
// FXAA
// TODO SSR quality profiles
// Sky color
// Use Shutter speed, F-Stops, ISO value to calculate DoF, exposure and motion blur at once

#ifndef COMMON_GLSL
#define COMMON_GLSL

#version 120
#extension GL_EXT_gpu_shader4 : enable

#define PI       3.14159265359
#define EPSILON  0.001
#define INFINITY 1e12
#define E        2.71828182845904523536028747135266249775724709369995

#include "framebuffer.glsl"

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform int heldItemId;
uniform int heldItemId2;
uniform int worldTime;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform vec3 sunPosition; 
uniform vec3 moonPosition; 
uniform vec3 shadowLightPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform vec4 entityColor;

/**
 * Returns the hyperbolic cosine of the parameter.
 * This function normally requires "#version 130" or later to be globally defined.
 *
 * @param x    value
 *
 * @return    hyperbolic cosine of x
 */
float cosh(in float x) {
	return (pow(E, x) + pow(E, -x)) * 0.5;
}

/**
 * Converts RGB color into the percepted grayscale value.
 *
 * @param color    RGB value
 *
 * @return    grayscale value
 */
float luma(in vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

/**
 * Computes fragment position in view space.
 *
 * @param depthTex    depth buffer to be sampled
 * @param coord       UV coordinate in range [0.0, 1.0] on both axes
 *
 * @return    fragment position in view space
 */
vec3 getFragPos(in sampler2D depthTex, in vec2 coord) {
	float depth = texture2D(depthTex, coord).x;
	vec4 pos = gbufferProjectionInverse * (vec4(coord.x, coord.y, depth, 1.0f) * 2.0 - 1.0);
	pos /= pos.w;
	return pos.xyz;
}

#include "encoding.glsl"
#include "options.glsl"

#endif // COMMON_GLSL