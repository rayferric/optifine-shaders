#version 120
#include "include/common.glsl"
#include "include/material.glsl"

varying vec3 v_Entity; // Unused (residues after gbuffers_textured_lit)
varying vec4 v_Color;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;
varying vec3 v_Normal; // Unused
varying mat3 v_TBN;
varying vec3 v_FragPos; // Unused
varying vec3 v_ShadowCoord; // Unused

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;

void main() {
	// mc_Entity attribute doesn't carry proper ID for hand items (and that's the reason this program exists)
	// This mapping will mostly unnoticeably fail when holding translucents in both hands
	vec3 entity = vec3(heldItemId, 0.0, 0.0);
	if(!isTranslucent(entity))entity.x = heldItemId2;

	vec4 albedoAlpha = texture2D(texture, v_TexCoord) * v_Color;
	float alpha = albedoAlpha.w;
	vec3 albedo = gammaToLinear(albedoAlpha.xyz);
	albedo = remapEntityAlbedo(albedo, entity);

	vec4 RMET = vec4(texture2D(specular, v_TexCoord).xyz, 1.0 - alpha); // Perceptual smoothness; Metallic; Emission; Transmittance
	RMET.x = pow(1.0 - RMET.x, 2.0); // Perceptual smoothness -> Linear roughness
	RMET = remapEntityRMET(RMET, entity);
	float roughness     = RMET.x;
	float metallic      = RMET.y;
	// float emission      = RMET.z;
	float transmittance = RMET.w;

	vec3 N = normalize((texture2D(normals, v_TexCoord).xyz * 2.0 - 1.0) * v_TBN);
	vec3 L = normalize(shadowLightPosition);

	MaterialMask mask = genLitMask(entity);
	mask.isHand = true;

	// HDR
	gl_FragData[0].xyz = vec3(0.0);
	gl_FragData[0].w   = 0.11; // The whole fragment is discarded if gl_FragData[0].w <= 0.1
	// Normal XY; Material ID
	gl_FragData[1].xy  = encodeNormal(N);
	gl_FragData[1].z   = encodeMask(mask);
	gl_FragData[1].w   = 1.0;
	// Albedo RG; (Albedo B + Roughness); (Metallic + Transmittance)
	vec3 albedoGamma = linearToGamma(albedo);
	gl_FragData[2].x   = encodeVec2(albedoGamma.xy);
	gl_FragData[2].y   = encodeVec2(vec2(albedoGamma.z, roughness));
	gl_FragData[2].z   = encodeVec2(vec2(metallic, transmittance));
	gl_FragData[2].w   = 1.0;
	// Ambient light
	gl_FragData[3].xy  = v_AmbientLight;
	gl_FragData[3].w   = 1.0;
}

/* DRAWBUFFERS:0123 */