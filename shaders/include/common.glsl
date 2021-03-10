#ifndef COMMON_GLSL
#define COMMON_GLSL

#extension GL_EXT_gpu_shader4 : enable

#define PI       3.141593
#define EPSILON  0.001
#define INFINITY 1e12
#define E        2.718282

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
 * This function normally requires "#version 130" or later to be globally defined.
 *
 * @param doubleArea twice the area of angle's hyperbolic sector
 *
 * @return hyperbolic cosine of doubleArea
 */
float cosh(in float doubleArea) {
	return (pow(E, doubleArea) + pow(E, -doubleArea)) * 0.5;
}

/**
 * Computes the inverse of a matrix.
 * This function normally requires "#version 140" or later to be globally defined.
 *
 * param m matrix to invert
 *
 * @return m<sup>-1</sup>
 */
mat4 inverse(in mat4 m) {
	float s0 = m[0][0] * m[1][1] - m[0][1] * m[1][0];
	float s1 = m[0][0] * m[2][1] - m[0][1] * m[2][0];
	float s2 = m[0][0] * m[3][1] - m[0][1] * m[3][0];
	float s3 = m[1][0] * m[2][1] - m[1][1] * m[2][0];
	float s4 = m[1][0] * m[3][1] - m[1][1] * m[3][0];
	float s5 = m[2][0] * m[3][1] - m[2][1] * m[3][0];
	
	float c5 = m[2][2] * m[3][3] - m[2][3] * m[3][2];
	float c4 = m[1][2] * m[3][3] - m[1][3] * m[3][2];
	float c3 = m[1][2] * m[2][3] - m[1][3] * m[2][2];
	float c2 = m[0][2] * m[3][3] - m[0][3] * m[3][2];
	float c1 = m[0][2] * m[2][3] - m[0][3] * m[2][2];
	float c0 = m[0][2] * m[1][3] - m[0][3] * m[1][2];

	float det = s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0;

	return mat4(
		 m[1][1] * c5 - m[2][1] * c4 + m[3][1] * c3,
		-m[0][1] * c5 + m[2][1] * c2 - m[3][1] * c1,
		 m[0][1] * c4 - m[1][1] * c2 + m[3][1] * c0,
		-m[0][1] * c3 + m[1][1] * c1 - m[2][1] * c0,
		-m[1][0] * c5 + m[2][0] * c4 - m[3][0] * c3,
		 m[0][0] * c5 - m[2][0] * c2 + m[3][0] * c1,
		-m[0][0] * c4 + m[1][0] * c2 - m[3][0] * c0,
		 m[0][0] * c3 - m[1][0] * c1 + m[2][0] * c0,
		 m[1][3] * s5 - m[2][3] * s4 + m[3][3] * s3,
		-m[0][3] * s5 + m[2][3] * s2 - m[3][3] * s1,
		 m[0][3] * s4 - m[1][3] * s2 + m[3][3] * s0,
		-m[0][3] * s3 + m[1][3] * s1 - m[2][3] * s0,
		-m[1][2] * s5 + m[2][2] * s4 - m[3][2] * s3,
		 m[0][2] * s5 - m[2][2] * s2 + m[3][2] * s1,
		-m[0][2] * s4 + m[1][2] * s2 - m[3][2] * s0,
		 m[0][2] * s3 - m[1][2] * s1 + m[2][2] * s0
	) * (1.0 / det);
}

/**
 * Converts color to perceptual grayscale value.
 *
 * @param color color
 *
 * @return grayscale value
 */
float luma(in vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

/**
 * Computes fragment position in view space.
 *
 * @param depth fragment depth in range [0.0, 1.0]
 * @param coord UV coordinate in range [0.0, 1.0] on both axes
 *
 * @return fragment position in view space
 */
vec3 getFragPos(in float depth, in vec2 coord) {
	vec4 pos = gbufferProjectionInverse * (vec4(coord.x, coord.y, depth, 1.0f) * 2.0 - 1.0);
	pos /= pos.w;
	return pos.xyz;
}

/**
 * Computes fragment position in view space.
 *
 * @param depthTex depth buffer to sample
 * @param coord    UV coordinate in range [0.0, 1.0] on both axes
 *
 * @return fragment position in view space
 */
vec3 getFragPos(in sampler2D depthTex, in vec2 coord) {
	float depth = texture2D(depthTex, coord).x;
	return getFragPos(depth, coord);
}

/**
 * Approximates RGB tint value of given color temperature in kelvin.
 * Ported from the original algorithm by Tanner Helland.
 * https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
 *
 * @param kelvin temperature in kelvin from 1000 up to 40000
 *
 * @return RGB tint value
 */
vec3 blackbody(in float kelvin) {
	float scaled = clamp(kelvin, 1000.0, 40000.0) * 0.01;
	
	vec3 rgb;
	
	if(scaled <= 66.0) {
		rgb.x = 1.0;
		rgb.y = 0.39008157876 * log(scaled) - 0.63184144378;
	} else {
		rgb.x = 1.29293618606 * pow(scaled - 60.0, -0.1332047592);
		rgb.y = 1.1298908609 * pow(scaled - 60.0, -0.0755148492);
	}
	
	if (scaled >= 66.0) rgb.z = 1.0;
	else if (scaled <= 19.0) rgb.z = 0.0;
	else rgb.z = 0.54320678911 * log(scaled - 10.0) - 1.19625408914;
	
	return clamp(rgb, 0.0, 1.0);
}

/**
 * Transforms HDR color to LDR using ACES operator.
 * Ported from original source:
 * https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve
 *
 * @param color HDR color
 *
 * @return LDR color
 */
vec3 tonemapACES(in vec3 color) {
	const float a = 2.51;
	const float b = 0.03;
	const float c = 2.43;
	const float d = 0.59;
	const float e = 0.14;
	return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

#include "framebuffer.glsl"
#include "options.glsl"

#endif // COMMON_GLSL
