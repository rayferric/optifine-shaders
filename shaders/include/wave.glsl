#ifndef WAVE_GLSL
#define WAVE_GLSL

#include "hash.glsl"
#include "material.glsl"

vec3 wave(in vec3 phaseSeed, in float freq) {
	float scaledTime = frameTimeCounter * freq * WAVING_FREQUENCY;
	vec3 phase = vec3(hash(phaseSeed.xyz), hash(phaseSeed.yzx), hash(phaseSeed.zxy));
    return sin(2.0 * PI * (scaledTime + phase));
}

vec3 waveBlock(in vec3 pos, in vec3 entity, in bool isTopVertex) {
	// Waves with same phase, but slightly different frequency will
	// periodically interfere making the movement more plausible.

	vec3 offset = vec3(0.0);

	if (false) {}

#ifdef WAVING_WATER
	else if (isWater(entity)) {
		offset.y += wave(pos + 0.0, 0.5).y * 0.01;
		offset.y += wave(pos + 1.0, 1.0).y * 0.01;
		offset.y += wave(pos + 1.0, 1.1).y * 0.01;
	}
#endif

#ifdef WAVING_LAVA
	else if (isLava(entity)) {
		offset.y += wave(pos + 0.0, 0.5).y * 0.01;
		offset.y += wave(pos + 1.0, 0.5).y * 0.01;
		offset.y += wave(pos + 1.0, 0.6).y * 0.01;
	}
#endif

#ifdef WAVING_LEAVES
	else if (isLeaves(entity)) {
		offset += wave(pos + 0.0, 0.5) * 0.005;
		offset += wave(pos + 1.0, 1.0) * 0.002;
		offset += wave(pos + 1.0, 1.1) * 0.002;
		offset += wave(pos + 2.0, 1.0) * 0.002;
		offset += wave(pos + 2.0, 0.5) * 0.002;
	}
#endif

#ifdef WAVING_FIRE
	else if (isTopVertex && isFire(entity)) {
		offset += wave(pos + 0.0, 0.5) * 0.02;
		offset += wave(pos + 1.0, 1.0) * 0.02;
		offset += wave(pos + 1.0, 1.1) * 0.02;
	}
#endif

#ifdef WAVING_SINGLE_PLANTS
	else if (isTopVertex && isSinglePlant(entity)) {
		offset += wave(pos + 0.0, 0.5) * 0.03;
		offset += wave(pos + 1.0, 1.0) * 0.01;
		offset += wave(pos + 1.0, 1.1) * 0.01;
		offset += wave(pos + 2.0, 1.0) * 0.01;
		offset += wave(pos + 2.0, 0.5) * 0.01;
	}
#endif

#ifdef WAVING_MULTI_PLANTS
	else if (isMultiPlant(entity)) {
		offset += wave(pos + 0.0, 0.5) * 0.005;
		offset += wave(pos + 1.0, 1.0) * 0.002;
		offset += wave(pos + 1.0, 1.1) * 0.002;
		offset += wave(pos + 2.0, 1.0) * 0.002;
		offset += wave(pos + 2.0, 0.5) * 0.002;
	}
#endif

	return pos + (offset * WAVING_AMPLITUDE);
}

#endif // WAVE_GLSL
