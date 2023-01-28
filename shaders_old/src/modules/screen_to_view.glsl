#ifndef SCREEN_TO_VIEW_GLSL
#define SCREEN_TO_VIEW_GLSL

#include "/src/modules/normalized_mul.glsl"
#include "/src/modules/temporal_jitter.glsl"

/**
 * Converts screen space 2D coordinates
 * to view space position.
 *
 * @param screenPos screen space position
 * @param depth     sampled depth
 *
 * @return view space position
 */
vec3 screenToView(in vec2 screenPos, in float depth) {
	vec2 temporalOffset = getTemporalOffset();
	return normalizedMul(gbufferProjectionInverse, vec3(screenPos - temporalOffset, depth) * 2.0 - 1.0);
}

/**
 * Converts screen space 2D coordinates
 * to view space position.
 *
 * @param screenPos screen space position
 * @param depthTex  depth buffer to sample
 *
 * @return view space position
 */
vec3 screenToView(in vec2 screenPos, in sampler2D depthTex) {
	float depth = texture2D(depthTex, screenPos).x;
	return screenToView(screenPos, depth);
}

#endif // SCREEN_TO_VIEW_GLSL
