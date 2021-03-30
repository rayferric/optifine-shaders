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

// /**
//  * Returns the hyperbolic cosine of the parameter.
//  * This function normally requires "#version 130" or later to be globally defined.
//  *
//  * @param doubleArea twice the area of angle's hyperbolic sector
//  *
//  * @return hyperbolic cosine of doubleArea
//  */
// float cosh(in float doubleArea) {
// 	return (pow(E, doubleArea) + pow(E, -doubleArea)) * 0.5;
// }

// /**
//  * Computes the inverse of a matrix.
//  * This function normally requires "#version 140" or later to be globally defined.
//  *
//  * param m matrix to invert
//  *
//  * @return m<sup>-1</sup>
//  */
// mat4 inverse(in mat4 m) {
// 	float s0 = m[0][0] * m[1][1] - m[0][1] * m[1][0];
// 	float s1 = m[0][0] * m[2][1] - m[0][1] * m[2][0];
// 	float s2 = m[0][0] * m[3][1] - m[0][1] * m[3][0];
// 	float s3 = m[1][0] * m[2][1] - m[1][1] * m[2][0];
// 	float s4 = m[1][0] * m[3][1] - m[1][1] * m[3][0];
// 	float s5 = m[2][0] * m[3][1] - m[2][1] * m[3][0];
	
// 	float c5 = m[2][2] * m[3][3] - m[2][3] * m[3][2];
// 	float c4 = m[1][2] * m[3][3] - m[1][3] * m[3][2];
// 	float c3 = m[1][2] * m[2][3] - m[1][3] * m[2][2];
// 	float c2 = m[0][2] * m[3][3] - m[0][3] * m[3][2];
// 	float c1 = m[0][2] * m[2][3] - m[0][3] * m[2][2];
// 	float c0 = m[0][2] * m[1][3] - m[0][3] * m[1][2];

// 	float det = s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0;

// 	return mat4(
// 		 m[1][1] * c5 - m[2][1] * c4 + m[3][1] * c3,
// 		-m[0][1] * c5 + m[2][1] * c2 - m[3][1] * c1,
// 		 m[0][1] * c4 - m[1][1] * c2 + m[3][1] * c0,
// 		-m[0][1] * c3 + m[1][1] * c1 - m[2][1] * c0,
// 		-m[1][0] * c5 + m[2][0] * c4 - m[3][0] * c3,
// 		 m[0][0] * c5 - m[2][0] * c2 + m[3][0] * c1,
// 		-m[0][0] * c4 + m[1][0] * c2 - m[3][0] * c0,
// 		 m[0][0] * c3 - m[1][0] * c1 + m[2][0] * c0,
// 		 m[1][3] * s5 - m[2][3] * s4 + m[3][3] * s3,
// 		-m[0][3] * s5 + m[2][3] * s2 - m[3][3] * s1,
// 		 m[0][3] * s4 - m[1][3] * s2 + m[3][3] * s0,
// 		-m[0][3] * s3 + m[1][3] * s1 - m[2][3] * s0,
// 		-m[1][2] * s5 + m[2][2] * s4 - m[3][2] * s3,
// 		 m[0][2] * s5 - m[2][2] * s2 + m[3][2] * s1,
// 		-m[0][2] * s4 + m[1][2] * s2 - m[3][2] * s0,
// 		 m[0][2] * s3 - m[1][2] * s1 + m[2][2] * s0
// 	) * (1.0 / det);
// }

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
 * Converts screen coordinates to three-dimensional view space position.
 *
 * @param depth fragment depth in range [0.0, 1.0]
 * @param coord UV coordinate in range [0.0, 1.0] on both axes
 *
 * @return fragment position in view space
 */
vec3 getFragPos(in float depth, in vec2 coord) {
	vec4 pos = gbufferProjectionInverse * (vec4(coord.xy, depth, 1.0) * 2.0 - 1.0);
	return pos.xyz / pos.w;
}

/**
 * Converts screen coordinates to three-dimensional view space position.
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
 * Converts three-dimensional position to normalized screen coordinates.
 *
 * @param pos spatial position in view space
 *
 * @return UV coordinate in range [0.0, 1.0] on both axes
 */
vec2 getScreenCoord(in vec3 viewPos) {
	vec4 proj = gbufferProjection * vec4(viewPos, 1.0);
	return (proj.xy / proj.w) * 0.5 + 0.5;
}

#include "framebuffer.glsl"
#include "options.glsl"

#endif // COMMON_GLSL
