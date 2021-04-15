#ifndef SHADOW_GLSL
#define SHADOW_GLSL

#include "encoding.glsl"
#include "hash.glsl"
#include "raymarch.glsl"

// Defines precision gain towards the center of the shadow map in range (0.0, 1.0)
#define SHADOW_MAP_DISTORTION_STRENGTH 0.8
// How much the distorted shadow map is stretched to a rectangular shape [1.0 - inf)
#define SHADOW_MAP_DISTORTION_STRETCH  12.0

#define CONTACT_SHADOW_RAY_LENGTH    0.3  // Ray marching distance
#define CONTACT_SHADOW_BIAS          0.02 // Offset ray origin to avoid self-shading at grazing angles
#define CONTACT_SHADOW_TOLERANCE     0.05 // Max Z difference to score a hit
#define CONTACT_SHADOW_VIEW_DISTANCE 5.0
#define CONTACT_SHADOW_FADE_DISTANCE 2.0

float getContactShadow(
		in sampler2D depthTex,
		in vec3      viewPos,
		in vec3      lightDir) {
#if CONTACT_SHADOW_SAMPLES != 0
	float cutoffDistance = CONTACT_SHADOW_VIEW_DISTANCE + CONTACT_SHADOW_FADE_DISTANCE;

	if (-viewPos.z < cutoffDistance) {
		float stepLen = CONTACT_SHADOW_RAY_LENGTH / float(CONTACT_SHADOW_SAMPLES);
		
		RayMarchResult result = rayMarch(
				depthTex, viewPos, lightDir,
				CONTACT_SHADOW_RAY_LENGTH,
				CONTACT_SHADOW_BIAS,
				CONTACT_SHADOW_SAMPLES,
				CONTACT_SHADOW_TOLERANCE);

		float opacity = 1.0 - smoothstep(CONTACT_SHADOW_VIEW_DISTANCE,
				cutoffDistance, -viewPos.z);

		return 1.0 - float(result.hasHit) * opacity;
	}
#endif
	return 1.0;
}

/**
 * Computes vertex position scaling factor used
 * to direct more texels to areas close to camera.
 *
 * @param pos undistorted position
 *
 * @return scaling factor, multiply it by pos to get remapped coordinate
 */
float getShadowDistortionFactor(in vec2 pos) {
	vec2 p = pow(abs(pos), vec2(SHADOW_MAP_DISTORTION_STRETCH));
	float d = pow(p.x + p.y, 1.0 / SHADOW_MAP_DISTORTION_STRETCH);
	d = mix(1.0, d, SHADOW_MAP_DISTORTION_STRENGTH);
	return 1.0 / d;
}

float getShadowBias(in vec3 normal, in vec3 lightDir, in float distortionFactor) {
	float cosTheta = dot(normal, lightDir);
	float angleFactor = sqrt(1.0 - cosTheta * cosTheta) / cosTheta; // = tan(acos(cosTheta));
	return angleFactor / (distortionFactor * 1024.0);
}

/**
 * Computes colored shadow intensity factor.
 *
 * @param shadowTex       shadow depth texture (all objects)
 * @param shadowTexOpaque shadow depth texture (only opaque)
 * @param shadowColorTex  shadow color texture
 * @param shadowCoord     shadow coordinate
 *
 * @return shadow color
 */
vec3 getShadowColor(in sampler2D shadowTex, in sampler2D shadowTexOpaque, in sampler2D shadowColorTex, in vec3 shadowCoord) {
	float shading       = step(shadowCoord.z, texture2D(shadowTex, shadowCoord.xy).x);
	float opaqueShading = step(shadowCoord.z, texture2D(shadowTexOpaque, shadowCoord.xy).x);

	vec3 shadowColor = gammaToLinear(texture2D(shadowColorTex, shadowCoord.xy).xyz);

	return (opaqueShading - shading) * shadowColor + shading;
}

#define COLORED_VOLUMETRICS

/**
 * Computes unfiltered, unbiased shadow
 * for the purpose of volumetric effects.
 *
 * @param shadowTex       shadow depth texture (all objects)
 * @param shadowTexOpaque shadow depth texture (only opaque)
 * @param shadowColorTex  shadow color texture
 * @param viewPos         sample position in view space
 *
 * @return shadow color
 */
vec3 getVolumetricShadow(in sampler2D shadowTex, in sampler2D shadowTexOpaque, in sampler2D shadowColorTex, in vec3 viewPos) {
	vec3 shadowViewPos = (shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 shadowClipPos = projPos(shadowProjection, shadowViewPos);

	float distortionFactor = getShadowDistortionFactor(shadowClipPos.xy);
	shadowClipPos.xy *= distortionFactor;
	vec3 shadowCoord = shadowClipPos * 0.5 + 0.5;

	#ifdef COLORED_VOLUMETRICS
		return getShadowColor(shadowTex, shadowTexOpaque, shadowColorTex, shadowCoord);
	#else
		return step(shadowCoord.z, texture2D(shadowTex, shadowCoord.xy).x);
	#endif
}

#define SHADOW_DISTANCE_SAMPLES 8
#define SHADOW_MIN_PENUMBRA 0.025
#define SHADOW_MAX_PENUMBRA 0.2 // In meters
#define SHADOW_SUN_ANGULAR_RADIUS (0.0087 * 4.0) // In radians, not physically accurate

vec3 getSoftShadow(
		in sampler2D shadowTex,
		in sampler2D shadowTexOpaque,
		in sampler2D shadowColorTex,
		in vec3      viewPos,
		in vec3      normal,
		in vec3      lightDir) {
	// Transform position to shadow camera space and compute bias

	float cosTheta = dot(normal, lightDir);
	vec3 shadowViewPos = (shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 shadowClipPos = projPos(shadowProjection, shadowViewPos);
	float distortionFactor = getShadowDistortionFactor(shadowClipPos.xy);
	float bias = getShadowBias(normal, lightDir, distortionFactor);
	float shadowDepth = shadowClipPos.z * 0.5 + 0.5 - bias;

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

		float occluderDepth = texture2D(shadowTex, shadowUv).x;
		float inShadow = step(occluderDepth, shadowDepth);
		occlusionDepth += occluderDepth * inShadow;
		occludedSamples += inShadow;
	}
	occlusionDepth /= occludedSamples;

	// Convert occluder depth to occlusion distance and compute penumbra radius
	float occluderShadowViewPosZ = projPos(shadowProjectionInverse, vec3(0.0, 0.0, occlusionDepth * 2.0 - 1.0)).z;
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
			color += getShadowColor(shadowTex, shadowTexOpaque, shadowColorTex, shadowCoord);
		#else
			color += step(shadowCoord.z, texture2D(shadowTex, shadowCoord.xy).x);
		#endif
	}
	return color / float(SOFT_SHADOW_SAMPLES);
}

#endif // SHADOW_GLSL
