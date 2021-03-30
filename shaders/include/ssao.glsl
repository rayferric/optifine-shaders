#ifndef SSAO_GLSL
#define SSAO_GLSL

#include "hash.glsl"

#define SSAO_RADIUS 0.25

float computeSSAO(in vec3 fragPos, in vec3 normal, in sampler2D depthTex) {
#if SSAO_SAMPLES == 0
	return 1.0;
#endif

	float aoStrength = 0.0;

	for (int i = 0; i < SSAO_SAMPLES; i++) {
		vec3 samplePos = fragPos + hashHemisphereDir(frameTimeCounter * fragPos + float(i), normal) * SSAO_RADIUS * hash(fragPos * float(i));
		vec2 coord = getScreenCoord(samplePos);
		
		float testDepth = -samplePos.z;
		float realDepth = -getFragPos(depthTex, coord).z;
		float rangeFactor = smoothstep(0.0, 1.0, SSAO_RADIUS / distance(realDepth, testDepth));
		aoStrength += float(realDepth < testDepth) * rangeFactor;
	}

	return pow(1.0 - (aoStrength / float(SSAO_SAMPLES)), SSAO_EXPONENT);
}

#endif // SSAO_GLSL
