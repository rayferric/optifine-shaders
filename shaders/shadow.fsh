#version 120

#include "include/common.glsl"
#include "include/encoding.glsl"

varying vec4 v_Color;
varying vec2 v_TexCoord;

uniform sampler2D texture;

void main() {
	vec4 albedoOpacity = texture2D(texture, v_TexCoord) * v_Color;
	vec3 albedo = gammaToLinear(albedoOpacity.xyz);
	float opacity = albedoOpacity.w;

	// shadowcolor0 (Shadow Color)
	gl_FragData[0].xyz = albedo * (1.0 - opacity);
	gl_FragData[0].w = opacity;
}

/* DRAWBUFFERS:0 */
