#ifndef TEMPORAL_JITTER_GLSL
#define TEMPORAL_JITTER_GLSL

#include "/src/modules/halton.glsl"

// Maximum offset length in pixels
#define TEMPORAL_JITTER_RADIUS 1.0

/**
 * @brief Computes random subpixel offset unique to this frame.
 *
 * @return screen space offset
 */
vec2 getTemporalOffset() {
	vec2 unitOffset = halton16[frameCounter % 16] * 2.0 - 1.0;
	return TEMPORAL_JITTER_RADIUS * unitOffset / vec2(viewWidth, viewHeight);
}

#endif // TEMPORAL_JITTER_GLSL
