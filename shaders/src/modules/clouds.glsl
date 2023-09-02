#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/src/modules/constants.glsl"
#include "/src/modules/hash.glsl"
#include "/src/modules/henyey_greenstein.glsl"
#include "/src/modules/intersection.glsl"
#include "/src/modules/sky.glsl"

#define CLOUDS_CLOUD_COVERAGE_TEX       colortex14
#define CLOUDS_CLOUD_DETAIL_TEX         colortex15
// radius of the hypothetical planet the bedrock layer is starting at
#define CLOUDS_VIEW_RADIUS              10000.0
// the radius of the cloud sphere above the surface of the planet
#define CLOUDS_INNER_RADIUS             10100.0
// the radius of the enclosing sphere of the cloud sphere
#define CLOUDS_OUTER_RADIUS             10200.0
#define CLOUDS_CLOUD_SAMPLES            32
#define CLOUDS_LIGHT_SAMPLES            4
#define CLOUDS_MIE_PROB                 10e-2
#define CLOUDS_G                        -0.5
#define CLOUDS_WIND                     vec2(5.0, 10.0) // units per second
#define CLOUDS_DETAIL_LAYER_HEIGHT      7.0
#define CLOUDS_MAX_CLOUD_TRACE_DISTANCE 2000.0
#define CLOUDS_MAX_LIGHT_TRACE_DISTANCE 100.0
#define CLOUDS_LIGHT_TRACE_LENGTH       20.0

// clang-format off

// 1/6 * PI
const mat2 cloudCoverageRot1 = mat2(
	sqrt(3.0), -1.0,
	1.0, sqrt(3.0)
) / 2.0;

// 2/3 * PI
const mat2 cloudCoverageRot2 = mat2(
	-1.0, -sqrt(3.0),
	sqrt(3.0), -1.0
) / 2.0;

// clang-format on

/**
 * @brief Computes the attenuation of a ray through the atmosphere.
 */
float attenuation(in float x) {
	float bell   = cos(PI * x) * 0.5 + 0.5;
	float cutoff = step(-1.0, x) * step(x, 1.0);
	return bell * cutoff;
}

float cloudCoverage(in vec2 pos, in float factor) {
	float coverage = 0.0;

	coverage += texture(CLOUDS_CLOUD_COVERAGE_TEX, pos * 0.001 + 0.2).x;
	coverage +=
	    texture(
	        CLOUDS_CLOUD_COVERAGE_TEX, (cloudCoverageRot1 * pos * 0.0001 + 0.3)
	    )
	        .x;
	coverage +=
	    texture(
	        CLOUDS_CLOUD_COVERAGE_TEX, (cloudCoverageRot2 * pos * 0.0007 - 0.1)
	    )
	        .x;

	coverage *= 0.33;
	factor   = 1.0 - factor;
	factor   = factor * 0.8;
	coverage = smoothstep(factor, factor + 0.2, coverage);

	return coverage;
}

float cloudDetail(in vec3 pos) {
	float floorY =
	    floor(pos.y / CLOUDS_DETAIL_LAYER_HEIGHT) * CLOUDS_DETAIL_LAYER_HEIGHT;
	float ceilY = floorY + CLOUDS_DETAIL_LAYER_HEIGHT;

	vec3 floorOffsetScale = hash(vec3(
	    (floorY - CLOUDS_INNER_RADIUS) /
	    (CLOUDS_OUTER_RADIUS - CLOUDS_INNER_RADIUS)
	));
	vec3 ceilOffsetScale  = hash(vec3(
        (ceilY - CLOUDS_INNER_RADIUS) /
        (CLOUDS_OUTER_RADIUS - CLOUDS_INNER_RADIUS)
    ));

	floorOffsetScale.xy *= 10.0;
	ceilOffsetScale.xy  *= 10.0;

	floorOffsetScale.z = mix(0.001, 0.003, floorOffsetScale.z);
	ceilOffsetScale.z  = mix(0.001, 0.003, ceilOffsetScale.z);

	float floorDetail = texture(
	                        CLOUDS_CLOUD_DETAIL_TEX,
	                        pos.xz * floorOffsetScale.z + floorOffsetScale.xy
	)
	                        .x;

	float ceilDetail = texture(
	                       CLOUDS_CLOUD_DETAIL_TEX,
	                       pos.xz * ceilOffsetScale.z + ceilOffsetScale.xy
	)
	                       .x;

	float detail = mix(floorDetail, ceilDetail, pos.y - floorY);
	return detail * detail;
}

// TODO: docs
// Cloud shape is the general density of the cloud without the details
float cloudShape(
    in vec3 spherePos, in vec2 worldOffset, in float coverageFactor
) {
	float coverage = cloudCoverage(spherePos.xz + worldOffset, coverageFactor);

	// Make the clouds less dense at the top
	float cloudYFactor = (length(spherePos) - CLOUDS_INNER_RADIUS) /
	                     (CLOUDS_OUTER_RADIUS - CLOUDS_INNER_RADIUS);
	coverage = smoothstep(sqrt(cloudYFactor), 1.0, coverage);

	// Fade the cloud layer at the top and the bottom
	coverage *= attenuation(
	    ((CLOUDS_INNER_RADIUS + CLOUDS_OUTER_RADIUS) * 0.5 - length(spherePos)
	    ) /
	    ((CLOUDS_OUTER_RADIUS - CLOUDS_INNER_RADIUS) * 0.5)
	);

	// Make the clouds more clumpy
	coverage = smoothstep(0.4, 0.6, coverage);

	return coverage;
}

// TODO: docs
// The full density of the cloud including the details
float cloudDensity(in vec3 spherePos, in vec2 worldOffset, in float shape) {
	float detail =
	    cloudDetail(spherePos + vec3(worldOffset.x, 0.0, worldOffset.y));

	// float cloudSurfaceFactor =
	//     smoothstep(0.1, 0.2, shape) - smoothstep(0.3, 0.4, shape);

	return shape; // * mix(1.0, detail, cloudSurfaceFactor);
	              // return cloudSurfaceFactor;
}

/**
 * @brief Calculates the color and transparency of the clouds in a given
 * direction.
 *
 * @param viewDir normalized view vector from fragment to camera in world space
 * @param lightDir normalized light vector from fragment to light in world space
 * @param origin origin of the ray in world space (used to position the clouds)
 * @param coverage cloud coverage, set to high for cloudy days
 * @param maxDistance maximum length of the ray, e.g. the distance to a mountain
 *
 * @return cloud color along with alpha blending value
 */
vec4 clouds(
    in vec3  viewDir,
    in vec3  lightDir,
    in vec3  origin,
    in float coverage,
    in float maxDistance
) {
	// origin.xz += CLOUDS_WIND * frameTimeCounter;

	// Negate the view vector to get the view direction.
	viewDir = -viewDir;

	vec2 worldOffset = origin.xz;
	origin           = vec3(0.0, origin.y + CLOUDS_VIEW_RADIUS, 0.0);

	// Intersect the two planes that define the cloud volume.
	Intersection innerIntersection =
	    intersectSphere(origin, viewDir, CLOUDS_INNER_RADIUS);
	Intersection outerIntersection =
	    intersectSphere(origin, viewDir, CLOUDS_OUTER_RADIUS);

	// If the outer sphere was not intersected, the clouds cannot be seen.
	// Same if the outer sphere is all behind the viewer.
	if (outerIntersection.near > outerIntersection.far ||
	    outerIntersection.far < 0.0) {
		return vec4(0.0);
	}

	// Find the start and end of the ray that is inside the cloud volume.
	float start, end;
	if (origin.y > CLOUDS_OUTER_RADIUS) {
		// If the viewer is above the cloud volume...
		start = outerIntersection.near;
		if (innerIntersection.near < innerIntersection.far &&
		    innerIntersection.near > 0.0 &&
		    outerIntersection.far > maxDistance) {
			// If the inner sphere was intersected...
			end = innerIntersection.near;
		} else {
			end = outerIntersection.far;
		}
	} else if (origin.y > CLOUDS_INNER_RADIUS) {
		// If the viewer is inside the cloud volume...
		start = 0.0;
		if (innerIntersection.near < innerIntersection.far &&
		    innerIntersection.near > 0.0 &&
		    outerIntersection.far > maxDistance) {
			// If the inner sphere was intersected...
			end = innerIntersection.near;
		} else {
			end = outerIntersection.far;
		}
	} else {
		// If the viewer is underneath the cloud volume...
		start = innerIntersection.far;
		end   = outerIntersection.far;
	}

	// Abort if the cloud volume is positioned behind the obstacle at
	// maxDistance.
	end = min(end, maxDistance);
	// end = min(end, 1000.0);
	if (start > end) {
		return vec4(0.0);
	}

	// the linear progress [0, 1] at which the sampling is the most dense
	// It starts at 0.0 and is updated whenever we encounter a new cloud.
	float samplingFocalPoint = 0.0;
	// Are we currently tracing a cloud?
	// used to detect the moment when we enter a cloud
	bool tracingCloud = false;
	// the actual progress along the ray during the previous iteration
	// only updated while not tracing a cloud
	float prevSamplingProgress = 0.0;
	// snapshot of prevSamplingProgress when we entered a cloud
	// Represents the progress along the ray just before entering the cloud.
	float entrySamplingProgress = 0.0;

	// the optical depth along the primary ray
	float opticalDepth = 0.0;

	// the accumulated scattered energy along the main ray
	vec3 directScattering  = vec3(0.0);
	vec3 ambientScattering = vec3(0.0);

	float backgroundVisibility = 1.0;

	// Integrate our way through the cloud volume.
	// This algorithm is analogous to the one used in the atmosphere shader.
	// see: /shaders/src/modules/sky.glsl
	for (int i = 0; i < CLOUDS_CLOUD_SAMPLES; i++) {
		float rand = hash(fract(viewDir * frameTimeCounter * 0.1)).x;
		float linearProgress =
		    (float(i) + rand) / float(CLOUDS_CLOUD_SAMPLES); // [0, 1)
		float samplingProgress = linearProgress;             // [0, 1)

		// // Remap samplingProgress from [samplingFocalPoint, 1) to [0, 1).
		// samplingProgress -= samplingFocalPoint;
		// samplingProgress /= 1.0 - samplingFocalPoint;

		// // parabolic ray progression
		// samplingProgress *= samplingProgress;

		// // Remap samplingProgress back from [0, 1) to [entrySamplingProgress,
		// // 1).
		// // entrySamplingProgress is the samplingProgress before entering the
		// // cloud volume.
		// samplingProgress *= 1.0 - entrySamplingProgress;
		// samplingProgress += entrySamplingProgress;

		vec3 samplePos = origin + viewDir * mix(start, end, samplingProgress);

		float shape = cloudShape(samplePos, worldOffset, coverage);
		// if (shape > EPSILON) {
		// 	// We are inside a cloud.
		// 	if (!tracingCloud) {
		// 		// We just entered a cloud.
		// 		// Update the focal point to increase local sampling density
		// 		samplingFocalPoint    = linearProgress;
		// 		entrySamplingProgress = prevSamplingProgress;

		// 		// Remember that we are tracing the cloud and continue with the
		// 		// new sampling pattern.
		// 		tracingCloud = true;

		// 		// We do not save prevSamplingProgress here because we're not
		// 		// sampling at all and going backwards along the ray.
		// 		continue;
		// 	}
		// } else {
		// 	// We are outside of a cloud.
		// 	tracingCloud = false;

		// 	// Empty space will not contribute to the optical depth.
		// 	prevSamplingProgress = samplingProgress;
		// 	continue;
		// }

		float stepSize = (samplingProgress - prevSamplingProgress) *
		                 (end - start); // always > 0
		prevSamplingProgress = samplingProgress;

		// At this point we are inside a cloud.
		// samplePos is the position of the current sample.

		float lightStart = 0.0;
		float lightEnd   = CLOUDS_LIGHT_TRACE_LENGTH;

		float lightPrevSamplingProgress = 0.0;

		// the optical depth along the whole secondary ray
		float lightOpticalDepth = 0.0;

		for (int j = 0; j < CLOUDS_LIGHT_SAMPLES; j++) {
			float lightRand = hash(fract(samplePos * frameTimeCounter * 0.1)).x;
			float lightSamplingProgress =
			    (float(j) + lightRand) / float(CLOUDS_LIGHT_SAMPLES);
			vec3 lightSamplePos =
			    samplePos +
			    lightDir * mix(lightStart, lightEnd, lightSamplingProgress);

			float lightStepSize =
			    (lightSamplingProgress - lightPrevSamplingProgress) *
			    (lightEnd - lightStart);
			lightPrevSamplingProgress = lightSamplingProgress;

			lightOpticalDepth +=
			    cloudShape(lightSamplePos, worldOffset, coverage) *
			    lightStepSize;
		}

		float density           = cloudDensity(samplePos, worldOffset, shape);
		float opticalDepthDelta = density * stepSize;
		opticalDepth            += opticalDepthDelta;

		// direct light in-scattering
		float lightAfterOutScattering =
		    exp(-(CLOUDS_MIE_PROB * (opticalDepth + lightOpticalDepth)));
		directScattering += lightAfterOutScattering * opticalDepthDelta;

		// ambient light in-scattering
		// We can use density value to estimate the mean optical depth of all
		// ambient rays
		float ambientLightOpticalDepth = shape * shape * shape * 100.0;
		float ambientLightAfterOutScattering =
		    exp(-(CLOUDS_MIE_PROB * (opticalDepth + ambientLightOpticalDepth)));
		ambientScattering += ambientLightAfterOutScattering * opticalDepthDelta;

		// End early.
		backgroundVisibility = exp(-(CLOUDS_MIE_PROB * opticalDepth));
		if (backgroundVisibility < 0.05) {
			break;
		}
	}
	backgroundVisibility -= 0.05;
	backgroundVisibility = clamp(backgroundVisibility, 0.0, 1.0);

	// Direct
	float cosTheta          = dot(viewDir, lightDir);
	vec3  inScatteredDirect = directScattering * CLOUDS_MIE_PROB *
	                         phaseHenyeyGreenstein(cosTheta, CLOUDS_G) *
	                         skyDirect(lightDir, true);

	// Ambient
	vec3 inScatteredAmbient =
	    ambientScattering * CLOUDS_MIE_PROB * skyIndirect(lightDir);

	vec3  energy       = inScatteredDirect + inScatteredAmbient;
	float cloudOpacity = 1.0 - backgroundVisibility;
	return vec4(energy, cloudOpacity);
}

#endif // CLOUDS_GLSL
