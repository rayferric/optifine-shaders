#ifndef WAVE_GLSL
#define WAVE_GLSL

#include "/src/modules/blocks.glsl"
#include "/src/modules/hash.glsl"

vec3 hashWave(in vec3 phaseSeed, in float freq) {
	float scaledTime = frameTimeCounter * freq * WAVING_FREQUENCY;
	vec3  phase =
	    vec3(hash(phaseSeed.xyz), hash(phaseSeed.yzx), hash(phaseSeed.zxy));
	return sin(2.0 * PI * (scaledTime + phase));
}

vec3 getBlockWave(in vec3 phaseSeed, in vec3 entity, in bool isTopVertex) {
	// Waves with same phase, but slightly different frequency will
	// periodically interfere making the movement more plausible.

	vec3 offset = vec3(0.0);

	if (false) {
	}

#ifdef WAVING_WATER
	else if (isWater(entity)) {
		offset.y += hashWave(phaseSeed + 0.0, 0.5).y * 0.01;
		offset.y += hashWave(phaseSeed + 1.0, 1.0).y * 0.01;
		offset.y += hashWave(phaseSeed + 1.0, 1.1).y * 0.01;
	}
#endif

#ifdef WAVING_LAVA
	else if (isLava(entity)) {
		offset.y += hashWave(phaseSeed + 0.0, 0.5).y * 0.01;
		offset.y += hashWave(phaseSeed + 1.0, 0.5).y * 0.01;
		offset.y += hashWave(phaseSeed + 1.0, 0.6).y * 0.01;
	}
#endif

#ifdef WAVING_LEAVES
	else if (isLeaves(entity)) {
		offset += hashWave(phaseSeed + 0.0, 0.5) * 0.005;
		offset += hashWave(phaseSeed + 1.0, 1.0) * 0.002;
		offset += hashWave(phaseSeed + 1.0, 1.1) * 0.002;
		offset += hashWave(phaseSeed + 2.0, 1.0) * 0.002;
		offset += hashWave(phaseSeed + 2.0, 0.5) * 0.002;
	}
#endif

#ifdef WAVING_FIRE
	else if (isTopVertex && isFire(entity)) {
		offset += hashWave(phaseSeed + 0.0, 0.5) * 0.02;
		offset += hashWave(phaseSeed + 1.0, 1.0) * 0.02;
		offset += hashWave(phaseSeed + 1.0, 1.1) * 0.02;
	}
#endif

#ifdef WAVING_SINGLE_PLANTS
	else if (isTopVertex && isSinglePlant(entity)) {
		offset += hashWave(phaseSeed + 0.0, 0.5) * 0.03;
		offset += hashWave(phaseSeed + 1.0, 1.0) * 0.01;
		offset += hashWave(phaseSeed + 1.0, 1.1) * 0.01;
		offset += hashWave(phaseSeed + 2.0, 1.0) * 0.01;
		offset += hashWave(phaseSeed + 2.0, 0.5) * 0.01;
	}
#endif

#ifdef WAVING_MULTI_PLANTS
	else if (isMultiPlant(entity)) {
		offset += hashWave(phaseSeed + 0.0, 0.5) * 0.005;
		offset += hashWave(phaseSeed + 1.0, 1.0) * 0.002;
		offset += hashWave(phaseSeed + 1.0, 1.1) * 0.002;
		offset += hashWave(phaseSeed + 2.0, 1.0) * 0.002;
		offset += hashWave(phaseSeed + 2.0, 0.5) * 0.002;
	}
#endif

	return offset * WAVING_AMPLITUDE;
}

// Dir length is inversely proportional to wave length
float gerstnerWave(
    in vec2 origin, in vec2 dir, in float freq, in float steepness
) {
	float scaledTime = frameTimeCounter * freq * WAVING_FREQUENCY;
	return pow(
	    sin(origin.x * dir.x + origin.y * dir.y + scaledTime) * 0.5 + 0.5,
	    steepness
	);
}

float getWaterWaveHeight(in vec2 worldPos) {
	return 0.02 *
	       (0.1 * gerstnerWave(
	                  worldPos, 4.0 * normalize(vec2(4.0, 5.0)), 2.0, 0.5
	              ) +
	        0.1 * gerstnerWave(
	                  worldPos, 6.0 * normalize(vec2(1.0, -4.0)), 5.0, 0.5
	              ) +
	        0.1 * gerstnerWave(
	                  worldPos, 7.0 * normalize(vec2(-8.0, 7.0)), 2.0, 0.5
	              ) +
	        0.1 * gerstnerWave(
	                  worldPos, 8.0 * normalize(vec2(4.0, 9.0)), 5.0, 0.5
	              ) +
	        0.1 * gerstnerWave(
	                  worldPos, 3.0 * normalize(vec2(-4.0, 1.0)), 2.0, 0.5
	              ) +
	        0.1 * gerstnerWave(
	                  worldPos, 4.0 * normalize(vec2(7.0, -2.0)), 3.0, 0.5
	              ) +
	        0.1 * gerstnerWave(
	                  worldPos, 5.0 * normalize(vec2(1.0, 7.0)), 5.0, 0.5
	              ) +
	        0.1 * gerstnerWave(
	                  worldPos, 4.0 * normalize(vec2(8.0, 3.0)), 2.0, 0.5
	              ) +
	        0.1 * gerstnerWave(
	                  worldPos, 5.0 * normalize(vec2(-1.0, 2.0)), 3.0, 0.5
	              ));
}

vec3 getWaterWaveNormal(in vec2 worldPos) {
	float b = getWaterWaveHeight(worldPos + vec2(0.0, -0.1));
	float t = getWaterWaveHeight(worldPos + vec2(0.0, 0.1));
	float l = getWaterWaveHeight(worldPos + vec2(-0.1, 0.0));
	float r = getWaterWaveHeight(worldPos + vec2(0.1, 0.0));

	vec3 v1 = vec3(0.0, t - b, 0.2);
	vec3 v2 = vec3(0.2, r - l, 0.0);

	return normalize(cross(v1, v2));
}

#endif // WAVE_GLSL
