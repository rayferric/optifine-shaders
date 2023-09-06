#ifndef RAYMARCH_GLSL
#define RAYMARCH_GLSL

#include "/src/modules/constants.glsl"
#include "/src/modules/depth.glsl"
#include "/src/modules/hash.glsl"
#include "/src/modules/is_inside_rect.glsl"
#include "/src/modules/screen_to_view.glsl"
#include "/src/modules/temporal_jitter.glsl"

struct RayMarchResult {
	bool hasHit;
	vec2 coord;
};

/**
 * @brief Traces a ray in screen space.
 *
 * @param depthTex        depth buffer to sample
 * @param viewOrigin      ray origin
 * @param dir             tracing direction
 * @param rayLength       maximum length of traced ray
 * @param bias            offset of ray origin in tracing direction to avoid
 * self-intersection at grazing angles
 * @param stepCount       maximum number of steps for the initial scan
 * @param refineStepCount maximum number of steps for the refinement scan
 * @param nearThickness   maximum Z difference to score a hit for intersections
 * near the camera
 * @param farThickness    maximum Z difference to score a hit for intersections
 * further from the camera
 *
 * @return    .hasHit - whether the ray scored a hit | .coord - screen space
 * position of the intersection point
 */
RayMarchResult rayMarch(
    in sampler2D depthTex,
    in vec3      viewOrigin,
    in vec3      viewDir,
    in float     rayLength,
    in float     bias,
    in int       stepCount,
    in int       refineStepCount,
    in float     nearThickness,
    in float     farThickness
) {
	vec2 temporalOffset = getTemporalOffset();

	// viewOrigin = vec3(0.2, -0.5, -1.0);
	// viewDir    = normalize(vec3(-1.0, 1.0, -1.0));

	vec3 start = viewOrigin + viewDir * 0.1;
	vec3 end   = start + viewDir * 0.01;

	vec4 projStart = gbufferProjection * vec4(start, 1.0);
	vec4 projEnd   = gbufferProjection * vec4(end, 1.0);

	// We will interpolate 3 values between them
	// 2 of which are used to cheaply calculate ray depth
	// in sync with 2D screen coordinates
	float invWStart = 1.0 / projStart.w;
	float invWEnd   = 1.0 / projEnd.w;

	vec2 screenStart = projStart.xy * invWStart * 0.5 + 0.5;
	vec2 screenEnd   = projEnd.xy * invWEnd * 0.5 + 0.5;

	{
		vec2 screenDir = normalize(screenEnd - screenStart);
		screenEnd      = screenStart + screenDir * SQRT2;
		// clamp screenDir length to screen bounds
		if (screenEnd.x < 0.0 || screenEnd.x > 1.0) {
			float xDelta = screenEnd.x < 0.0 ? -screenEnd.x : screenEnd.x - 1.0;
			float xScale = xDelta / abs(screenDir.x);
			screenEnd -= screenDir * xScale;
		}
		if (screenEnd.y < 0.0 || screenEnd.y > 1.0) {
			float yDelta = screenEnd.y < 0.0 ? -screenEnd.y : screenEnd.y - 1.0;
			float yScale = yDelta / abs(screenDir.y);
			screenEnd -= screenDir * yScale;
		}

		// Recalculate 3D endpoint backwards using the new screenEnd.
		end = screenToView(screenEnd, 0.5);

		// direction from camera to end point
		vec3 projDir = normalize(end);
		// intersection of camera-end ray with start-(actual end) ray
		float rayLen = (projDir.z * (0.0 - viewOrigin.y) -
		                projDir.y * (0.0 - viewOrigin.z)) /
		               (projDir.z * viewDir.y - projDir.y * viewDir.z);

		// It might so happen that the ray will not reach the desired length
		// because the projection ray will look away from the view ray.
		// In this case negative ray length will be found.
		// Let's set those bad cases to a relatively high ray length
		// and then run this whole pass again without the hardcoded
		// screenDir length so that no bad rays are left.
		const float maxRayLen = 10000.0;
		rayLen                = clamp(rayLen, -maxRayLen, maxRayLen);
		float badRay          = max(step(rayLen, 0.0), step(maxRayLen, rayLen));
		rayLen                = mix(rayLen, maxRayLen, badRay);

		// Recalculate end point like before.
		end       = viewOrigin + viewDir * rayLen;
		projEnd   = gbufferProjection * vec4(end, 1.0);
		invWEnd   = 1.0 / projEnd.w;
		screenEnd = projEnd.xy * invWEnd * 0.5 + 0.5;
	}
	// Second pass, without hardcoded screenDir length.
	{
		end = normalizedMul(
		    gbufferProjectionInverse, vec3(screenEnd * 2.0 - 1.0, 0.5)
		);

		vec3  projDir             = normalize(end);
		vec3  commonPlaneNormal   = normalize(cross(viewDir, projDir));
		float projectFromTheRight = step(
		    0.5, abs(commonPlaneNormal.x)
		); // abs(commonPlaneNormal.x) > 0.5
		// intersect by looking from the right
		float rayLenFromRight = (projDir.z * (0.0 - viewOrigin.y) -
		                         projDir.y * (0.0 - viewOrigin.z)) /
		                        (projDir.z * viewDir.y - projDir.y * viewDir.z);
		// intersect by looking from the top
		float rayLenFromTop = (projDir.z * (0.0 - viewOrigin.x) -
		                       projDir.x * (0.0 - viewOrigin.z)) /
		                      (projDir.z * viewDir.x - projDir.x * viewDir.z);
		float rayLen = mix(rayLenFromTop, rayLenFromRight, projectFromTheRight);

		end       = viewOrigin + viewDir * rayLen;
		projEnd   = gbufferProjection * vec4(end, 1.0);
		invWEnd   = 1.0 / projEnd.w;
		screenEnd = projEnd.xy * invWEnd * 0.5 + 0.5;
	}

	// for (int i = 0; i < 100; i++) {
	// 	if (distance(screenStart, screenEnd) > 1.41) {
	// 		break;
	// 	}

	// 	end                += viewDir * 3.0;
	// 	projEnd            = gbufferProjection * vec4(end, 1.0);
	// 	invWEnd            = 1.0 / projEnd.w;
	// 	screenEnd          = projEnd.xy * invWEnd * 0.5 + 0.5;
	// }

	vec3 homoStart = start * invWStart;
	vec3 homoEnd   = end * invWEnd;

	for (int i = 1; i <= stepCount; i++) {
		// Linear progress across 2D screen, not the 3D ray
		float rand =
		    hash(float(i) * viewOrigin * viewDir * frameTimeCounter).x * 0.0;
		float progress = (float(i) - rand) / float(stepCount);

		// Non-linear progress will help when the ray is very long.
		progress = 1.0 - progress;
		float angleFactor =
		    pow(max(dot(viewDir, vec3(0.0, 0.0, -1.0)), 0.0), 2.0);
		progress = pow(progress, 1.0 + angleFactor);
		progress = 1.0 - progress;

		float invW   = mix(invWStart, invWEnd, progress);
		float homoZ  = mix(homoStart.z, homoEnd.z, progress);
		vec2  screen = mix(screenStart, screenEnd, progress);

		float rayDepth = -(homoZ / invW);

		float sampleDepth =
		    linearizeDepth(texture(depthTex, screen + temporalOffset).x);

		// When we reach behind the depth buffer...
		// (This block is terminal)
		if (rayDepth > sampleDepth) {
			float depthDiff  = rayDepth - sampleDepth;
			vec2  finalCoord = screen;

			float progressDelta = 1.0 / float(stepCount);
			bool  inFront       = false;

			vec2  prevScreen;
			float prevRayDepth;
			for (int j = 0; j < refineStepCount; j++) {
				// ...go back, and then trace forward
				// once we got in front of it
				progressDelta *= 0.5;
				progress      += inFront ? progressDelta : -progressDelta;

				// Remember tracing values from before the current step.
				prevScreen   = screen;
				prevRayDepth = rayDepth;

				// Heavy reuse of temporary variables
				invW   = mix(invWStart, invWEnd, progress);
				homoZ  = mix(homoStart.z, homoEnd.z, progress);
				screen = mix(screenStart, screenEnd, progress);

				rayDepth = -(homoZ / invW);
				sampleDepth =
				    linearizeDepth(texture(depthTex, screen + temporalOffset).x
				    );

				inFront = sampleDepth > rayDepth;

				// Mark more precise position, which
				// is still behind the depth buffer
				depthDiff  = inFront ? depthDiff : rayDepth - sampleDepth;
				finalCoord = inFront ? finalCoord : screen;
			}

			float thickness  = rayDepth * 0.1 + 1.0;
			thickness        = pow(thickness, 1.5);
			thickness       -= 1.0;
			if (depthDiff > thickness) {
				break;
			}

			return RayMarchResult(true, finalCoord);
		}
	}

	return RayMarchResult(false, vec2(0.0));
}

#endif // RAYMARCH_GLSL
