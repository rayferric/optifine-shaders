#ifndef TEMPORAL_JITTER_GLSL
#define TEMPORAL_JITTER_GLSL

#include "/src/modules/hash.glsl"

// Maximum offset length in pixels
#define TEMPORAL_JITTER_RADIUS 1.0

const vec2[] haltonSequence = vec2[](
	vec2(0.6563, 0.1852),
	vec2(0.4063, 0.5185),
	vec2(0.9063, 0.8519),
	vec2(0.0938, 0.2963),
	vec2(0.5938, 0.6296),
	vec2(0.3438, 0.9630),
	vec2(0.8438, 0.0123),
	vec2(0.2188, 0.3457),
	vec2(0.7188, 0.6790),
	vec2(0.4688, 0.1235),
	vec2(0.9688, 0.4568),
	vec2(0.0156, 0.7901),
	vec2(0.5156, 0.2346),
	vec2(0.2656, 0.5679),
	vec2(0.7656, 0.9012),
	vec2(0.1406, 0.0494)
);

/**
 * Computes random subpixel offset unique to this frame.
 *
 * @return screen space offset
 */
vec2 getTemporalOffset() {
	vec2 unitOffset = haltonSequence[frameCounter % 16] * 2.0 - 1.0;
	return TEMPORAL_JITTER_RADIUS * unitOffset / vec2(viewWidth, viewHeight);
}

#endif // TEMPORAL_JITTER_GLSL
