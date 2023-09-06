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

#include "/src/modules/clouds.glsl"
#include "/src/modules/gbuffer.glsl"
#include "/src/modules/pbr.glsl"
#include "/src/modules/screen_to_view.glsl"
#include "/src/modules/shadow.glsl"
#include "/src/modules/sky.glsl"
#include "/src/modules/ssao.glsl"

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

	vec3 skyLight   = gbuffer.skyLight * skyIndirect(worldSunDir, worldMoonDir);
	vec3 blockLight = gbuffer.blockLight * BLOCK_LIGHT_LUMINANCE;
	vec3 sunLight   = skyDirectSun(worldSunDir);

	if (gbuffer.layer == GBUFFER_LAYER_SKY) {
		outColor0.xyz = sky(-worldEyeDir, worldSunDir, worldMoonDir);
	}

	if (gbuffer.layer == GBUFFER_LAYER_OPAQUE) {
		IndirectContribution indirect = indirectContribution(
		    gbuffer.albedo,
		    gbuffer.roughness,
		    gbuffer.metallic,
		    0.0, // transmissive
		    gbuffer.normal,
		    viewEyeDir
		);
		vec3 hdr  = indirect.diffuse * (skyLight + blockLight);
		hdr      *= computeSsao(viewFragPos, gbuffer.normal, depthtex0);
		// (indirect specular will be added once SSR is available)

		vec3 direct = directContribution(
		    gbuffer.albedo,
		    gbuffer.roughness,
		    gbuffer.metallic,
		    0.0, // transmissive
		    gbuffer.normal,
		    viewEyeDir,
		    viewLightDir,
		    false
		);
		direct *= softShadow(localFragPos, gbuffer.normal, viewLightDir, false);
		hdr    += direct * sunLight;

		outColor0.xyz = hdr;
	}

	// if (gbuffer.layer == GBUFFER_LAYER_BASIC) {
	// 	// Billboard entities do not have proper normals,
	// 	// so they are lit using a custom model.

	// 	// simplified non-PBR shading model
	// 	vec3 indirect = gbuffer.albedo;
	// 	vec3 hdr      = indirect * (skyLight + blockLight);
	// 	vec3 direct   = gbuffer.albedo / PI;
	// 	direct *= softShadow(localFragPos, vec3(0.0), viewLightDir, true);
	// 	// (fakeSss = true disables normal-based bias)
	// 	hdr += direct * sunLight;

	// 	outColor0.xyz = hdr;
	// }

	outColor0.w = 1.0;
}

/* RENDERTARGETS: 5 */

#endif // FSH
