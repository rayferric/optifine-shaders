#include "include/common.glsl"
#include "include/material.glsl"
#include "include/shadow.glsl"
#include "include/pbr.glsl"
#include "include/ssr.glsl"

varying vec2 v_TexCoord;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D depthtex0; // All entities
uniform sampler2D depthtex1; // Opaque entities only
uniform sampler2DShadow shadowtex0; // All entities
uniform sampler2DShadow shadowtex1; // Opaque entities only
uniform sampler2D shadowcolor0;

void main() {
	// Extract G-Buffer data
	vec3 albedo = texture2D(colortex2, v_TexCoord).xyz;

	vec3 RMT = texture2D(colortex3, v_TexCoord).xyz;
	float roughness = RMT.x;
	float metallic = RMT.y;
	float transmittance = RMT.z;

	vec2 ambientLight = texture2D(colortex4, v_TexCoord).xy;

	vec3 NNM = texture2D(colortex1, v_TexCoord).xyz;
	vec3 N = decodeNormal(NNM.xy);
	MaterialMask mask = decodeMask(NNM.z);
	
	if(!mask.isLit) {
		gl_FragData[0].xyz = texture2D(colortex0, v_TexCoord).xyz;
		return;
	}

	vec3 fragPos      = getFragPos(depthtex0, v_TexCoord);
	vec3 fragPosSolid = getFragPos(depthtex1, v_TexCoord);
	vec3 localPos     = (gbufferModelViewInverse * vec4(fragPos, 1.0)).xyz;

	N = normalize(N);
	vec3 V = normalize(-fragPos);
	vec3 L = normalize(shadowLightPosition);
	vec3 H = normalize(V + L);

	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float NdotH = max(dot(N, H), 0.0);
	float HdotV = max(dot(H, V), 0.0);

	vec3 shadowCoord = getShadowCoord(fragPos, dot(N, L), false);
	
	vec3 F0 = mix(vec3(0.04), albedo, metallic);
	vec3 F  = fresnelSchlickRoughness(NdotV, F0, roughness);
	
	// Shadow energy + Ambient diffuse energy
	vec3 color = texture2D(colortex0, v_TexCoord).xyz;

	vec3 shadowFactor;
	if(mask.isHand)shadowFactor = vec3(0.0); // Disable weird shading of translucent hand items
	else {
		shadowFactor = getShadowColor(shadowtex0, shadowtex1, shadowcolor0, shadowCoord);
		shadowFactor *= computeShadowFade(dot(N, L));
		shadowFactor *= NdotL;
	}

	vec3 kD = (vec3(1.0) - F) * (1.0 - metallic);

	vec3 shadowBRDF = cookTorrance(albedo, roughness, metallic, NdotV, NdotL, NdotH, HdotV);
	vec3 ambientDiffuseBRDF = kD * albedo;

	vec3 shadowEnergy = (getShadowLightEnergy() * shadowFactor) * shadowBRDF;
	vec3 skyEnergy    = (avgSkyRadiance() * ambientLight.y) * ambientDiffuseBRDF;
	vec3 torchEnergy  = (TORCH_COLOR * ambientLight.x) * ambientDiffuseBRDF;

	color += shadowEnergy + skyEnergy + torchEnergy;


	// HDR
	gl_FragData[0].xyz = color;
	gl_FragData[0].w   = 1.0;
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
	gl_FragData[4].xy  = ambientLight;
	gl_FragData[4].w   = 1.0;
}
