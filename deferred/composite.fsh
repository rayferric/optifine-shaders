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

vec4 texture2DDistort(in sampler2D tex, in vec2 coord, in ivec2 scale) {
	coord = (coord * scale) + 0.5;

	vec2 f = fract(coord);
	coord = floor(coord) + f * f;

	coord = (coord - 0.5) / scale;
	return texture2D(tex, coord);
}

vec3 getWaterFog(in vec3 color, in MaterialMask mask, in vec3 fragPos, in vec3 fragPosOpaque) {
	if(!mask.isWater && !mask.isIce && isEyeInWater < 1)return color;

	float dist = distance(fragPos, fragPosOpaque);
	if(isEyeInWater > 0)dist = length(fragPos) * 0.5;


	float density = 0.5;
	vec3 fogColor = WATER_ALBEDO;
	if(mask.isIce) {
		density = 1.0;
		fogColor = ICE_ALBEDO;
	}
	fogColor *= 0.05;

	float fogFactor = 1.0 - clamp(exp(-density * dist), 0.0, 1.0);
	fogFactor *= fogFactor;
	return mix(color, fogColor, fogFactor);
}

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
	gl_FragData[0].xyz = texture2D(colortex0, v_TexCoord).xyz;
		return; // TODO DEBUG

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
	vec3 color;
	if(mask.isTranslucent) {
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

		color = shadowEnergy + skyEnergy + torchEnergy;
	} else {
		color = texture2D(colortex0, v_TexCoord).xyz;
	}

	// Ambient specular energy
	// Save some processing power here
	if(roughness < 0.25) {
		float fallbackFactor = float(ambientLight.y > 0.01) * (1.0 - isEyeInWater) * max(dot(N, normalize(upPosition)), 0.0); // Fall back to black in caves, under water and on surfaces that are not facing up
		vec3 reflectionEnergy = computeSSR(colortex0, depthtex0, fragPos, N, roughness, pow(ambientLight.y, 2.0));
		color += F * reflectionEnergy;
	}


	// Ambient transmitted energy
	if(mask.isTranslucent) {
		// TODO Use Du-Dv maps instead (animated for water)
		vec3 refraction = texture2DDistort(colortex0, v_TexCoord, ivec2(64.0 * sqrt(abs(fragPos.z)))).xyz;

		float fresnelStrength  = fresnelSchlickStrength(NdotV, 0.0);
		float kT = (1.0 - fresnelStrength) * transmittance;
		vec3 transmitted = refraction * albedo;
		
		color = mix(color, transmitted, kT);
	} else {
		//color = getWaterFog(color, mask, fragPos, fragPosSolid);
	}

	gl_FragData[0].xyz = color;
	gl_FragData[0].w   = 1.0;
}
