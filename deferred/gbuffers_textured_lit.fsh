#include "include/common.glsl"
#include "include/atmospherics.glsl"
#include "include/material.glsl"
#include "include/shadow.glsl"
#include "include/pbr.glsl"

varying vec3 v_Entity;
varying vec4 v_Color;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;
varying vec3 v_Normal;
varying mat3 v_TBN;
varying vec3 v_FragPos;
varying vec3 v_ShadowCoord;

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2DShadow shadowtex0; // All entities
uniform sampler2DShadow shadowtex1; // Opaque entities only
uniform sampler2D shadowcolor0;

void main() {
	// Extract data from textures
	vec4 albedoAlpha = texture2D(texture, v_TexCoord) * v_Color;
	float alpha = albedoAlpha.w;
	vec3 albedo = gammaToLinear(albedoAlpha.xyz);
	albedo = remapEntityAlbedo(albedo, v_Entity);

	vec4 RMET = vec4(texture2D(specular, v_TexCoord).xyz, 1.0 - alpha); // Perceptual smoothness; Metallic; Emission; Transmittance
	RMET.x = pow(1.0 - RMET.x, 2.0); // Perceptual smoothness -> Linear roughness
	RMET = remapEntityRMET(RMET, v_Entity);
	float roughness     = RMET.x;
	float metallic      = RMET.y;
	float emission      = RMET.z;
	float transmittance = RMET.w;

	// Calculate useful values
	vec3 N = normalize((texture2D(normals, v_TexCoord).xyz * 2.0 - 1.0) * v_TBN);

	// Fill out the G-Buffer
	MaterialMask mask = genEntityMask(v_Entity);

	if(!mask.isTranslucent) {
		vec3 emissionFactor = albedo * emission;
		emissionFactor += entityColor.xyz * entityColor.w * entityColor.w * entityColor.w; // Cubed entity coloring factor looks way better

		vec3 emissionEnergy = EMISSION_ILLUMINANCE * emissionFactor;

		// HDR
		gl_FragData[0].xyz = emissionEnergy; // Ambient specular is computed in composite
		gl_FragData[0].w   = alpha;
	} else {
		// HDR
		gl_FragData[0].xyz = vec3(0.0);
		gl_FragData[0].w   = 0.11; // The whole fragment is discarded if gl_FragData[0].w <= 0.1
	}

	// Normal XY; Material ID
	gl_FragData[1].xy  = encodeNormal(N);
	gl_FragData[1].z   = encodeMask(mask);
	gl_FragData[1].w   = 1.0;
	// Albedo
	gl_FragData[2].xyz = albedo;
	gl_FragData[2].w   = 1.0;
	// Roughness; Metallic; Transmittance
	gl_FragData[3].xyz = vec3(roughness, metallic, transmittance);
	gl_FragData[3].w   = 1.0;
	// Ambient light
	gl_FragData[4].xy  = v_AmbientLight;
	gl_FragData[4].w   = 1.0;
}