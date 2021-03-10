#ifndef SHADOW_GLSL
#define SHADOW_GLSL

float getShadowDistortionFactor(in vec2 pos) {
	vec2 p = pow(abs(pos), vec2(SHADOW_MAP_DISTORTION_STRETCH));
	float d = pow(p.x + p.y, 1.0 / SHADOW_MAP_DISTORTION_STRETCH);
	d = mix(1.0, d, SHADOW_MAP_DISTORTION_STRENGTH);
	return 1.0 / d;
}

vec3 getShadowCoord(in vec3 fragPos, in float cosTheta) {
	vec4 shadowPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(fragPos, 1.0);
	shadowPos.xyz /= shadowPos.w;

	float distortionFactor = getShadowDistortionFactor(shadowPos.xy);
	shadowPos.xy *= distortionFactor;

	float angleFactor = sqrt(1.0 - cosTheta * cosTheta) / cosTheta; // = tan(acos(cosTheta));
	float bias = angleFactor / (distortionFactor * shadowMapResolution) * 2.0;
	
	return shadowPos.xyz * 0.5 + vec3(0.5, 0.5, 0.5 - bias);
}

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

vec3 getShadowColor(in sampler2DShadow shadowMap, in sampler2DShadow opaqueShadowMap, in sampler2D shadowColorTex, in vec3 shadowCoord) {
	float shading = sampleShadowMap(shadowMap, shadowCoord);
#ifdef COLORED_SHADOWS
	float opaqueShading = sampleShadowMap(opaqueShadowMap, shadowCoord);
	vec3 shadowColor = texture2D(shadowColorTex, shadowCoord.xy).xyz;
	return (opaqueShading - shading) * shadowColor + shading;
#else
	return vec3(shading);
#endif
}

#endif // SHADOW_GLSL
