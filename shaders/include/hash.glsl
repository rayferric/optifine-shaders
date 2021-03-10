#ifndef HASH_GLSL
#define HASH_GLSL

#include "common.glsl"

/**
 * Computes floating-point value by hashing another one.
 *
 * @param value floating-point value to hash
 *
 * @return floating-point value in range [0.0, 1.0)
 */
float hash(in float value) {
	vec3 vec = fract(value * 0.1031);
	vec += dot(vec, vec.yzx + 19.19);
	return fract((vec.x + vec.y) * vec.z);
}

/**
 * Computes uniformly distributed random direction on unit sphere.
 *
 * @param value  three-component value to hash
 * @param normal hemisphere orientation
 *
 * @return normalized direction vector
 */
vec3 hashSphereDir(in float value) {
	vec2 hashed = vec2(hash(value), hash(value + 1.0));
	float s = hashed.x * 2.0 * PI;
	float t = hashed.y * 2.0 - 1.0;
	return vec3(sin(s), cos(s), t) / sqrt(t * t + 1.0);
}

/**
 * Computes uniformly distributed random direction
 * on unit hemisphere oriented along normal.
 *
 * @param value  three-component value to hash
 * @param normal hemisphere orientation
 *
 * @return normalized direction vector
 */
vec3 hashHemisphereDir(in float value, in vec3 normal) {
	vec3 dir = hashSphereDir(value);
	return dir * sign(dot(dir, normal));
}

#endif // HASH_GLSL
