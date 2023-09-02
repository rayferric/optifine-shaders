#ifndef SSAO_GLSL
#define SSAO_GLSL

#include "/src/modules/hash.glsl"
#include "/src/modules/linearize_depth.glsl"
#include "/src/modules/normalized_mul.glsl"
#include "/src/modules/temporal_jitter.glsl"

#define SSAO_RADIUS   0.25
#define SSAO_EXPONENT 0.75
#define SSAO_SAMPLES  4

/**
 * @brief Approximates ambient occlusion in screen space.
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
		vec3 unitOffset = hashToHemisphereOffset(
		    frameTimeCounter * viewPos + float(i), normal
		);
		unitOffset     = normalize(unitOffset + normal * 0.01);
		vec3 samplePos = viewPos + (unitOffset * SSAO_RADIUS);
		vec2 coord = normalizedMul(gbufferProjection, samplePos).xy * 0.5 + 0.5;

#ifdef TAA
		vec2  temporalOffset = getTemporalOffset();
		float bufferDistance =
		    linearizeDepth(texture2D(depthTex, coord + temporalOffset).x);
#else
		float bufferDistance = linearizeDepth(texture2D(depthTex, coord).x);
#endif

		aoStrength += step(bufferDistance, -samplePos.z) *
		              step(-samplePos.z, bufferDistance + SSAO_RADIUS);
	}

	return pow(1.0 - (aoStrength / float(SSAO_SAMPLES)), SSAO_EXPONENT);
}

#endif // SSAO_GLSL
