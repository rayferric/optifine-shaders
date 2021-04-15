#ifndef TEMPORAL_GLSL
#define TEMPORAL_GLSL

#include "hash.glsl"

#define TEMPORAL_MEMORY 0.95

/**
 * Computes random subpixel offset unique to this frame.
 *
 * @param prevFrame compute for previous frame
 *
 * @return 2D offset
 */
vec2 getTemporalOffset(bool prevFrame) {
	int frame = prevFrame ? frameCounter - 1 : frameCounter;
	//frame = (frame == -1) ? 720719 : frame;
	vec2 unitOffset = hashToCircleOffset(vec3(frame));
	return 0.25 * unitOffset / vec2(viewWidth, viewHeight);
}



#endif // TEMPORAL_GLSL
