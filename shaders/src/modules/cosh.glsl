#ifndef COSH_GLSL
#define COSH_GLSL

/**
 * @brief Returns the hyperbolic cosine of the parameter.
 * This function normally requires "#version 130" or later to be globally
 * defined.
 *
 * @param doubleArea twice the area of hyperbolic sector
 *
 * @return hyperbolic cosine of doubleArea
 */
float cosh(in float doubleArea) {
	return (pow(E, doubleArea) + pow(E, -doubleArea)) * 0.5;
}

#endif // COSH_GLSL
