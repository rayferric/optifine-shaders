#ifndef RAYMARCH_GLSL
#define RAYMARCH_GLSL

#include "/src/modules/is_inside_rect.glsl"
#include "/src/modules/linearize_depth.glsl"
#include "/src/modules/temporal_jitter.glsl"

#define RAYMARCH_REFINE_STEPS 4

struct RayMarchResult {
	bool hasHit;
	vec2 coord;
};

/**
 * @brief Traces a ray in screen space.
 *
 * @param depthTex      depth buffer to sample
 * @param origin        ray origin
 * @param dir           tracing direction
 * @param rayLength     maximum length of traced ray
 * @param bias          offset of ray origin in tracing direction to avoid
 * self-intersection at grazing angles
 * @param stepCount     maximum number of steps for the initial scan
 * @param nearThickness maximum Z difference to score a hit for intersections
 * near the camera
 * @param farThickness  maximum Z difference to score a hit for intersections
 * further from the camera
 *
 * @return    .hasHit - whether the ray scored a hit | .coord - screen space
 * position of the intersection point
 */
RayMarchResult rayMarch(
    in sampler2D depthTex,
    in vec3      origin,
    in vec3      dir,
    in float     rayLength,
    in float     bias,
    in int       stepCount,
    in float     nearThickness,
    in float     farThickness
) {
	vec2 temporalOffset = getTemporalOffset();

	vec3 start = origin + dir * 0.02;
	vec3 end   = origin + dir * rayLength;

	// Clip endpoint to near plane
	rayLength = -end.z > near ? rayLength : (-origin.z - near) / dir.z;
	end       = origin + dir * rayLength;

	vec4 projStart = gbufferProjection * vec4(start, 1.0);
	vec4 projEnd   = gbufferProjection * vec4(end, 1.0);

	// We will interpolate 3 values between them
	// 2 of which are used to cheaply calculate ray depth
	// in sync with 2D screen coordinates
	float invWStart = 1.0 / projStart.w;
	float invWEnd   = 1.0 / projEnd.w;

	vec3 homoStart = start * invWStart;
	vec3 homoEnd   = end * invWEnd;

	vec2 screenStart = projStart.xy * invWStart * 0.5 + 0.5;
	vec2 screenEnd   = projEnd.xy * invWEnd * 0.5 + 0.5;

	for (int i = 1; i <= stepCount; i++) {
		// Linear progress across 2D screen, not the 3D ray
		float progress = float(i) / float(stepCount);

		float invW   = mix(invWStart, invWEnd, progress);
		float homoZ  = mix(homoStart.z, homoEnd.z, progress);
		vec2  screen = mix(screenStart, screenEnd, progress);

		if (!isInsideRect(screen, vec2(0.0), vec2(1.0))) {
			break;
		}

		float rayDepth = -(homoZ / invW);

		if (rayDepth < near || rayDepth > far) {
			break;
		}

		float sampleDepth =
		    linearizeDepth(texture2D(depthTex, screen + temporalOffset).x);

		// When we reach behind the depth buffer...
		// (This block is terminal)
		if (rayDepth > sampleDepth) {
			float depthDiff  = rayDepth - sampleDepth;
			vec2  finalCoord = screen;

			float progressDelta = 1.0 / float(stepCount);
			bool  inFront       = false;

			for (int i = 0; i < RAYMARCH_REFINE_STEPS; i++) {
				// ...go back, and then trace forward
				// once we got in front of it
				progressDelta *= 0.5;
				progress      += inFront ? progressDelta : -progressDelta;

				// Heavy reuse of temporary variables
				invW   = mix(invWStart, invWEnd, progress);
				homoZ  = mix(homoStart.z, homoEnd.z, progress);
				screen = mix(screenStart, screenEnd, progress);

				rayDepth    = -(homoZ / invW);
				sampleDepth = linearizeDepth(
				    texture2D(depthTex, screen + temporalOffset).x
				);

				inFront = sampleDepth > rayDepth;

				// Mark more precise position, which
				// is still behind the depth buffer
				depthDiff  = inFront ? depthDiff : rayDepth - sampleDepth;
				finalCoord = inFront ? finalCoord : screen;
			}

			if (depthDiff >
			    mix(nearThickness, farThickness, pow(progress, 10.0))) {
				break;
			}

			return RayMarchResult(true, finalCoord);
		}
	}

	return RayMarchResult(false, vec2(0.0));
}

#endif // RAYMARCH_GLSL
