#ifndef WAVE_GLSL
#define WAVE_GLSL

#include "common.glsl"
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

#ifdef WAVING_LEAVES
	if (isLeaves(entity)) {
		offset += wave(pos + 0.0, 0.5) * 0.005;
		offset += wave(pos + 1.0, 1.0) * 0.005;
		offset += wave(pos + 1.0, 1.1) * 0.005;
	}
#endif

// #if WAVING_PLANTS
// 	if (isLeaves(entity) || isMultiPlant(entity)) {
// 		offset += wave(pos + 0.0, 0.5) * 0.005;
// 		offset += wave(pos + 1.0, 1.0) * 0.005;
// 		offset += wave(pos + 1.0, 1.1) * 0.005;
// 	}
// #endif

// 	if (isWater(entity)) {
// 		offset.y += wave(pos + 0.0, 0.5).y * 0.01;
// 		offset.y += wave(pos + 1.0, 1.0).y * 0.01;
// 		offset.y += wave(pos + 1.0, 1.1).y * 0.01;
// 	} else if (isLava(entity)) {
// 		offset.y += wave(pos + 0.0, 0.5).y * 0.01;
// 		offset.y += wave(pos + 1.0, 0.5).y * 0.01;
// 		offset.y += wave(pos + 1.0, 0.6).y * 0.01;
// 	} else 
// 	// } else if (isSinglePlant(entity) && isTopVertex) {
// 	// 	offset += wave(pos + 0.0, 0.5) * 0.005;
// 	// 	offset += wave(pos + 1.0, 1.0) * 0.005;
// 	// 	offset += wave(pos + 1.0, 1.1) * 0.005;
// 	} else if (isSinglePlant(entity) && isTopVertex) {
// 		offset += wave(pos + 0.0, 0.5) * 0.03;
// 		offset += wave(pos + 1.0, 1.0) * 0.01;
// 		offset += wave(pos + 1.0, 1.1) * 0.01;
// 	}

	return pos + (offset * WAVING_AMPLITUDE);
}

// vec3 calcMove(in vec3 pos, float f0, float f1, float f2, float f3, float f4, float f5, vec3 amp1, vec3 amp2) {
//     vec3 move1 = calcWave(pos      , 0.0027, 0.0400, 0.0400, 0.0127, 0.0089, 0.0114, 0.0063, 0.0224, 0.0015) * amp1;
//     vec3 move2 = calcWave(pos+move1, 0.0348, 0.0400, 0.0400, f0, f1, f2, f3, f4, f5) * amp2;
//     return move1 + move2;
// }

// float calcLilypadMove(vec3 worldpos){
//     float wave = sin(2 * PI * (frametime*0.7 + worldpos.x * 0.14 + worldpos.z * 0.07))
//                 + sin(2 * PI * (frametime*0.5 + worldpos.x * 0.10 + worldpos.z * 0.20));
//     return wave * 0.025;
// }

// float calcLavaMove(vec3 worldpos)
// {
//     float fy = fract(worldpos.y + 0.005);
		
//     if(fy > 0.01){
//     float wave = sin(2 * PI * (frametime*0.7 + worldpos.x * 0.14 + worldpos.z * 0.07))
//                 + sin(2 * PI * (frametime*0.5 + worldpos.x * 0.10 + worldpos.z * 0.20));
//     return wave * 0.025;
//     } else return 0.0;
// }

#endif // WAVE_GLSL
