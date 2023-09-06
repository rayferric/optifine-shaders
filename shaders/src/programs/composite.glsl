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

	vec3 skyLight   = gbuffer.skyLight * skyIndirect(worldSunDir, worldMoonDir);
	vec3 blockLight = gbuffer.blockLight * BLOCK_LIGHT_ENERGY;
	vec3 sunLight   = skyDirectSun(worldSunDir);

	outColor0.xyz = vec3(1.0);

	// Sky
	if (gbuffer.layer == GBUFFER_LAYER_SKY) {
		// outColor0.xyz = texture(colortex5, v_TexCoord).xyz;
		outColor0.xyz = vec3(0.0, 1.0, 1.0);
	}

	if (gbuffer.layer == GBUFFER_LAYER_OPAQUE) {
		vec3 hdr = texture(colortex5, v_TexCoord).xyz;

		if (gbuffer.roughness < 0.5) {
			IndirectContribution indirect = indirectContribution(
			    gbuffer.albedo,
			    gbuffer.roughness,
			    gbuffer.metallic,
			    0.0, // transmissive
			    gbuffer.normal,
			    viewEyeDir
			);

			// specular with SSR
			vec3 viewIncoming = importanceGgx(
			    hash(frameTimeCounter * viewFragPos).xy,
			    gbuffer.normal,
			    -normalize(viewFragPos),
			    gbuffer.roughness
			);
			if (dot(viewIncoming, gbuffer.normal) < 0.0) {
				viewIncoming = reflect(viewIncoming, gbuffer.normal);
			}

			vec3 worldIncoming =
			    normalize(mat3(gbufferModelViewInverse) * viewIncoming);
			vec3 fallback = sky(worldIncoming, worldSunDir, worldMoonDir);
			vec4 ssr      = computeSsReflection(
                colortex5, depthtex2, viewFragPos, viewIncoming
            );
			vec3 reflectionLight  = mix(fallback, ssr.xyz, ssr.w);
			hdr                  += indirect.specular * reflectionLight;
		}

		outColor0.xyz = vec3(0.0, 0.0, 1.0);
	}

	if (gbuffer.layer == GBUFFER_LAYER_TRANSLUCENT) {
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
		vec3 viewIncoming = importanceGgx(
		    hash(frameTimeCounter * viewFragPos).xy,
		    gbuffer.normal,
		    -normalize(viewFragPos),
		    gbuffer.roughness
		);
		vec3 worldIncoming =
		    normalize(mat3(gbufferModelViewInverse) * viewIncoming);
		vec3 fallback = sky(worldIncoming, worldSunDir, worldMoonDir);
		vec4 ssr      = computeSsReflection(
            colortex5, depthtex2, viewFragPos, viewIncoming
        );
		vec3 reflectionLight  = mix(fallback, ssr.xyz, ssr.w);
		hdr                  += indirect.specular * reflectionLight;

		// transmissive
		vec3 transmissionLight  = texture(colortex5, v_TexCoord).xyz;
		hdr                    += indirect.transmitted * transmissionLight;

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

		outColor0.xyz = vec3(0.0, 1.0, 0.0);
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

		outColor0.xyz = vec3(1.0, 0.0, 0.0);
	}

	outColor0.w = 1.0;
}

/* RENDERTARGETS: 5 */

#endif // FSH
