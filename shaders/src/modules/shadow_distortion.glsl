#ifndef SHADOW_DISTORTION_FACTOR_GLSL
#define SHADOW_DISTORTION_FACTOR_GLSL

/**
 * @brief Computes vertex position scaling factor used
 * to direct more texels to areas close to camera.
 *
 * @param pos undistorted position
 *
 * @return scaling factor, multiply it by pos to get remapped coordinate
 */
float getShadowDistortionFactor(in vec2 pos) {
	vec2  p = pow(abs(pos), vec2(SHADOW_MAP_DISTORTION_STRETCH));
	float d = pow(p.x + p.y, 1.0 / SHADOW_MAP_DISTORTION_STRETCH);
	d       = mix(1.0, d, SHADOW_MAP_DISTORTION_STRENGTH);
	return 1.0 / d;
}

#endif // SHADOW_DISTORTION_FACTOR_GLSL