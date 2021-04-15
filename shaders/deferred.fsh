#version 120

#include "include/common.glsl"

#include "include/material.glsl"
#include "include/pbr.glsl"
#include "include/shadow.glsl"
#include "include/ssao.glsl"

varying vec2 v_TexCoord;

uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;  // All entities
uniform sampler2D depthtex1;  // Opaque entities only
uniform sampler2D shadowtex0; // All entities
uniform sampler2D shadowtex1; // Opaque entities only
uniform sampler2D shadowcolor0;

void main() {
	vec3 N = decodeNormal(texture2D(colortex2, v_TexCoord).xy);

	vec3 albedoOpacityRM = texture2D(colortex3, v_TexCoord).xyz;
	vec2 RG = decodeVec2(albedoOpacityRM.x);
	vec2 BO = decodeVec2(albedoOpacityRM.y);
	vec2 RM = decodeVec2(albedoOpacityRM.z);
	vec3 albedo     = gammaToLinear(vec3(RG, BO.x));
	float opacity   = BO.y;
	float roughness = RM.x;
	float metallic  = RM.y;

	vec3 ambientLightMask = texture2D(colortex4, v_TexCoord).xyz;
	vec2 ambientLight = ambientLightMask.xy;
	MaterialMask mask = decodeMask(ambientLightMask.z);

	vec3 fragPos       = getFragPos(v_TexCoord, depthtex0);
	vec3 fragPosOpaque = getFragPos(v_TexCoord, depthtex1);

	vec3 V = normalize(-fragPos);
	vec3 L = normalize(shadowLightPosition);
	vec3 H = normalize(V + L);

	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float NdotH = max(dot(N, H), 0.0);
	float HdotV = max(dot(H, V), 0.0);

	vec3 shadowColor = getSoftShadow(shadowtex0, shadowtex1, shadowcolor0, fragPos, N, L) * NdotL;
	shadowColor *= getContactShadow(depthtex1, fragPos, L);
	vec3 shadowContribution = cookTorrance(albedo, roughness, metallic, NdotV, NdotL, NdotH, HdotV);
	vec3 shadowEnergy = (SUN_ENERGY * shadowColor) * shadowContribution;

	// Ambient specular energy is computed in composite
	vec3 specular = mix(vec3(0.04), albedo, metallic);
	specular = fresnelSchlick(NdotV, specular, roughness);
	vec3 ambientDiffuseContribution = (vec3(1.0) - specular) * (1.0 - metallic) * albedo;
	vec3 skyDiffuseEnergy   = (SUN_ENERGY * 0.125 * ambientLight.x) * ambientDiffuseContribution;
	vec3 torchDiffuseEnergy = (TORCH_ENERGY * ambientLight.y) * ambientDiffuseContribution;

	skyDiffuseEnergy *= computeSSAO(fragPos, N, depthtex0);

	// colortex1: HDR Buffer
	gl_FragData[0].xyz = shadowEnergy + skyDiffuseEnergy + torchDiffuseEnergy;
}

/* DRAWBUFFERS:1 */
