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

/**
 * Transforms fragment from player's view to shadow camera's clip space.
 * Applies angle-weighted depth bias in the process.
 *
 * @param viewPos  view space position
 * @param cosTheta cosine of the shadow angle, dot(N, L)
 *
 * @return shadow coordinate, ready to be plugged into shadow2D()
 */
vec3 getShadowCoord(in vec3 viewPos, in float cosTheta) {
	vec4 shadowPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0);
	shadowPos.xyz /= shadowPos.w;

	float distortionFactor = getShadowDistortionFactor(shadowPos.xy);
	shadowPos.xy *= distortionFactor;

	float angleFactor = sqrt(1.0 - cosTheta * cosTheta) / cosTheta; // = tan(acos(cosTheta));
	float bias = angleFactor / (distortionFactor * shadowMapResolution) * 2.0;
	
	return shadowPos.xyz * 0.5 + vec3(0.5, 0.5, 0.5 - bias);
}

/**
 * Samples a shadow map with optional interpolation.
 *
 * @param shadowMap   shadow map to sample
 * @param shadowCoord shadow coordinate
 *
 * @return shading factor
 */
float sampleShadowMap(in sampler2DShadow shadowMap, in vec3 shadowCoord) {
#ifdef SHADOW_FILTER
	float texelSize = 1.0 / shadowMapResolution;
	vec2 texelCoord = shadowCoord.xy * shadowMapResolution + 0.5;

	vec2 center = floor(texelCoord) * texelSize;
	vec2 f = fract(texelCoord);

	vec2 offset = vec2(0.0, texelSize);

	float bl = shadow2D(shadowMap, vec3(center + offset.xx, shadowCoord.z)).x;
	float tl = shadow2D(shadowMap, vec3(center + offset.xy, shadowCoord.z)).x;
	float br = shadow2D(shadowMap, vec3(center + offset.yx, shadowCoord.z)).x;
	float tr = shadow2D(shadowMap, vec3(center + offset.yy, shadowCoord.z)).x;

	float l = mix(bl, tl, f.y);
	float r = mix(br, tr, f.y);
	return mix(l, r, f.x);
#else
	return shadow2D(shadowMap, shadowCoord).x;
#endif
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
vec3 getShadowColor(in sampler2DShadow shadowMap, in sampler2DShadow shadowMapOpaque, in sampler2D shadowColorTex, in vec3 shadowCoord) {
	float shading = sampleShadowMap(shadowMap, shadowCoord);
#ifdef COLORED_SHADOWS
	float opaqueShading = sampleShadowMap(shadowMapOpaque, shadowCoord);
	vec3 shadowColor = gammaToLinear(texture2D(shadowColorTex, shadowCoord.xy).xyz);
	return (opaqueShading - shading) * shadowColor + shading;
#else
	return vec3(shading);
#endif
}

#define SUN_ANGULAR_RADIUS (0.0087 * 20.0) // In radians

float getTemporalShadow(in sampler2D shadowMap, in vec3 viewPos) {
	vec4 shadowPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0);
	shadowPos.xyz /= shadowPos.w;

	float distortionFactor = getShadowDistortionFactor(shadowPos.xy);
	shadowPos.xy *= distortionFactor;

	vec3 shadowCoord = shadowPos.xyz * 0.5 + 0.5;
	float occluderDepth = texture2D(shadowMap, shadowCoord.xy).x;
	vec3 occluderShadowPos = vec3(shadowCoord.xy, occluderDepth) * 2.0 - 1.0;
	occluderShadowPos.xy /= distortionFactor;

	vec4 occluderViewPos = shadowProjectionInverse * vec4(occluderShadowPos, 1.0);
	occluderViewPos.xyz /= occluderViewPos.w;
	occluderViewPos = gbufferModelView * shadowModelViewInverse * occluderViewPos;

	// This is the real distance between the occluder and the fragment
	float dist = distance(viewPos, occluderViewPos.xyz);
	float jitterRadius = dist * tan(SUN_ANGULAR_RADIUS);
	//jitterRadius = min(jitterRadius, 0.2);

	float shade = 0.0;
	{
	vec4 newShadowPos = shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0);
	newShadowPos.xy += hashCircleDir(viewPos * frameTimeCounter) * hash(viewPos * frameTimeCounter) * jitterRadius;
	newShadowPos = shadowProjection * newShadowPos;
	newShadowPos.xyz /= newShadowPos.w;

	float newDistortionFactor = getShadowDistortionFactor(newShadowPos.xy);
	newShadowPos.xy *= distortionFactor;

	vec3 newShadowCoord = newShadowPos.xyz * 0.5 + 0.5;
	shade += float(texture2D(shadowMap, newShadowCoord.xy).x > newShadowCoord.z - 0.0001);
	}{
	vec4 newShadowPos = shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0);
	newShadowPos.xy += hashCircleDir(viewPos * frameTimeCounter) * hash(viewPos * frameTimeCounter) * jitterRadius;
	newShadowPos = shadowProjection * newShadowPos;
	newShadowPos.xyz /= newShadowPos.w;

	float newDistortionFactor = getShadowDistortionFactor(newShadowPos.xy);
	newShadowPos.xy *= distortionFactor;

	vec3 newShadowCoord = newShadowPos.xyz * 0.5 + 0.5;
	shade += float(texture2D(shadowMap, newShadowCoord.xy).x > newShadowCoord.z - 0.0001);
	}{
	vec4 newShadowPos = shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0);
	newShadowPos.xy += hashCircleDir(viewPos * frameTimeCounter) * hash(viewPos * frameTimeCounter) * jitterRadius;
	newShadowPos = shadowProjection * newShadowPos;
	newShadowPos.xyz /= newShadowPos.w;

	float newDistortionFactor = getShadowDistortionFactor(newShadowPos.xy);
	newShadowPos.xy *= distortionFactor;

	vec3 newShadowCoord = newShadowPos.xyz * 0.5 + 0.5;
	shade += float(texture2D(shadowMap, newShadowCoord.xy).x > newShadowCoord.z - 0.0001);
	}
	return shade / 3.0;
}

#endif // SHADOW_GLSL
