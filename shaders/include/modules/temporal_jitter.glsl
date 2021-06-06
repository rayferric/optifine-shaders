#ifndef TEMPORAL_JITTER_GLSL
#define TEMPORAL_JITTER_GLSL

#include "/include/modules/hash.glsl"

// Maximum offset length in pixels
#define TEMPORAL_JITTER_RADIUS 0.5

/**
 * Computes random subpixel offset unique to this frame.
 *
 * @param prevFrame whether to compute for previous frame
 *
 * @return screen space offset
 */
vec2 getTemporalOffset(bool prevFrame) {
	int frame = prevFrame ? frameCounter - 1 : frameCounter;
	frame = (frame == -1) ? 720719 : frame;
	vec2 unitOffset = hashToCircleOffset(vec3(frame));
	return TEMPORAL_JITTER_RADIUS * unitOffset / vec2(viewWidth, viewHeight);
}

#endif // TEMPORAL_JITTER_GLSL
