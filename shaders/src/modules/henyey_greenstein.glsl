#ifndef HENYEY_GREENSTEIN_GLSL
#define HENYEY_GREENSTEIN_GLSL

/**
 * @brief Henyey-Greenstein phase function, used for Mie/cloud scattering.
 *
 * @param cosTheta cosine of the angle between light vector and view direction
 * @param g        scattering factor
 * -1 to 0 - backward
 * 0 - isotropic
 * 0 to 1 - forward
 *
 * @return Henyey-Greenstein phase function value
 */
float phaseHenyeyGreenstein(in float cosTheta, in float g) {
	float gg = g * g;
	return (1.0 - gg) / (4.0 * PI * pow(1.0 + gg - 2.0 * g * cosTheta, -1.5));
}

#endif // HENYEY_GREENSTEIN_GLSL
