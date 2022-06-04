#ifndef SSR_GLSL
#define SSR_GLSL

#include "hash.glsl"
#include "atmospherics.glsl"

#define SSR_INIT_STEP 1.0
#define SSR_STEP_MUL  2.0

#define SSR_MAX_STEPS 20
#define SSR_BIN_STEPS 4

// TODO: These hashing funcs are broken

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
	for (int i = 0; i < SSR_BIN_STEPS; i++) {
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
	dir *= SSR_INIT_STEP / SSR_STEP_MUL;
	for (int i = 0; i < SSR_MAX_STEPS; i++) {
		origin += (dir *= SSR_STEP_MUL);

		vec4 proj  = gbufferProjection * vec4(origin, 1.0);
		coord = (proj.xyz / proj.w) * 0.5 + 0.5;
		if(coord.x <= 0.0 || coord.x >= 1.0 || coord.y <= 0.0 || coord.y >= 1.0 || coord.z <= 0.0 || coord.z >= 1.0)break;

		float rayDepth   = -origin.z;
		float worldDepth = -getFragPos(depthTex, coord.xy).z;
		float stepDepth  = -dir.z;

		// When the ray depth finally surpassed world depth, we refine and
		// check whether the difference is within a reasonable margin
		if(rayDepth > worldDepth && rayDepth - worldDepth < stepDepth + 0.5) {
			return vec3(binarySearch(depthTex, origin, dir), 1.0);
		}
		
	}
	return vec3(coord.xy, 0.0);
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
vec3 computeSSReflection(in sampler2D colorTex, in sampler2D depthTex, in vec3 fragPos, in vec3 normal, in float roughness, in float skyFactor) {
	vec3 dir = reflect(normalize(fragPos), normal);
	vec3 jitt = normalize(mix(dir, hashDirInHemisphere(fragPos * frameTimeCounter, normal), roughness));
	vec3 coord = rayMarch(depthTex, fragPos, jitt);

	vec2 dCoord = smoothstep(0.75, 1.0, abs(coord.xy * 2.0 - 1.0));
	float screenEdgeFactor = clamp(1.0 - (dCoord.x + dCoord.y), 0.0, 1.0);
	
	vec3 fallback = getSkyEnergy(dir) * skyFactor;
	return mix(fallback, texture2D(colorTex, coord.xy).xyz, coord.z * screenEdgeFactor);
}

/**
 * Calculates refraction color at given fragment position.
 *
 * @param colorTex     HDR texture that contains already calculated screen energy
 * @param depthTex     depth buffer to be sampled
 * @param fragPos      fragment's position in view space
 * @param normal       fragment's normal in view space
 * @param ior          fragment's index of refraction
 * @param roughness    fragment's roughness value
 * @param skyFactor    on-fallback sky color factor
 *
 * @return    reflection color
 */
vec3 computeSSRefraction(in sampler2D colorTex, in sampler2D depthTex, in vec3 fragPos, in vec3 normal, in float ior, in float roughness, in float skyFactor) {
	vec3 viewDir = normalize(fragPos);
	vec3 dir = refract(viewDir, normal, ior);
	if(length(dir) == 0.0)dir = reflect(viewDir, normal);
	vec3 jitt = normalize(mix(dir, hashDirInHemisphere(fragPos * frameTimeCounter, normal), roughness));
	vec3 coord = rayMarch(depthTex, fragPos, jitt);

	vec2 dCoord = smoothstep(0.75, 1.0, abs(coord.xy * 2.0 - 1.0));
	float screenEdgeFactor = clamp(1.0 - (dCoord.x + dCoord.y), 0.0, 1.0);
	
	vec3 fallback = getSkyEnergy(dir) * skyFactor;
	return mix(fallback, texture2D(colorTex, coord.xy).xyz, coord.z);
}

#endif // SSR_GLSL