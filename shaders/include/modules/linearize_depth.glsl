#ifndef LINEARIZE_DEPTH_GLSL
#define LINEARIZE_DEPTH_GLSL

/**
 * Converts player camera normalized depth to
 * linear value between the clipping planes.
 *
 * @param depth non-linear depth in range [0, 1]
 *
 * @return linear distance from camera on the Z axis
 */
float linearizeDepth(in float depth) {
    depth = depth * 2.0 - 1.0;
    return (2.0 * near * far) / (far - depth * (far - near));
}

#endif // LINEARIZE_DEPTH_GLSL