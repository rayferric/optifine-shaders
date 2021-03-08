#ifndef SSR_GLSL
#define SSR_GLSL

#include "atmospherics.glsl"

#define SSR_INIT_STEP 0.5
#define SSR_STEP_MUL  2.0

#define SSR_MAX_STEPS 16
#define SSR_BIN_STEPS 4


/**
 * Generates normalized, pseudo-random number by hashing a value.
 *
 * @param value    three-component value to be hashed
 *
 * @return    number in range <0.0, 1.0]
 */
float hash3(in vec3 value) {
	return fract(sin(value.x * 1000.0 + value.y * 10000.0 + value.z * 100000.0));
}

/**
 * Generates random direction in hemisphere oriented along normal.
 *
 * @param seed      three-component value to be hashed
 * @param normal    hemisphere orientation
 *
 * @return    normalized direction
 */
vec3 hashDirHemi(in vec3 seed, in vec3 normal) {
	vec3 dir;
	dir.x = hash3(seed.xyx * vec3(1.0, 10.0, 100.0));
	dir.y = hash3(seed.yxz * vec3(100.0, 1.0, 10.0));
	dir.z = hash3(seed.zzy * vec3(10.0, 100.0, 1.0));
	dir = dir * 2.0 - 1.0;
	dir = normalize(dir / cos(dir)); // Ensures uniform distribution

	return dot(dir, normal) < 0.0 ? -dir : dir;
}



/**
 * Refines ray marching result by performing a binary search from the last known ray position.
 *
 * @param depthTex    depth buffer to be sampled
 * @param origin      last known ray position
 * @param dir         ray direction appropriately scaled by the step size
 *
 * @return    texel coordinates in range <0, 1> on both axes
 */
vec2 binarySearch(in sampler2D depthTex, in vec3 origin, in vec3 dir) {
	bool exceeded = true;
	vec2 coord;
	for(int i = 0; i < SSR_BIN_STEPS; i++) {
		dir *= 0.5;
		if(exceeded)origin -= dir;
		else origin += dir;

		vec4 proj  = gbufferProjection * vec4(origin, 1.0);
		coord = (proj.xy / proj.w) * 0.5 + 0.5;

		float rayDepth   = -origin.z;
		float worldDepth = -getFragPos(depthTex, coord.xy).z;

		exceeded = rayDepth > worldDepth;
	}
	return coord;
}

/**
 * Returns final coordinates after raymarching the depth buffer.
 *
 * @param depthTex    depth buffer to be sampled
 * @param origin      ray origin
 * @param dir         normalized ray direction
 *
 * @return    .xy - texel coordinates in range <0, 1> on both axes | .z - whether the algorithm has succeeded (1.0) or not (0.0)
 */
vec3 rayMarch(in sampler2D depthTex, in vec3 origin, in vec3 dir) {
	vec3 coord;
	dir *= SSR_INIT_STEP;
	for(int i = 0; i < SSR_MAX_STEPS; i++) {
		origin += (dir *= SSR_STEP_MUL);

		vec4 proj  = gbufferProjection * vec4(origin, 1.0);
		coord = (proj.xyz / proj.w) * 0.5 + 0.5;
		if(coord.x <= 0.0 || coord.x >= 1.0 || coord.y <= 0.0 || coord.y >= 1.0 || coord.z <= 0.0 || coord.z >= 1.0)break;

		float rayDepth   = -origin.z; // Current ray depth
		float worldDepth = -getFragPos(depthTex, coord.xy).z; // World depth at current ray position projected onto the depth buffer
		float stepDepth  = -dir.z; // Expected ray depth increase when no collision occurred

		// When the ray depth finally surpassed world depth, we check whether the difference is within a reasonable margin to prevent infinite repetition of missing data
		if(rayDepth > worldDepth && rayDepth - worldDepth < stepDepth + 0.5) {
			return vec3(binarySearch(depthTex, origin, dir), 1.0);
		}
		
	}
	return vec3(coord.xy, 0.0);
}

// TODO Somehow blur the reflection
vec3 texture2DBlur(in sampler2D tex, in vec2 coord, in int size) {
    vec3 color = vec3(0.0);
    for(int x = -size; x <= size; x++) {
        for(int y = -size; y <= size; y++) {
            color += texture2DOffset(tex, coord, ivec2(x, y)).xyz;
        }
    }
	int side = size * 2 + 1;
    return color / (side * side);
}

/**
 * Calculates reflection color at given fragment position.
 *
 * @param colorTex     HDR texture that contains already calculated screen energy
 * @param depthTex     depth buffer to be sampled
 * @param fragPos      fragment's position in view space
 * @param normal       fragment's normal in view space
 * @param roughness    fragment's roughness value
 * @param skyFactor    on-fallback sky color factor
 *
 * @return    reflection color
 */
vec3 computeSSR(in sampler2D colorTex, in sampler2D depthTex, in vec3 fragPos, in vec3 normal, in float roughness, in float skyFactor) {
	vec3 dir = reflect(normalize(fragPos), normal);
	vec3 jitt = normalize(mix(dir, hashDirHemi(fragPos * frameTimeCounter, normal), roughness));
	vec3 coord = rayMarch(depthTex, fragPos, jitt);

	vec2 dCoord = smoothstep(0.75, 1.0, abs(coord.xy * 2.0 - 1.0));
    float screenEdgeFactor = clamp(1.0 - (dCoord.x + dCoord.y), 0.0, 1.0);
	
	vec3 fallback = getSkyEnergy(dir) * skyFactor;
	return mix(fallback, texture2D(colorTex, coord.xy).xyz, coord.z * screenEdgeFactor);
}

#endif // SSR_GLSL