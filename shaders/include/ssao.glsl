#ifndef SSAO_GLSL
#define SSAO_GLSL

#include "hash.glsl"

#define SSAO_RADIUS   0.25
#define SSAO_EXPONENT 1.5

float computeSSAO(in vec3 fragPos, in vec3 normal, in sampler2D depthTex) {
#if SSAO_SAMPLES == 0
	return 1.0;
#endif

	float aoStrength = 0.0;

	for (int i = 0; i < SSAO_SAMPLES; i++) {
		vec3 unitOffset = hashToHemisphereOffset(frameTimeCounter * fragPos + float(i), normal);
		vec3 samplePos = fragPos + (unitOffset * SSAO_RADIUS);
		vec2 coord = projPos(gbufferProjection, samplePos).xy * 0.5 + 0.5;
		
		float bufferDistance = getLinearDepth(texture2D(depthTex, coord + 0.05).x);
		float rangeFactor = smoothstep(0.0, 1.0, SSAO_RADIUS / distance(bufferDistance, -samplePos.z));
		aoStrength += float(bufferDistance < -samplePos.z) * rangeFactor;
	}

	return pow(1.0 - (aoStrength / float(SSAO_SAMPLES)), SSAO_EXPONENT);
}

#endif // SSAO_GLSL
