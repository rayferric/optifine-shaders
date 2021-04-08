#ifndef SHADOW_GLSL
#define SHADOW_GLSL

#include "encoding.glsl"
#include "hash.glsl"

// Defines precision gain towards the center of the shadow map in range (0.0, 1.0)
#define SHADOW_MAP_DISTORTION_STRENGTH 0.8
// How much the distorted shadow map is stretched to a rectangular shape [1.0 - inf)
#define SHADOW_MAP_DISTORTION_STRETCH  12.0

uniform mat4 shadowModelViewInverse;

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

// @return whether shadow coordinates are in shadow
float sampleShadowMap(in sampler2D shadowMap, in vec3 shadowCoord) {
	return float(texture2D(shadowMap, shadowCoord.xy).x > shadowCoord.z);
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
vec3 sampleShadowColor(in sampler2D shadowMap, in sampler2D shadowMapOpaque, in sampler2D shadowColorTex, in vec3 shadowCoord) {
	float shading = sampleShadowMap(shadowMap, shadowCoord);
#ifdef COLORED_SHADOWS
	float opaqueShading = sampleShadowMap(shadowMapOpaque, shadowCoord);
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
	return sampleShadowColor(shadowMap, shadowMapOpaque, shadowColorTex, shadowCoord);
}

#define SHADOW_CONTACT_DISTANCE       0.2  // Ray marching distance
#define SHADOW_CONTACT_TOLERANCE      0.05 // Max Z difference to score a hit
#define SHADOW_CONTACT_BASE_SAMPLES   8    // Number of marching steps
#define SHADOW_CONTACT_REFINE_SAMPLES 4    // Number of refinement steps

// Call this once origin is behind the depth buffer
vec3 binaryRefine(in vec3 origin, in vec3 offset, in sampler2D depthTex) {
	vec3 lastBehind = origin;

	// We're currently behind the depth buffer, so let's go halfway back
	offset *= 0.5;
	origin -= offset;

	for (int i = 0; i < SHADOW_CONTACT_REFINE_SAMPLES; i++) {
		vec3  coord = projPos(gbufferProjection, origin) * 0.5 + 0.5;
		float depth = texture2D(depthTex, coord.xy).x;

		bool inFront = depth > coord.z;

		// Mark more precise position, which
		// is still behind the depth buffer
		lastBehind = mix(origin, lastBehind, float(inFront));

		// Trace forward once we got in front of it
		offset *= 0.5;
		origin += inFront ? offset : -offset;
	}

	return lastBehind;
}

vec3 getContactShadow(
		in sampler2D depthTex,
		in vec3      viewPos,
		in vec3      lightDir) {
	vec3 origin = viewPos;
	vec3 offset = lightDir * (SHADOW_CONTACT_DISTANCE / float(SHADOW_CONTACT_BASE_SAMPLES));

	for (int i = 0; i < SHADOW_CONTACT_BASE_SAMPLES; i++) {
		origin += offset;
		vec3  coord = projPos(gbufferProjection, origin) * 0.5 + 0.5;
		float depth = texture2D(depthTex, coord.xy).x;

		// Once we're behind the depth buffer
		if (coord.z > depth) {
			origin = binaryRefine(origin, offset, depthTex);
			coord  = projPos(gbufferProjection, origin) * 0.5 + 0.5;
			depth  = texture2D(depthTex, coord.xy).x;

			// Break if refinement didn't move the origin close enough
			if (distance(-origin.z, linearizeDepth(depth)) > SHADOW_CONTACT_TOLERANCE)
				break;
			
			return vec3(0.0);
		}
	}

	return vec3(1.0);
}

#define SHADOW_DISTANCE_SAMPLES 8
#define SHADOW_SAMPLES 8
#define SHADOW_MIN_PENUMBRA 0.02
#define SHADOW_MAX_PENUMBRA 0.2 // In meters
#define SHADOW_SUN_ANGULAR_RADIUS (0.087) // In radians, not physically accurate

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

	float occlusionDepth = 1.0;
	int occludedSamples = 0;
	for (int i = 0; i < SHADOW_DISTANCE_SAMPLES; i++) {
		vec2 unitOffset = hashToCircleOffset(frameTimeCounter * viewPos + float(i)) * hash(viewPos + float(i));
		vec2 offsetShadowClipPos = shadowClipPos.xy + (unitOffset * SHADOW_MAX_PENUMBRA * shadowProjScale);
		offsetShadowClipPos *= getShadowDistortionFactor(offsetShadowClipPos);
		vec2 shadowUv = offsetShadowClipPos * 0.5 + 0.5;

		float occluderDepth = texture2D(shadowMap, shadowUv).x;
		bool inShadow = occluderDepth < shadowDepth;
		occlusionDepth = min(occlusionDepth, inShadow ? occluderDepth : occlusionDepth);
		occludedSamples += int(inShadow);
	}

	// Cut short in case of full umbra
	if (occludedSamples == SHADOW_DISTANCE_SAMPLES) {
		shadowClipPos.xy *= distortionFactor;
		vec3 shadowCoord = vec3(shadowClipPos.xy * 0.5 + 0.5, shadowDepth);
		return sampleShadowColor(shadowMap, shadowMapOpaque, shadowColorTex, shadowCoord);
	}
	// Otherwise we're sampling in penumbra (or full light)

	// Convert occluder depth to occlusion distance and compute penumbra radius
	float occluderShadowViewPosZ = projPos(shadowProjectionInverse, vec3(0.0, 0.0, occlusionDepth * 2.0 - 1.0)).z;
	float occlusionDistance = distance(shadowViewPos.z, occluderShadowViewPosZ);
	float penumbraRadius = tan(SHADOW_SUN_ANGULAR_RADIUS) * occlusionDistance;
	penumbraRadius = clamp(penumbraRadius, SHADOW_MIN_PENUMBRA, SHADOW_MAX_PENUMBRA);

	vec3 color = vec3(0.0);
	for (int i = 0; i < SHADOW_SAMPLES; i++) {
		vec2 unitOffset = hashToCircleOffset(frameTimeCounter * viewPos + float(i)) * hash(viewPos + float(i));
		vec2 offsetShadowClipPos = shadowClipPos.xy + (unitOffset * penumbraRadius * shadowProjScale);
		offsetShadowClipPos *= getShadowDistortionFactor(offsetShadowClipPos);
		vec3 shadowCoord = vec3(offsetShadowClipPos * 0.5 + 0.5, shadowDepth);

		color += sampleShadowColor(shadowMap, shadowMapOpaque, shadowColorTex, shadowCoord);
	}
	return color / float(SHADOW_SAMPLES);
}

#endif // SHADOW_GLSL
