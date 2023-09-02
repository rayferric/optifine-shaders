#ifndef GAMMA_GLSL
#define GAMMA_GLSL

/**
 * @brief Converts value from gamma to linear space.
 *
 * @param value value in gamma space
 *
 * @return value in linear space
 */
float gammaToLinear(in float value) {
	return pow(value, 2.2);
}

/**
 * @brief Converts value from linear to gamma space.
 *
 * @param value value in linear space
 *
 * @return value in gamma space
 */
float linearToGamma(in float value) {
	return pow(value, 1.0 / 2.2);
}

/**
 * @brief Converts value from gamma to linear space.
 *
 * @param value value in gamma space
 *
 * @return value in linear space
 */
vec2 gammaToLinear(in vec2 value) {
	return pow(value, vec2(2.2));
}

/**
 * @brief Converts value from linear to gamma space.
 *
 * @param value value in linear space
 *
 * @return value in gamma space
 */
vec2 linearToGamma(in vec2 value) {
	return pow(value, vec2(1.0 / 2.2));
}

/**
 * @brief Converts value from gamma to linear space.
 *
 * @param value value in gamma space
 *
 * @return value in linear space
 */
vec3 gammaToLinear(in vec3 value) {
	return pow(value, vec3(2.2));
}

/**
 * @brief Converts value from linear to gamma space.
 *
 * @param value value in linear space
 *
 * @return value in gamma space
 */
vec3 linearToGamma(in vec3 value) {
	return pow(value, vec3(1.0 / 2.2));
}

#endif // GAMMA_GLSL
