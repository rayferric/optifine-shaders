#version 120

#include "include/common.glsl"
#include "include/encoding.glsl"
#include "include/material.glsl"
#include "include/pbr.glsl"
#include "include/shadow.glsl"

varying vec4 v_Color;
varying vec3 v_Entity;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;
varying vec3 v_Normal;
varying mat3 v_TBN;
varying vec3 v_FragPos;
varying vec3 v_ShadowCoord;

uniform sampler2D       texture;
uniform sampler2D       lightmap;
uniform sampler2D       normals;
uniform sampler2D       specular;
uniform sampler2DShadow shadowtex0; // All entities
uniform sampler2DShadow shadowtex1; // Opaque entities only
uniform sampler2D       shadowcolor0;

void main() {
	vec4 albedoOpacity = texture2D(texture, v_TexCoord) * v_Color;
	albedoOpacity.xyz = gammaToLinear(albedoOpacity.xyz);
	albedoOpacity = remapBlockAlbedoOpacity(albedoOpacity, v_Entity);
	vec3 albedo = albedoOpacity.xyz;
	float opacity = albedoOpacity.w;

	// Perceptual Smoothness; Metallic; Emission
	vec3 RME = texture2D(specular, v_TexCoord).xyz;
	// Convert perceptual smoothness to roughness
	RME.x = pow(1.0 - RME.x, 2.0);
	RME = remapBlockRME(RME, v_Entity);
	float roughness = RME.x;
	float metallic  = RME.y;
	float emission  = RME.z;

	vec3 N = normalize((texture2D(normals, v_TexCoord).xyz * 2.0 - 1.0) * v_TBN);
	vec3 V = normalize(-v_FragPos);
	vec3 L = normalize(shadowLightPosition);
	vec3 H = normalize(V + L);

	MaterialMask mask = makeLitMask(v_Entity);

	if (mask.isOpaque) {
		float NdotV = max(dot(N, V), 0.0);
		float NdotL = max(dot(N, L), 0.0);
		float NdotH = max(dot(N, H), 0.0);
		float HdotV = max(dot(H, V), 0.0);

		vec3 shadowFactor = getShadowColor(shadowtex0, shadowtex1, shadowcolor0, v_ShadowCoord) * NdotL;
		vec3 shadowContribution = cookTorrance(albedo, roughness, metallic, NdotV, NdotL, NdotH, HdotV);
		vec3 shadowEnergy = (SUN_ENERGY * shadowFactor) * shadowContribution;

		// Ambient specular energy is computed in composite
		vec3 specular = mix(vec3(0.04), albedo, metallic);
		specular = fresnelSchlick(NdotV, specular, roughness);
		vec3 ambientDiffuseContribution = (vec3(1.0) - specular) * (1.0 - metallic) * albedo;
		vec3 skyDiffuseEnergy   = (SUN_ENERGY * 0.125 * v_AmbientLight.x) * ambientDiffuseContribution;
		vec3 torchDiffuseEnergy = (TORCH_ENERGY * v_AmbientLight.y) * ambientDiffuseContribution;

		// Remapped alpha looks way better
		vec3 emissionFactor = albedo * emission;
		emissionFactor += entityColor.xyz * (entityColor.w * entityColor.w * entityColor.w);
		vec3 emissionEnergy = EMISSION_ILLUMINANCE * emissionFactor;

		// colortex0: HDR
		gl_FragData[0].xyz = shadowEnergy + skyDiffuseEnergy + torchDiffuseEnergy + emissionEnergy;
		gl_FragData[0].w   = opacity;
	} else {
		// colortex0: HDR
		gl_FragData[0].xyz = vec3(0.0);
		gl_FragData[0].w   = 0.11;
		// Setting alpha to 0 would discard the fragment
	}

	// colortex1: Packed Normal
	gl_FragData[1].xy = encodeNormal(N);
	gl_FragData[1].w  = 1.0;

	// colortex2: Packed sRGB Albedo RG; Packed (sRGB Albedo B + Opacity); Packed (Roughness + Metallic)
	vec3 albedoGamma = linearToGamma(albedo);
	gl_FragData[2].x = encodeVec2(albedoGamma.xy);
	gl_FragData[2].y = encodeVec2(vec2(albedoGamma.z, opacity));
	gl_FragData[2].z = encodeVec2(vec2(roughness, metallic));
	gl_FragData[2].w = 1.0;

	// colortex3: Gamma-Space Sky Light; Gamma-Space Torch Light; Material ID
	gl_FragData[3].xy = linearToGamma(v_AmbientLight);
	gl_FragData[3].z  = encodeMask(mask);
	gl_FragData[3].w  = 1.0;
}

/* DRAWBUFFERS:0123 */
