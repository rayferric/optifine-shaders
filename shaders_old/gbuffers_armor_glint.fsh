#version 120
#include "include/common.glsl"
#include "include/material.glsl"
#include "include/atmospherics.glsl"

varying vec4 v_Color;
varying vec2 v_TexCoord;

uniform sampler2D texture;

void main() {
	vec4 albedoAlpha = texture2D(texture, v_TexCoord) * v_Color;
	float alpha = albedoAlpha.w;
	vec3 albedo = gammaToLinear(albedoAlpha.xyz) * alpha;

	// HDR
	gl_FragData[0].xyz = EMISSION_ILLUMINANCE * albedo;
	gl_FragData[0].w   = alpha;
	// Normal XY; Material ID
	// gl_FragData[1].xy  = vec2(0.0);
	gl_FragData[1].z   = encodeMask(genUnlitMask());
	gl_FragData[1].w   = 1.0;
}

/* DRAWBUFFERS:01 */