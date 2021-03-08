#include "include/common.glsl"
#include "include/material.glsl"

varying vec4 v_Color;

void main() {
	vec4 colorAlpha = v_Color;
	vec3 color = gammaToLinear(colorAlpha.xyz);
	float alpha = colorAlpha.w;

	// HDR
	gl_FragData[0].xyz = color;
	gl_FragData[0].w   = alpha;
	// Normal XY; Material ID
	// gl_FragData[1].xy  = vec2(0.0);
	gl_FragData[1].z   = encodeMask(genUnlitMask());
	gl_FragData[1].w   = 1.0;
	// Albedo
	// gl_FragData[2].xyz = vec3(0.0);
	// gl_FragData[2].w   = 1.0;
	// Roughness; Metallic; Transmittance
	// gl_FragData[3].xyz = vec3(0.0);
	// gl_FragData[3].w   = 1.0;
	// Ambient light
	// gl_FragData[4].xyz = vec3(0.0);
	// gl_FragData[4].w   = 1.0;
}
