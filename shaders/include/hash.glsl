#ifndef HASH_GLSL
#define HASH_GLSL

/**
 * Computes floating-point value by hashing a three-component vector.
 *
 * @param value three-component vector to hash
 *
 * @return floating-point value in range [0.0, 1.0)
 */
float hash(in vec3 value) {
	value = fract(value * vec3(0.1031, 0.1030, 0.0973));
    value += dot(value, value.yxz + 33.33);
    value = fract((value.xxy + value.yxx)*value.zyx);
	value += dot(value, value.yzx + 33.33);
	return fract((value.x + value.y) * value.z);
}

/**
 * Computes uniformly distributed random direction on unit circle.
 *
 * @param value three-component value to hash
 *
 * @return normalized direction vector
 */
vec2 hashToCircleDir(in vec3 value) {
	float theta = hash(value) * 2.0 * PI;
	return vec2(cos(theta), sin(theta));
}

/**
 * Computes uniformly distributed random direction on unit sphere.
 *
 * @param value three-component value to hash
 *
 * @return normalized direction vector
 */
vec3 hashToSphereDir(in vec3 value) {
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
vec3 hashToHemisphereDir(in vec3 value, in vec3 normal) {
	vec3 dir = hashToSphereDir(value);
	return dir * sign(dot(dir, normal));
}

/**
 * Computes uniformly distributed random position in unit circle.
 *
 * @param value three-component value to hash
 *
 * @return offset vector
 */
vec2 hashToCircleOffset(in vec3 value) {
	return hashToCircleDir(value) * sqrt(hash(value.zyx));
}

/**
 * Computes uniformly distributed random position
 * in unit hemisphere oriented along normal.
 *
 * @param value  three-component value to hash
 * @param normal hemisphere orientation
 *
 * @return offset vector
 */
vec3 hashToHemisphereOffset(in vec3 value, in vec3 normal) {
	return hashToHemisphereDir(value, normal) * sqrt(hash(value.zyx));
}

#endif // HASH_GLSL
