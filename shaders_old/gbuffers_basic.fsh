#version 120
#include "include/common.glsl"
#include "include/material.glsl"
#include "include/atmospherics.glsl"
#include "include/shadow.glsl"

varying vec4 v_Color;
varying vec2 v_AmbientLight;
varying vec3 v_Normal;
varying vec3 v_FragPos;
varying vec3 v_ShadowCoord;

uniform sampler2DShadow shadowtex0; // All entities
uniform sampler2DShadow shadowtex1; // Opaque entities only
uniform sampler2D shadowcolor0;

void main() {
	// Read data from textures
	vec4 albedoAlpha = v_Color;
	float alpha = albedoAlpha.w;
	vec3 albedo = gammaToLinear(albedoAlpha.xyz);

	// Calculate useful values
	vec3 N = v_Normal;
	vec3 V = normalize(-v_FragPos);
	vec3 L = normalize(shadowLightPosition);

	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);

	vec3 shadowFactor = getShadowColor(shadowtex0, shadowtex1, shadowcolor0, v_ShadowCoord);
	shadowFactor *= getShadowSwitchFactor(); // Hide shading while switching light sources
	shadowFactor *= getShadowNoonFade(dot(v_Normal, L)); // Hide disconnected shadows at noon
	shadowFactor *= NdotL;

	vec3 shadowBRDF = albedo;
	vec3 ambientDiffuseBRDF = albedo;

	vec3 shadowEnergy   = (getShadowIlluminance() * shadowFactor) * shadowBRDF;
	vec3 skyEnergy      = (avgSkyRadiance() * v_AmbientLight.y) * ambientDiffuseBRDF;
	vec3 torchEnergy    = (TORCH_COLOR * v_AmbientLight.x) * ambientDiffuseBRDF;

	// HDR
	gl_FragData[0].xyz = shadowEnergy + skyEnergy + torchEnergy; // Ambient specular is computed in composite
	gl_FragData[0].w   = alpha;
	// Normal XY; Material ID
	// gl_FragData[1].xy  = vec2(0.0);
	gl_FragData[1].z   = encodeMask(genUnlitMask());
	gl_FragData[1].w   = 1.0;
}

/* DRAWBUFFERS:01 */