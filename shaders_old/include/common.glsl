//
// SSAO
// Bloom
// FXAA
// TODO SSR quality profiles
// Sky color
// Use Shutter speed, F-Stops, ISO value to calculate DoF, exposure and motion blur at once

#ifndef COMMON_GLSL
#define COMMON_GLSL

#extension GL_EXT_gpu_shader4 : enable

#define PI       3.14159265359
#define EPSILON  0.001
#define INFINITY 1e12
#define E        2.71828182845904523536028747135266249775724709369995

#include "framebuffer.glsl"

uniform mat4 gbufferModelView;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

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
uniform vec3 previousCameraPosition;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform vec4 entityColor;

/**
 * Returns the hyperbolic cosine of the parameter.
 * This function requires "#version 130" or later to be globally defined.
 *
 * @param x    value
 *
 * @return    hyperbolic cosine of x
 */
float cosh(in float x) {
	return (pow(E, x) + pow(E, -x)) * 0.5;
}

/**
 * Converts RGB color to a perceptual grayscale value.
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

/**
 * Computes fragment position in view space.
 *
 * @param depth    normalized depth
 * @param coord    UV coordinate in range [0.0, 1.0] on both axes
 *
 * @return    fragment position in view space
 */
vec3 getFragPos(in float depth, in vec2 coord) {
	vec4 pos = gbufferProjectionInverse * (vec4(coord.x, coord.y, depth, 1.0f) * 2.0 - 1.0);
	pos /= pos.w;
	return pos.xyz;
}

/**
 * Approximates RGB tint value of given color temperature in Kelvin.
 * Ported from the original algorithm by Tanner Helland.
 * https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
 *
 * @param kelvin    temperature in Kelvin from 1000 up to 40000
 *
 * @return    RGB value
 */
vec3 blackbody(const in float kelvin) {
	float scaled = clamp(kelvin, 1000.0, 40000.0) * 0.01;
	
	vec3 rgb;
	
	if(scaled <= 66.0) {
		rgb.x = 1.0;
		rgb.y = 0.39008157876 * log(scaled) - 0.63184144378;
	} else {
		rgb.x = 1.29293618606 * pow(scaled - 60.0, -0.1332047592);
		rgb.y = 1.1298908609 * pow(scaled - 60.0, -0.0755148492);
	}
	
	if(scaled >= 66.0)rgb.z = 1.0;
	else if(scaled <= 19.0)rgb.z = 0.0;
	else rgb.z = 0.54320678911 * log(scaled - 10.0) - 1.19625408914;
	
	return clamp(rgb, 0.0, 1.0);
}

#include "encoding.glsl"
#include "options.glsl"

#endif // COMMON_GLSL