#version 120

#include "include/common.glsl"
#include "include/encoding.glsl"
#include "include/material.glsl"

varying vec4 v_Color;
varying vec3 v_Entity;
varying vec2 v_TexCoord;

uniform sampler2D texture;

void main() {
	vec4 albedoOpacity = texture2D(texture, v_TexCoord) * v_Color;
	albedoOpacity.xyz = gammaToLinear(albedoOpacity.xyz);
	albedoOpacity = remapEntityAlbedoOpacity(albedoOpacity, v_Entity);
	vec3 albedo = albedoOpacity.xyz;
	float opacity = albedoOpacity.w;

	// shadowcolor0: sRGB Shadow Color
	gl_FragData[0].xyz = linearToGamma(albedo * (1.0 - opacity));
	gl_FragData[0].w = opacity;
}

/* DRAWBUFFERS:0 */
