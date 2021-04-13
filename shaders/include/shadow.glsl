#ifndef SHADOW_GLSL
#define SHADOW_GLSL

#include "encoding.glsl"
#include "hash.glsl"
#include "ray_march.glsl"

// Defines precision gain towards the center of the shadow map in range (0.0, 1.0)
#define SHADOW_MAP_DISTORTION_STRENGTH 0.8
// How much the distorted shadow map is stretched to a rectangular shape [1.0 - inf)
#define SHADOW_MAP_DISTORTION_STRETCH  12.0

#define SHADOW_CONTACT_RAY_LENGTH    0.3  // Ray marching distance
#define SHADOW_CONTACT_SAMPLES       8    // Number of marching steps
#define SHADOW_CONTACT_TOLERANCE     0.05 // Max Z difference to score a hit
#define SHADOW_CONTACT_VIEW_DISTANCE 5.0
#define SHADOW_CONTACT_FADE_DISTANCE 2.0

float getContactShadow(
		in sampler2D depthTex,
		in vec3      viewPos,
		in vec3      lightDir) {
	float cutoffDistance = SHADOW_CONTACT_VIEW_DISTANCE + SHADOW_CONTACT_FADE_DISTANCE;

	if (-viewPos.z < cutoffDistance) {
		float stepLen = SHADOW_CONTACT_RAY_LENGTH / float(SHADOW_CONTACT_SAMPLES);
		
		//bool hit = rayMarch(depthTex, viewPos, lightDir, stepLen,
				//1.0, SHADOW_CONTACT_SAMPLES, SHADOW_CONTACT_TOLERANCE);
		RayMarchResult result = rayMarch(
				depthTex, viewPos, lightDir,
				SHADOW_CONTACT_RAY_LENGTH,
				SHADOW_CONTACT_SAMPLES,
				SHADOW_CONTACT_TOLERANCE);
		float shading = float(!result.hasHit);

		float fade = smoothstep(SHADOW_CONTACT_VIEW_DISTANCE,
				cutoffDistance, -viewPos.z);
		return mix(shading, 1.0, fade);
	} else
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

/**
 * Computes optionally colored shadow intensity factor.
 *
 * @param shadowMap       shadow depth texture (all objects)
 * @param shadowMapOpaque shadow depth texture (only opaque)
 * @param shadowColorTex  shadow color texture
 * @param shadowCoord     shadow coordinate
 *
 * @return shadow color
 */
vec3 getShadowColor(in sampler2D shadowMap, in sampler2D shadowMapOpaque, in sampler2D shadowColorTex, in vec3 shadowCoord) {
	//float contactShadow = getContactShadow(depthtex0, fragPos, L);

	float shading = step(shadowCoord.z, texture2D(shadowMap, shadowCoord.xy).x);
#ifdef COLORED_SHADOWS
	float opaqueShading = step(shadowCoord.z, texture2D(shadowMapOpaque, shadowCoord.xy).x);
	vec3 shadowColor = gammaToLinear(texture2D(shadowColorTex, shadowCoord.xy).xyz);
	return (opaqueShading - shading) * shadowColor + shading;
#else
	return vec3(shading);
#endif
}

float getShadowBias(in vec3 normal, in vec3 lightDir, in float distortionFactor) {
	float cosTheta = dot(normal, lightDir);
	float angleFactor = sqrt(1.0 - cosTheta * cosTheta) / cosTheta; // = tan(acos(cosTheta));
	return angleFactor / (distortionFactor * 1024.0);
}

vec3 getHardShadow(in sampler2D shadowMap, in sampler2D shadowMapOpaque, in sampler2D shadowColorTex, in vec3 viewPos, in vec3 normal, in vec3 lightDir) {
	vec3 shadowViewPos = (shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 shadowClipPos = projPos(shadowProjection, shadowViewPos);

	float distortionFactor = getShadowDistortionFactor(shadowClipPos.xy);
	shadowClipPos.xy *= distortionFactor;
	float bias = getShadowBias(normal, lightDir, distortionFactor);

	vec3 shadowCoord = shadowClipPos * 0.5 + vec3(0.5, 0.5, 0.5 - bias);
	return getShadowColor(shadowMap, shadowMapOpaque, shadowColorTex, shadowCoord);
}

#define SHADOW_DISTANCE_SAMPLES 8
#define SHADOW_SAMPLES 8
#define SHADOW_MIN_PENUMBRA 0.025
#define SHADOW_MAX_PENUMBRA 0.2 // In meters
#define SHADOW_SUN_ANGULAR_RADIUS (0.0087 * 4.0) // In radians, not physically accurate

vec3 getSoftShadow(
		in sampler2D shadowMap,
		in sampler2D shadowMapOpaque,
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
	
	// Estimate distance to occluder, if any
	float occlusionDepth = 0.0;
	float occludedSamples = 0.0;
	for (int i = 0; i < SHADOW_DISTANCE_SAMPLES; i++) {
		vec2 unitOffset = hashToCircleOffset(frameTimeCounter * viewPos + float(i));
		vec2 offsetShadowClipPos = shadowClipPos.xy + (unitOffset * SHADOW_MAX_PENUMBRA * shadowProjScale);
		offsetShadowClipPos *= getShadowDistortionFactor(offsetShadowClipPos);
		vec2 shadowUv = offsetShadowClipPos * 0.5 + 0.5;

		float occluderDepth = texture2D(shadowMap, shadowUv).x;
		float inShadow = step(occluderDepth, shadowDepth);
		occlusionDepth += occluderDepth * inShadow;
		occludedSamples += inShadow;
	}
	occlusionDepth /= occludedSamples;

	// Convert occluder depth to occlusion distance and compute penumbra radius
	float occluderShadowViewPosZ = projPos(shadowProjectionInverse, vec3(0.0, 0.0, occlusionDepth * 2.0 - 1.0)).z;
	float occlusionDistance = distance(shadowViewPos.z, occluderShadowViewPosZ);
	float penumbraRadius = tan(SHADOW_SUN_ANGULAR_RADIUS) * occlusionDistance;
	// Scale minimum penumbra radius with shadow resolution, so no self-shadowing occurs
	float minPenumbra = min(SHADOW_MIN_PENUMBRA, SHADOW_MIN_PENUMBRA * (shadowMapResolution / 2048.0));
	penumbraRadius = clamp(penumbraRadius, minPenumbra, SHADOW_MAX_PENUMBRA);

	vec3 color = vec3(0.0);
	for (int i = 0; i < SHADOW_SAMPLES; i++) {
		vec2 unitOffset = hashToCircleOffset(frameTimeCounter * viewPos + float(i));
		vec2 offsetShadowClipPos = shadowClipPos.xy + (unitOffset * penumbraRadius * shadowProjScale);
		offsetShadowClipPos *= getShadowDistortionFactor(offsetShadowClipPos);
		vec3 shadowCoord = vec3(offsetShadowClipPos * 0.5 + 0.5, shadowDepth);

		color += getShadowColor(shadowMap, shadowMapOpaque, shadowColorTex, shadowCoord);
	}
	return color / float(SHADOW_SAMPLES);
}

#endif // SHADOW_GLSL
