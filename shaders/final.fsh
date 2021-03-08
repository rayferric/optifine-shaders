#version 120
#include "include/common.glsl"
#include "include/atmospherics.glsl"

varying vec2 v_TexCoord;

uniform sampler2D colortex0;
uniform sampler2D colortex5;

void main() {
	vec3 color = gammaToLinear(texture2D(colortex5, v_TexCoord).xyz);

	color = pow(color, vec3(GAMMA));
	color = clamp(mix(vec3(luma(color)), color, SATURATION), 0.0, 1.0);
	color = clamp(mix(vec3(0.5), color, CONTRAST), 0.0, 1.0);
	
	gl_FragColor.xyz = linearToGamma(color);
	gl_FragColor.w   = 1.0;
}