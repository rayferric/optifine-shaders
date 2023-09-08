#ifndef HASH_GLSL
#define HASH_GLSL

#include "/src/modules/constants.glsl"

/**
 * @brief Computes the hash of a 3D vector.
 * Breaks down to gray-scale if all components of the vector are the same.
 * Banding becomes visible on resolutions higher than 1024 * 10^2 pixels per
 * unit. You can get more resolution by chaining multiple hash calls, i.e.:
 * hash(hash(value)) - Gives maximum resolution of 1024 * 10^6 pixels per unit.
 *
 * @param value saturated 3D vector
 * The value must be saturated, i.e. between 0 and 1. Otherwise the hash
 * function will break down.
 *
 * @return randomized and saturated 3D vector
 */
vec3 hash(in vec3 value) {
	// The spec requires input between 0 and 1:
	// value = fract(value);

	value  = fract(value * 1234.567);
	value += dot(value, value.yxz + 123.4567);
	return vec3(fract((value.xyz + value.yzx) * value.zxy));
}

/**
 * @brief Computes uniformly distributed random direction on unit circle.
 *
 * @param value saturated 3D seed
 *
 * @return normalized direction vector
 */
vec2 hashToCircleDir(in vec3 value) {
	float theta = hash(value).x * 2.0 * PI;
	return vec2(cos(theta), sin(theta));
}

/**
 * @brief Computes uniformly distributed random direction on unit sphere.
 *
 * @param value saturated 3D seed
 *
 * @return normalized direction vector
 */
vec3 hashToSphereDir(in vec3 value) {
	vec3  hashed = hash(value);
	float s      = hashed.x * 2.0 * PI;
	float t      = hashed.y * 2.0 - 1.0;
	return vec3(sin(s), cos(s), t) / sqrt(t * t + 1.0);
}

/**
 * @brief Computes uniformly distributed random direction
 * on unit hemisphere oriented along normal.
 *
 * @param value  saturated 3D vector
 * @param normal hemisphere orientation
 *
 * @return normalized direction vector
 */
vec3 hashToHemisphereDir(in vec3 value, in vec3 normal) {
	vec3 dir = hashToSphereDir(value);
	return dir * sign(dot(dir, normal));
}

/**
 * @brief Computes uniformly distributed random position in unit circle.
 *
 * @param value saturated 3D vector
 *
 * @return offset vector
 */
vec2 hashToCircleOffset(in vec3 value) {
	// return hashToCircleDir(value) * sqrt(hash(value.zyx));

	// The above code, but with one less hash call:
	vec3  hashed = hash(value);
	float theta  = hashed.x * 2.0 * PI;
	vec2  result = vec2(cos(theta), sin(theta));

	return result * sqrt(hashed.y);
}

/**
 * @brief Computes uniformly distributed random position
 * in unit hemisphere oriented along normal.
 *
 * @param value  saturated 3D vector
 * @param normal hemisphere orientation
 *
 * @return offset vector
 */
vec3 hashToHemisphereOffset(in vec3 value, in vec3 normal) {
	return hashToHemisphereDir(value, normal) * sqrt(hash(value.zyx).x);

	// // The above code, but with one less hash call:
	// vec3  hashed = hash(value);
	// float s      = hashed.x * 2.0 * PI;
	// float t      = hashed.y * 2.0 - 1.0;
	// vec3  result = vec3(sin(s), cos(s), t) / sqrt(t * t + 1.0);

	// result *= sign(dot(dir, normal));
	// return result * sqrt(hashed.z);
}

#endif // HASH_GLSL
