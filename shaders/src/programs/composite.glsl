varying vec2 v_TexCoord;

///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

void main() {
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/src/modules/gbuffer.glsl"
#include "/src/modules/luminance.glsl"
#include "/src/modules/pbr.glsl"
#include "/src/modules/screen_to_view.glsl"
#include "/src/modules/shadow.glsl"
#include "/src/modules/sky.glsl"
#include "/src/modules/ssao.glsl"
#include "/src/modules/ssr.glsl"

// This deferred pass generates partial HDR lighting for non-translucent
// materials.
// Indirect specular irradiance is omitted and will be added in subsequent
// passes.

void main() {
	float depth = texture(depthtex0, v_TexCoord).x;

	vec3 viewFragPos  = screenToView(v_TexCoord, depth);
	vec3 localFragPos = (gbufferModelViewInverse * vec4(viewFragPos, 1.0)).xyz;

	vec3 viewEyeDir  = -normalize(viewFragPos);
	vec3 worldEyeDir = normalize(mat3(gbufferModelViewInverse) * viewEyeDir);

	vec3 worldSunDir =
	    normalize(mat3(gbufferModelViewInverse) * normalize(sunPosition));
	vec3 worldMoonDir =
	    normalize(mat3(gbufferModelViewInverse) * normalize(moonPosition));
	vec3 viewLightDir = normalize(shadowLightPosition);

	GBuffer gbuffer = sampleGBuffer(v_TexCoord);

	vec3 skyIndirect = skyIndirect(worldSunDir, worldMoonDir);
	vec3 skyLight    = gbuffer.skyLight * skyIndirect;
	vec3 blockLight  = gbuffer.blockLight * BLOCK_LIGHT_LUMINANCE;
	vec3 sunLight    = skyDirectSun(worldSunDir);

	// medium thickness
	float thickness = 0.0;
	if (gbuffer.layer != GBUFFER_LAYER_OPAQUE) {
		vec3 viewOpaqueFragPos = screenToView(v_TexCoord, depthtex1);
		thickness = length(viewOpaqueFragPos) - length(viewFragPos);
	}
	if (isEyeInWater == 1) {
		thickness = length(viewFragPos);
	}

	if (gbuffer.layer == GBUFFER_LAYER_SKY) {
		outColor0.xyz = texture(colortex5, v_TexCoord).xyz;
	}

	if (gbuffer.layer == GBUFFER_LAYER_OPAQUE) {
		vec3 hdr = texture(colortex5, v_TexCoord).xyz;

		// if (gbuffer.roughness < MAX_SSR_ROUGHNESS) {
		IndirectContribution indirect = indirectContribution(
		    gbuffer.albedo,
		    gbuffer.roughness,
		    gbuffer.metallic,
		    0.0, // transmissive
		    gbuffer.normal,
		    viewEyeDir
		);

		// specular with SSR
		SSR ssr = computeSsReflection(
		    colortex5, depthtex2, viewFragPos, gbuffer.normal, gbuffer.roughness
		);
		vec3  worldDir  = normalize(mat3(gbufferModelViewInverse) * ssr.dir);
		vec3  fallback  = sky(worldDir, worldSunDir, worldMoonDir);
		float skyFactor = smoothstep(-0.4, 0.4, worldDir.y);
		fallback = mix(vec3(luminance(skyIndirect * 0.1)), fallback, skyFactor);
		fallback             *= smoothstep(0.0, 0.8, gbuffer.skyLight);
		fallback             *= 1.0 - float(isEyeInWater == 1);
		vec3 reflectionLight  = mix(fallback, ssr.color, ssr.opacity);
		if (isEyeInWater == 1) {
			// extinction on the path from mirror surface to the eye
			reflectionLight *= exp(-thickness * WATER_ABSORPTION);
		}
		hdr += indirect.specular * reflectionLight;

		vec3 emissionLight  = gbuffer.albedo * EMISSIVE_LUMINANCE;
		hdr                += gbuffer.emissive * emissionLight;

		outColor0.xyz = hdr;
	}

	if (gbuffer.layer == GBUFFER_LAYER_TRANSLUCENT ||
	    gbuffer.layer == GBUFFER_LAYER_WATER ||
	    gbuffer.layer == GBUFFER_LAYER_ICE ||
	    gbuffer.layer == GBUFFER_LAYER_HONEY) {
		IndirectContribution indirect = indirectContribution(
		    gbuffer.albedo,
		    gbuffer.roughness,
		    0.0, // metallic
		    gbuffer.transmissive,
		    gbuffer.normal,
		    viewEyeDir
		);

		// basic diffuse
		vec3 hdr = indirect.diffuse * (skyLight + blockLight);

		// specular with SSR
		SSR ssr = computeSsReflection(
		    colortex5, depthtex2, viewFragPos, gbuffer.normal, gbuffer.roughness
		);
		vec3  worldDir  = normalize(mat3(gbufferModelViewInverse) * ssr.dir);
		vec3  fallback  = sky(worldDir, worldSunDir, worldMoonDir);
		float skyFactor = smoothstep(-0.4, 0.0, worldDir.y);
		fallback = mix(vec3(luminance(skyIndirect * 0.1)), fallback, skyFactor);
		fallback             *= smoothstep(0.0, 0.8, gbuffer.skyLight);
		fallback             *= 1.0 - float(isEyeInWater == 1);
		vec3 reflectionLight  = mix(fallback, ssr.color, ssr.opacity);
		if (isEyeInWater == 1) {
			// extinction on the path from mirror surface to the eye
			reflectionLight *= exp(-thickness * WATER_ABSORPTION);
		}
		hdr += indirect.specular * reflectionLight;

		// transmissive
		vec3 transmissionLight = texture(colortex5, v_TexCoord).xyz;
		if (gbuffer.layer == GBUFFER_LAYER_WATER) {
			transmissionLight *= exp(-thickness * WATER_ABSORPTION);
		} else if (gbuffer.layer == GBUFFER_LAYER_ICE) {
			transmissionLight *= exp(-thickness * ICE_ABSORPTION);
		} else if (gbuffer.layer == GBUFFER_LAYER_HONEY) {
			// limit honey thickness to 5 blocks
			transmissionLight *= exp(-min(thickness, 5.0) * HONEY_ABSORPTION);
		}
		hdr += indirect.transmitted * transmissionLight;

		vec3 direct = directContribution(
		    gbuffer.albedo,
		    gbuffer.roughness,
		    0.0, // metallic
		    gbuffer.transmissive,
		    gbuffer.normal,
		    viewEyeDir,
		    viewLightDir,
		    false
		);
		direct *= softShadow(localFragPos, gbuffer.normal, viewLightDir, false);
		hdr    += direct * sunLight;

		outColor0.xyz = hdr;
	}

	if (gbuffer.layer == GBUFFER_LAYER_BASIC) {
		// Basic entities do not have proper normals,
		// so they are lit using a custom model.

		// simplified non-PBR shading model
		vec3 indirect = gbuffer.albedo;
		vec3 hdr      = indirect * (skyLight + blockLight);
		vec3 direct   = gbuffer.albedo / PI;
		direct *= softShadow(localFragPos, vec3(0.0), viewLightDir, true);
		// (fakeSss = true disables normal-based bias)
		hdr += direct * sunLight;

		vec3 emissionLight  = gbuffer.albedo * EMISSIVE_LUMINANCE;
		hdr                += gbuffer.emissive * emissionLight;

		outColor0.xyz = hdr;
	}

	// outColor0.xyz =
	//     skyFog(outColor0.xyz, localFragPos, worldSunDir, worldMoonDir);

	outColor0.w = 1.0;
}

/* RENDERTARGETS: 5 */

#endif // FSH
