#ifndef SSAO_GLSL
#define SSAO_GLSL

#include "/src/modules/hash.glsl"
#include "/src/modules/linearize_depth.glsl"
#include "/src/modules/normalized_mul.glsl"
#include "/src/modules/temporal_jitter.glsl"

#define SSAO_RADIUS   0.25
#define SSAO_EXPONENT 0.75

/**
 * Approximates ambient occlusion in screen space.
 *
 * @param viewPos  fragment position in view space
 * @param normal   fragment normal
 * @param depthTex depth buffer to sample
 *
 * @return ambient occlusion value
 */
float computeSsao(in vec3 viewPos, in vec3 normal, in sampler2D depthTex) {
#if SSAO_SAMPLES == 0
	return 1.0;
#endif

	float aoStrength = 0.0;

	for (int i = 0; i < SSAO_SAMPLES; i++) {
		vec3 unitOffset = hashToHemisphereOffset(frameTimeCounter * viewPos + float(i), normal);
		vec3 samplePos = viewPos + (unitOffset * SSAO_RADIUS);
		vec2 coord = normalizedMul(gbufferProjection, samplePos).xy * 0.5 + 0.5;
		
		vec2 temporalOffset = getTemporalOffset();

		float bufferDistance = linearizeDepth(texture2D(depthTex, coord + temporalOffset).x);
		
		float rangeFactor = smoothstep(0.0, 1.0, SSAO_RADIUS / distance(bufferDistance, -samplePos.z));
		aoStrength += float(bufferDistance < -samplePos.z) * rangeFactor;
	}

	return pow(1.0 - (aoStrength / float(SSAO_SAMPLES)), SSAO_EXPONENT);
}

#endif // SSAO_GLSL
