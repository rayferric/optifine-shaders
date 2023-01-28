#version 120
#include "include/common.glsl"
#include "include/material.glsl"
#include "include/shadow.glsl"
#include "include/atmospherics.glsl"
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
	// Read data from textures
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
	vec3 V = normalize(-v_FragPos);
	vec3 L = normalize(shadowLightPosition);
	vec3 H = normalize(V + L);

	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float NdotH = max(dot(N, H), 0.0);
	float HdotV = max(dot(H, V), 0.0);

	vec3 F0 = mix(vec3(0.04), albedo, metallic);
	vec3 F  = fresnelSchlickRoughness(NdotV, F0, roughness);

	// Fill out the G-Buffer
	MaterialMask mask = genLitMask(v_Entity);

	if(!mask.isTranslucent) {
		vec3 shadowFactor = getShadowColor(shadowtex0, shadowtex1, shadowcolor0, v_ShadowCoord);
		shadowFactor *= getShadowSwitchFactor(); // Hide shading while switching light sources
		if(isPlant(v_Entity))shadowFactor *= max(dot(normalize(upPosition), L), 0.0); // Fake vegetation lighting
		else shadowFactor *= NdotL * getShadowNoonFade(dot(v_Normal, L)); // Hide disconnected shadows at noon
		vec3 emissionFactor = albedo * emission;
		emissionFactor += entityColor.xyz * entityColor.w * entityColor.w * entityColor.w; // Cubed entity coloring factor looks way better

		vec3 kD = (vec3(1.0) - F) * (1.0 - metallic);

		vec3 shadowBRDF = cookTorrance(albedo, roughness, metallic, NdotV, NdotL, NdotH, HdotV);
		vec3 ambientDiffuseBRDF = kD * albedo;

		vec3 shadowEnergy   = (getShadowIlluminance() * shadowFactor) * shadowBRDF;
		vec3 skyEnergy      = (avgSkyRadiance() * v_AmbientLight.y) * ambientDiffuseBRDF;
		vec3 torchEnergy    = (TORCH_COLOR * v_AmbientLight.x) * ambientDiffuseBRDF;
		vec3 emissionEnergy = EMISSION_ILLUMINANCE * emissionFactor;

		// HDR
		gl_FragData[0].xyz = shadowEnergy + skyEnergy + torchEnergy + emissionEnergy; // Ambient specular is computed in composite
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