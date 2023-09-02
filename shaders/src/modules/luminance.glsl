#ifndef LUMINANCE_GLSL
#define LUMINANCE_GLSL

#include "/src/modules/gamma.glsl"

/**
 * @brief Converts linear color to luminance.
 *
 * @param color linear color
 *
 * @return linear luminance
 */
float luminance(in vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

/**
 * @brief Converts sRGB color to gamma space luminance.
 *
 * @param color sRGB color
 *
 * @return luminance in gamma space
 */
float luma(in vec3 color) {
	return linearToGamma(luminance(gammaToLinear(color)));
}

#endif // LUMINANCE_GLSL
