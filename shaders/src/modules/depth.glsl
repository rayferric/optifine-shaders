#ifndef DEPTH_GLSL
#define DEPTH_GLSL

/**
 * @brief Converts non-linear normalized depth to
 * linear value between the clipping planes.
 *
 * @param depth non-linear depth in range [0, 1]
 *
 * @return linear distance from camera on the Z axis
 */
float linearizeDepth(in float depth) {
	depth = depth * 2.0 - 1.0;
	return gbufferProjection[3][2] / (gbufferProjection[2][2] + depth);
}

/**
 * @brief Converts linear value between the clipping planes to
 * non-linear normalized depth.
 *
 * @param depth distance from camera on the Z axis in range [near, far]
 *
 * @return non-linear depth in range [0, 1]
 */
float normalizeDepth(in float depth) {
	// y = a / (b + x)
	// y(b + x) = a
	// by + bx = a
	// bx = a - by
	// x = (a - by) / b
	// x = a/b - y
	depth = (gbufferProjection[3][2] / gbufferProjection[2][2]) - depth;
	return depth * 0.5 + 0.5;
}

#endif // DEPTH_GLSL
