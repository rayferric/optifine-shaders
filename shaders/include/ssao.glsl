#ifndef SSAO_GLSL
#define SSAO_GLSL

#define SSAO_SAMPLES  8
#define SSAO_RADIUS   0.25
#define SSAO_STRENGTH 1.5

float computeSSAO(in vec3 fragPos, in vec3 normal, in sampler2D depthTex) {
	float aoStrength = 0.0;

	for (int i = 0; i < SSAO_SAMPLES; i++) {
		vec3 samplePos = fragPos + hashHemisphereDir(frameTimeCounter * fragPos + float(i), normal) * SSAO_RADIUS;
		vec4 proj = gbufferProjection * vec4(samplePos, 1.0);
		vec2 coord = (proj.xy / proj.w) * 0.5 + 0.5;
		
		float testDepth = -samplePos.z;
		float realDepth = -getFragPos(depthTex, coord).z;
		float rangeFactor = smoothstep(0.0, 1.0, SSAO_RADIUS / distance(realDepth, testDepth));
		aoStrength += float(realDepth < testDepth) * rangeFactor;
	}

	return pow(1.0 - (aoStrength / float(SSAO_SAMPLES)), SSAO_STRENGTH);
}

#endif // SSAO_GLSL
