#ifndef SHADOW_GLSL
#define SHADOW_GLSL

#include "/include/modules/encode.glsl"
#include "/include/modules/hash.glsl"
#include "/include/modules/normalized_mul.glsl"
#include "/include/modules/raymarch.glsl"
#include "/include/modules/shadow_distortion.glsl"

#define CONTACT_SHADOW_RAY_LENGTH    0.3  // Ray marching distance
#define CONTACT_SHADOW_BIAS          0.02 // Offset ray origin to avoid self-shading at grazing angles
#define CONTACT_SHADOW_TOLERANCE     0.05 // Max Z difference to score a hit
#define CONTACT_SHADOW_VIEW_DISTANCE 12.0
#define CONTACT_SHADOW_FADE_DISTANCE 2.0

#define SHADOW_FADE_DISTANCE 50.0

float contactShadow(in vec3 viewPos, in vec3 lightDir) {
#if CONTACT_SHADOW_SAMPLES != 0
	if (-viewPos.z < CONTACT_SHADOW_VIEW_DISTANCE) {
		RayMarchResult result = rayMarch(
				depthtex1, viewPos, lightDir,
				CONTACT_SHADOW_RAY_LENGTH,
				CONTACT_SHADOW_BIAS,
				CONTACT_SHADOW_SAMPLES,
				CONTACT_SHADOW_TOLERANCE,
				CONTACT_SHADOW_TOLERANCE);

		float opacity = 1.0 - smoothstep(CONTACT_SHADOW_VIEW_DISTANCE - CONTACT_SHADOW_FADE_DISTANCE,
				CONTACT_SHADOW_VIEW_DISTANCE, -viewPos.z);

		return 1.0 - float(result.hasHit) * opacity;
	}
#endif
	return 1.0;
}

float getShadowBias(in vec3 normal, in vec3 lightDir, in float distortionFactor) {
	float cosTheta = dot(normal, lightDir);
	float angleFactor = sqrt(1.0 - cosTheta * cosTheta) / cosTheta; // = tan(acos(cosTheta));
	return angleFactor / (distortionFactor * 1024.0);
}

/**
 * Computes colored shadow intensity factor.
 *
 * @param shadowCoord     shadow coordinate
 *
 * @return shadow color
 */
vec3 getShadowColor(in vec3 shadowCoord) {
	float shading       = step(shadowCoord.z, texture2D(shadowtex0, shadowCoord.xy).x);
	float opaqueShading = step(shadowCoord.z, texture2D(shadowtex1, shadowCoord.xy).x);

	vec3 shadowColor = gammaToLinear(texture2D(shadowcolor0, shadowCoord.xy).xyz);

	return (opaqueShading - shading) * shadowColor + shading;
}

#define COLORED_VOLUMETRICS

/**
 * Computes unfiltered, unbiased shadow
 * for the purpose of volumetric effects.
 *
 * @param viewPos sample position in view space
 *
 * @return shadow color
 */
vec3 getVolumetricShadow(in vec3 viewPos) {
	// TODO: We could trace volumetric fog in
	// shadow clip space for enhanced performance,
	// see: /include/modules/raymarch.glsl

	vec3 shadowViewPos = (shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 shadowClipPos = normalizedMul(shadowProjection, shadowViewPos);

	float distortionFactor = getShadowDistortionFactor(shadowClipPos.xy);
	shadowClipPos.xy *= distortionFactor;
	vec3 shadowCoord = shadowClipPos * 0.5 + 0.5;

	// if (!isInsideRect(shadowCoord.xy, vec2(0.0), vec2(1.0)))
	// 		return vec3(1.0);

	#ifdef COLORED_VOLUMETRICS
		return getShadowColor(shadowCoord);
	#else
		return step(shadowCoord.z, texture2D(shadowtex0, shadowCoord.xy).x);
	#endif
}

#define SHADOW_DISTANCE_SAMPLES 8
#define SHADOW_MIN_PENUMBRA 0.025
#define SHADOW_MAX_PENUMBRA 0.2 // In meters
#define SHADOW_SUN_ANGULAR_RADIUS (0.0087 * 4.0) // In radians, not physically accurate

vec3 softShadow(in vec3 viewPos, in vec3 normal, in vec3 lightDir) {
	// Transform position to shadow camera space and compute bias

	float cosTheta = dot(normal, lightDir);
	vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 shadowViewPos = (shadowModelView * vec4(worldPos, 1.0)).xyz;
	vec3 shadowClipPos = normalizedMul(shadowProjection, shadowViewPos);
	float distortionFactor = getShadowDistortionFactor(shadowClipPos.xy);
	float bias = getShadowBias(normal, lightDir, distortionFactor);
	float shadowDepth = shadowClipPos.z * 0.5 + 0.5 - bias;

	float opacity = 1.0 - smoothstep(250.0 - SHADOW_FADE_DISTANCE, 250.0, -shadowViewPos.z);
	opacity *= 1.0 - smoothstep(shadowDistance - SHADOW_FADE_DISTANCE, shadowDistance, length(worldPos.xy));
	if (opacity < EPSILON)
		return vec3(1.0);		

	// Inverse shadow camera extents
	vec2 shadowProjScale = vec2(shadowProjection[0][0], shadowProjection[1][1]);

#ifdef VARIABLE_PENUMBRA_SHADOW
	// Estimate distance to occluder, if any
	float occlusionDepth = 0.0;
	float occludedSamples = 0.0;
	for (int i = 0; i < SHADOW_DISTANCE_SAMPLES; i++) {
		vec2 unitOffset = hashToCircleOffset(frameTimeCounter * viewPos + float(i));
		vec2 offsetShadowClipPos = shadowClipPos.xy + (unitOffset * SHADOW_MAX_PENUMBRA * shadowProjScale);
		offsetShadowClipPos *= getShadowDistortionFactor(offsetShadowClipPos);
		vec2 shadowUv = offsetShadowClipPos * 0.5 + 0.5;

		float occluderDepth = texture2D(shadowtex0, shadowUv).x;
		float inShadow = step(occluderDepth, shadowDepth);
		occlusionDepth += occluderDepth * inShadow;
		occludedSamples += inShadow;
	}
	occlusionDepth /= occludedSamples;

	// Convert occluder depth to occlusion distance and compute penumbra radius
	float occluderShadowViewPosZ = normalizedMul(shadowProjectionInverse, vec3(0.0, 0.0, occlusionDepth * 2.0 - 1.0)).z;
	float occlusionDistance = distance(shadowViewPos.z, occluderShadowViewPosZ);
	float penumbraRadius = tan(SHADOW_SUN_ANGULAR_RADIUS) * occlusionDistance;
#else
	float penumbraRadius = SHADOW_MIN_PENUMBRA;
#endif

	// Scale minimum penumbra radius with shadow resolution, so no self-shadowing occurs
	float minPenumbra = min(SHADOW_MIN_PENUMBRA, SHADOW_MIN_PENUMBRA * (shadowMapResolution / 2048.0));
	penumbraRadius = clamp(penumbraRadius, minPenumbra, SHADOW_MAX_PENUMBRA);

	vec3 color = vec3(0.0);
	for (int i = 0; i < SOFT_SHADOW_SAMPLES; i++) {
		vec2 unitOffset = hashToCircleOffset(frameTimeCounter * viewPos + float(i));
		vec2 offsetShadowClipPos = shadowClipPos.xy + (unitOffset * penumbraRadius * shadowProjScale);
		offsetShadowClipPos *= getShadowDistortionFactor(offsetShadowClipPos);
		vec3 shadowCoord = vec3(offsetShadowClipPos * 0.5 + 0.5, shadowDepth);

		#ifdef COLORED_SHADOW
			color += getShadowColor(shadowCoord);
		#else
			color += step(shadowCoord.z, texture2D(shadowtex0, shadowCoord.xy).x);
		#endif
	}
	return mix(vec3(1.0), 
	color / float(SOFT_SHADOW_SAMPLES), opacity);;
}

#endif // SHADOW_GLSL