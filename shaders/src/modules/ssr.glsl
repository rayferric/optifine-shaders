#ifndef SSR_GLSL
#define SSR_GLSL

#include "/src/modules/hash.glsl"
#include "/src/modules/pbr.glsl"
#include "/src/modules/raymarch.glsl"

#define SSR_MAX_STEPS    16
#define SSR_REFINE_STEPS 8
#define SSR_MAX_DISTANCE 200.0 // Distance in pixels across screen
#define SSR_BIAS                                                               \
	0.05 // Offset ray origin to avoid self-intersection at grazing angles
#define SSR_NEAR_TOLERANCE 1.0
#define SSR_FAR_TOLERANCE  1.0

struct SSR {
	vec3  color;
	float opacity;
	vec3  dir;
};

/**
 * @brief Calculates reflection color at given fragment position.
 *
 * @param hdrTex     HDR texture that contains already calculated screen
 * luminance
 * @param depthTex     depth buffer to be sampled
 * @param fragPos      fragment's position in view space
 * @param viewIncoming incoming light direction in view space (reflected view
 * ray)
 *
 * @return    reflection color + alpha
 */
SSR computeSsReflection(
    in sampler2D hdrTex,
    in sampler2D depthTex,
    in vec3      viewFragPos,
    in vec3      viewNormal,
    in float     roughness
) {
	vec3 viewIncoming = importanceGgx(
	    hash(frameTimeCounter * viewFragPos).xy,
	    viewNormal,
	    -normalize(viewFragPos),
	    roughness
	);

	// Check if the specular lobe intersects the face.
	if (dot(viewIncoming, viewNormal) < 0.0) {
		viewIncoming = reflect(viewIncoming, viewNormal);
	}

	RayMarchResult result = rayMarch(
	    depthTex,
	    viewFragPos,
	    viewIncoming,
	    SSR_MAX_DISTANCE,
	    SSR_BIAS,
	    SSR_MAX_STEPS,
	    SSR_REFINE_STEPS,
	    SSR_NEAR_TOLERANCE,
	    SSR_FAR_TOLERANCE
	);

	vec2 uv     = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
	vec2 dist   = abs(result.coord * 2.0 - 1.0);
	uv          = abs(uv * 2.0 - 1.0);
	dist.x      = smoothstep(1.0 - 1.5 * (1.0 - uv.x), 1.0, dist.x);
	float bound = max(dist.y, dist.x);
	float fade  = smoothstep(0.0, 0.2, 1.0 - bound);
	// fade        = 1.0;

	SSR ssr;
	if (result.hasHit) {
		ssr.color   = texture(hdrTex, result.coord).xyz;
		ssr.opacity = fade;
	} else {
		ssr.color   = vec3(0.0);
		ssr.opacity = 0.0;
	}
	ssr.dir = viewIncoming;

	// vec3 worldIncoming =
	//     normalize(mat3(gbufferModelViewInverse) * viewIncoming);
	// vec3  fallback     = sky(worldIncoming, worldSunDir, worldMoonDir);
	// float groundFactor = 1.0 - smoothstep(-0.4, 0.4, worldIncoming.y);
	// fallback  = mix(fallback, vec3(luminance(skyIndirect * 0.1)),
	// groundFactor); fallback *= smoothstep(0.0, 0.8, gbuffer.skyLight);
	// fallback *= 1.0 - float(isEyeInWater == 1);
	// vec3 reflectionLight = mix(fallback, ssr.color, ssr.opacity);
	// if (isEyeInWater == 1) {
	// 	// extinction on the path from mirror surface to the eye
	// 	reflectionLight *= exp(-thickness * WATER_ABSORPTION);
	// }

	return ssr;
}

/**
 * @brief Calculates refraction color at given fragment position.
 *
 * @param hdrTex     HDR texture that contains already calculated screen
 * energy
 * @param depthTex     depth buffer to be sampled
 * @param fragPos      fragment's position in view space
 * @param normal       fragment's normal in view space
 * @param ior          fragment's index of refraction
 * @param roughness    fragment's roughness value
 * @param skyFactor    on-fallback sky color factor
 *
 * @return    reflection color
 */
// vec3 computeSSRefraction(in sampler2D hdrTex, in sampler2D depthTex, in
// vec3 fragPos, in vec3 normal, in float ior, in float roughness, in float
// skyFactor) { 	vec3 viewDir = normalize(fragPos); 	vec3 dir =
// refract(viewDir, normal, ior); 	if (length(dir) == 0.0)dir =
// reflect(viewDir, normal); 	vec3 jitt = normalize(mix(dir,
// hashDirInHemisphere(fragPos * frameTimeCounter, normal), roughness)); 	vec3
// coord = rayMarch(depthTex, fragPos, jitt);

// 	vec2 dCoord = smoothstep(0.75, 1.0, abs(coord.xy * 2.0 - 1.0));
// 	float screenEdgeFactor = clamp(1.0 - (dCoord.x + dCoord.y), 0.0, 1.0);

// 	vec3 fallback = getSkyEnergy(dir) * skyFactor;
// 	return mix(fallback, texture(hdrTex, coord.xy).xyz, coord.z);
// }
// vec3 computeSSRefraction(in sampler2D hdrTex, in sampler2D depthTex, in
// vec3 viewFragPos, in vec3 normal, in float roughness, in float ior) { 	vec3
// viewDir = normalize(viewFragPos); 	vec3 dir = refract(viewDir, normal,
// ior); if (length(dir) == 0.0) 		dir = reflect(viewDir, normal); 	vec3
// jitt = normalize(mix(dir, hashToHemisphereDir(viewFragPos * frameTimeCounter,
// normal), roughness));

// 	RayMarchResult result = rayMarch(
// 			depthTex, viewFragPos, jitt,
// 			SSR_MAX_DISTANCE, SSR_BIAS,
// 			SSR_MAX_STEPS, SSR_TOLERANCE);

// 	vec3 color = vec3(0.8, 0.9, 1.0) * SUN_ILLUMINANCE * 0.125;
// 	if (result.hasHit)
// 		color = texture(hdrTex, result.coord).xyz;
// 	return color;
// }

#endif // SSR_GLSL