#ifndef SHADOW_GLSL
#define SHADOW_GLSL

float getShadowDistortFactor(in vec2 pos) {
	vec2 p = pow(abs(pos), vec2(SHADOW_MAP_DISTORT_STRETCH));
	float d = pow(p.x + p.y, 1.0 / SHADOW_MAP_DISTORT_STRETCH);
	d = mix(1.0, d, SHADOW_MAP_DISTORT_STRENGTH);
	return 1.0 / d;
}

vec3 getShadowCoord(in vec3 fragPos, in float cosTheta, in bool selfShadowing) {
	vec4 shadowPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(fragPos, 1.0);
	shadowPos.xyz /= shadowPos.w;

	float distortFactor = getShadowDistortFactor(shadowPos.xy);
	shadowPos.xy *= distortFactor;

	float angleFactor = sqrt(1 - cosTheta * cosTheta) / cosTheta; // = tan(acos(cosTheta));
	float bias = angleFactor / (distortFactor * shadowMapResolution) * 2.0;
	if(selfShadowing)bias = 0.0005;
	
	return shadowPos.xyz * 0.5 + vec3(0.5, 0.5, 0.5 - bias);
}

float sampleShadowMap(in sampler2DShadow shadowMap, in vec3 shadowCoord) {
#ifdef SHADOW_FILTER

	float texelSize = 1.0 / shadowMapResolution;
	vec2 texelCoord = shadowCoord.xy * shadowMapResolution + 0.5;

    vec2 center = floor(texelCoord) * texelSize;
	vec2 f = fract(texelCoord);

	vec2 offset = vec2(0.0, texelSize);

    float bl = shadow2D(shadowMap, vec3(center + offset.xx, shadowCoord.z));
    float tl = shadow2D(shadowMap, vec3(center + offset.xy, shadowCoord.z));
    float br = shadow2D(shadowMap, vec3(center + offset.yx, shadowCoord.z));
    float tr = shadow2D(shadowMap, vec3(center + offset.yy, shadowCoord.z));

    float l = mix(bl, tl, f.y);
    float r = mix(br, tr, f.y);
	return mix(l, r, f.x);
#else
	return shadow2D(shadowMap, shadowCoord).x;
#endif
}

vec3 getShadowColor(in sampler2DShadow shadowMap, in sampler2DShadow shadowMapOpaque, in sampler2D shadowColorTex, in vec3 shadowCoord) {
	float shading = sampleShadowMap(shadowMap, shadowCoord);
#ifdef COLORED_SHADOWS
	float opaqueShading = sampleShadowMap(shadowMapOpaque, shadowCoord);
	vec3 shadowColor = texture2D(shadowColorTex, shadowCoord.xy).xyz;
	return shadowColor * (opaqueShading - shading) + shading;
#else
	return vec3(shading);
#endif
}

float computeShadowFade(in float cosTheta) { // Hide disconnected shadows at noon
	return 1.0 - min(pow(1.05 - abs(cosTheta), 32.0), 1.0);
}

#endif // SHADOW_GLSL