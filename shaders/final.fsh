#version 120

#include "include/common.glsl"
#include "include/encoding.glsl"

varying vec2 v_TexCoord;

uniform sampler2D colortex1;

/**
 * Transforms HDR color to LDR using ACES operator.
 * Ported from original source:
 * https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve
 *
 * @param color HDR color
 *
 * @return LDR color
 */
 vec3 tonemapACES(in vec3 color) {
	const float a = 2.51;
	const float b = 0.03;
	const float c = 2.43;
	const float d = 0.59;
	const float e = 0.14;
	return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

uniform sampler2D depthtex0;

void main() {
	vec3 hdr = texture2D(colortex1, v_TexCoord).xyz;
	hdr /= 25000.0;

	vec3 color = tonemapACES(hdr);
	color = pow(color, vec3(GAMMA));
	color = clamp(mix(vec3(luma(color)), color, SATURATION), 0.0, 1.0);
	color = clamp(mix(vec3(0.5), color, CONTRAST), 0.0, 1.0);
	
	gl_FragColor.xyz = linearToGamma(color);
	gl_FragColor.w   = 1.0;
}
