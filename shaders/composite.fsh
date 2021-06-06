#version 120

#include "include/common.glsl"

#include "include/material.glsl"
#include "include/pbr.glsl"
#include "include/shadow.glsl"
#include "include/ssao.glsl"

varying vec2 v_TexCoord;

uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;  // All entities
uniform sampler2D depthtex1;  // Opaque entities only
uniform sampler2D shadowtex0; // All entities
uniform sampler2D shadowtex1; // Opaque entities only
uniform sampler2D shadowcolor0;

void main() {
	vec3 normal = decodeNormal(texture2D(colortex2, v_TexCoord).xy);

	vec3 albedoOpacityRm = texture2D(colortex3, v_TexCoord).xyz;
	vec2 rg = decodeVec2(albedoOpacityRm.x);
	vec2 bo = decodeVec2(albedoOpacityRm.y);
	vec2 rm = decodeVec2(albedoOpacityRm.z);
	vec3 albedo     = gammaToLinear(vec3(rg, bo.x));
	float opacity   = bo.y;
	float roughness = rm.x;
	float metallic  = rm.y;

	vec3 ambientLightMask = texture2D(colortex4, v_TexCoord).xyz;
	vec2 ambientLight = ambientLightMask.xy;
	MaterialMask mask = decodeMask(ambientLightMask.z);

	vec3 viewPos = screenToView(v_TexCoord, depthtex0);

	vec3 lightDir = normalize(shadowLightPosition);
	vec3 viewDir = normalize(-viewPos);
	vec3 refractionDir = refract(viewDir, normal, 1.0);

	vec3 hdr;

	if (!mask.isOpaque) {
		float cosNv = max(dot(normal, viewDir), 0.0);

		vec3 shadowColor = softShadow(viewPos, normal, lightDir);
		shadowColor *= contactShadow(viewPos, L);
		vec3 shadowContribution = cookTorrance(albedo, roughness, metallic, normal, lightDir, viewDir);
		vec3 shadowEnergy = (SUN_ENERGY * shadowColor) * shadowContribution;

		// Ambient specular energy is computed in composite
		vec3 specular = mix(vec3(0.04), albedo, metallic);
		specular = fresnelSchlick(cosNv, specular, roughness);
		vec3 ambientDiffuseContribution = (vec3(1.0) - specular) * (1.0 - metallic) * albedo;
		vec3 skyDiffuseEnergy   = (SUN_ENERGY * 0.125 * ambientLight.x) * ambientDiffuseContribution;
		vec3 torchDiffuseEnergy = (TORCH_ENERGY * ambientLight.y) * ambientDiffuseContribution;

		hdr = shadowEnergy + skyDiffuseEnergy + torchDiffuseEnergy;
		hdr = mix(texture2D(colortex1, v_TexCoord).xyz * albedo, hdr, opacity);
	} else {
		hdr = texture2D(colortex1, v_TexCoord).xyz;
	}

	// colortex1: HDR Buffer
	gl_FragData[0].xyz = hdr;
	gl_FragData[0].w   = 1.0;
}

/* DRAWBUFFERS:1 */
