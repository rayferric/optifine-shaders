#version 120

#include "include/common.glsl"

#include "include/encoding.glsl"
#include "include/luminance.glsl"
#include "include/tonemap.glsl"

varying vec2 v_TexCoord;

uniform sampler2D colortex1;

uniform sampler2D depthtex0;

void main() {
	vec3 hdr = texture2D(colortex1, v_TexCoord).xyz;
	hdr /= 25000.0;

	vec3 color = tonemapACES(hdr);
	color = pow(color, vec3(GAMMA));
	color = clamp(mix(vec3(luminance(color)), color, SATURATION), 0.0, 1.0);
	color = clamp(mix(vec3(0.5), color, CONTRAST), 0.0, 1.0);
	
	gl_FragColor.xyz = linearToGamma(color);
	gl_FragColor.w   = 1.0;
}
