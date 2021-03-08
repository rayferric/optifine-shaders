#ifndef HASH_GLSL
#define HASH_GLSL

/**
 * Generates single number by hashing a three-component value.
 *
 * @param value    three-component value to be hashed
 *
 * @return    single number in range <0.0, 1.0]
 */
float hash1(in vec3 value) {
	value = fract(value * 0.1031);
    value += dot(value, value.yzx + 33.33);
    value *= sin(dot(value, vec3(9082.0, 87233.0, 132.0)));
    return fract((value.x + value.y) * value.z);
}

/**
 * Generates three-component number by hashing a three-component value.
 *
 * @param value    three-component value to be hashed
 *
 * @return    three-component number in range <0.0, 1.0] on all axes
 */
vec3 hash3(vec3 value) {
	value = fract(value * vec3(0.1031, 0.1030, 0.0973));
    value += dot(value, value.yxz + 33.33);
    return fract((value.xxy + value.yxx) * value.zyx);
}

/**
 * Generates random direction in hemisphere oriented along normal.
 *
 * @param seed      three-component value to be hashed
 * @param normal    hemisphere orientation
 *
 * @return    normalized direction
 */
vec3 hashDirInHemisphere(in vec3 seed, in vec3 normal) {
	vec3 dir = hash3(seed);
	dir = dir * 2.0 - 1.0;
	dir = normalize(dir / cos(dir)); // Ensures uniform distribution

	return dot(dir, normal) < 0.0 ? -dir : dir;
}

#endif // HASH_GLSL