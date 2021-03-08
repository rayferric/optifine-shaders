#include "include/common.glsl"
#include "include/material.glsl"
#include "include/atmospherics.glsl"

varying vec3 v_FragPos;

void main() {
	// HDR
	gl_FragData[0].xyz = getSkyEnergy(normalize(v_FragPos)); // TODO Compute sky color
	gl_FragData[0].w   = 0.11; // Low alpha (mostly) eliminates stars during night (preasumably additive blending is involved)
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
