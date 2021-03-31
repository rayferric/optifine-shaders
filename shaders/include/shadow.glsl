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

vec3 getHardShadow(in sampler2D shadowMap, in sampler2D shadowMapOpaque, in sampler2D shadowColorTex, in vec3 viewPos, in vec3 normal, in vec3 lightDir) {
	float cosTheta = dot(normal, lightDir);

	vec3 shadowViewPos = (shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 shadowClipPos = projPos(shadowProjection, shadowViewPos);

	float distortionFactor = getShadowDistortionFactor(shadowClipPos.xy);
	shadowClipPos.xy *= distortionFactor;

	float angleFactor = sqrt(1.0 - cosTheta * cosTheta) / cosTheta; // = tan(acos(cosTheta));
	float bias = angleFactor / (distortionFactor * 1048.0);

	vec3 shadowCoord = shadowClipPos * 0.5 + vec3(0.5, 0.5, 0.5 - bias);
	return sampleShadowColor(shadowMap, shadowMapOpaque, shadowColorTex, shadowCoord);
}

#define SHADOW_DISTANCE_SAMPLES 32
#define SHADOW_SAMPLES 32
#define SHADOW_RADIUS 0.2 // In meters
#define SHADOW_SUN_ANGULAR_RADIUS (0.0087 * 3.0) // In radians

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
	float angleFactor = sqrt(1.0 - cosTheta * cosTheta) / cosTheta; // = tan(acos(cosTheta));
	float bias = angleFactor / (distortionFactor * 1024.0);
	
	// Estimate distance to the occluder, if any

	float occlusionDistance = 0.0;
	int occludedSamples = 0;
	for (int i = 0; i < SHADOW_DISTANCE_SAMPLES; i++) {
		vec2 unitOffset = hashCircleDir(frameTimeCounter * viewPos + float(i)) * sqrt(hash(viewPos + float(i)));
		vec3 offsetShadowClipPos = projPos(shadowProjection, shadowViewPos + vec3(unitOffset * SHADOW_RADIUS, 0.0));

		float offsetDistortionFactor = getShadowDistortionFactor(offsetShadowClipPos.xy);

		offsetShadowClipPos.xy *= offsetDistortionFactor;
		vec3 shadowCoord = offsetShadowClipPos * 0.5 + vec3(0.5, 0.5, 0.5 - bias);

		float occluderDepth = texture2D(shadowMap, shadowCoord.xy).x;
		if (occluderDepth < shadowCoord.z) {
			vec3 occluderShadowClipPos = vec3(shadowCoord.xy, occluderDepth) * 2.0 - 1.0;
			occluderShadowClipPos.xy /= offsetDistortionFactor;
			vec3 occluderShadowViewPos = projPos(shadowProjectionInverse, occluderShadowClipPos);

			occlusionDistance += distance(shadowViewPos, occluderShadowViewPos);
			occludedSamples++;
		}
	}
	
	if (occludedSamples == 0) // Full light
		return vec3(1.0);
	else if (occludedSamples == SHADOW_SAMPLES) { // Umbra
		shadowClipPos.xy *= distortionFactor;
		vec3 shadowCoord = shadowClipPos * 0.5 + vec3(0.5, 0.5, 0.5 - bias);
		return sampleShadowColor(shadowMap, shadowMapOpaque, shadowColorTex, shadowCoord);
	}

	// Otherwise we're sampling in penumbra

	occlusionDistance /= float(occludedSamples);
	float shadowRadius = tan(SHADOW_SUN_ANGULAR_RADIUS) * occlusionDistance;
	shadowRadius = clamp(shadowRadius, 0.02, SHADOW_RADIUS);

	vec3 color = vec3(0.0);
	for (int i = 0; i < SHADOW_SAMPLES; i++) {
		vec2 unitOffset = hashCircleDir(frameTimeCounter * viewPos + float(i)) * sqrt(hash(viewPos + float(i)));
		vec3 offsetShadowClipPos = projPos(shadowProjection, shadowViewPos + vec3(unitOffset * shadowRadius, 0.0));

		float offsetDistortionFactor = getShadowDistortionFactor(offsetShadowClipPos.xy);

		offsetShadowClipPos.xy *= offsetDistortionFactor;
		vec3 shadowCoord = offsetShadowClipPos * 0.5 + vec3(0.5, 0.5, 0.5 - bias);

		color += sampleShadowColor(shadowMap, shadowMapOpaque, shadowColorTex, shadowCoord);
	}
	return color / float(SHADOW_SAMPLES);
}

#endif // SHADOW_GLSL
