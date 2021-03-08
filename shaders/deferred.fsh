#version 120
#include "include/common.glsl"
#include "include/material.glsl"
#include "include/atmospherics.glsl"

varying vec2 v_TexCoord;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

void main() {
	float depth = texture2D(depthtex0, v_TexCoord).x;
	if(depth == 1.0) { // Sky
		vec3 fragPos = getFragPos(depth, v_TexCoord);
		// HDR
		gl_FragData[0].xyz = getSpaceEnergy(normalize(fragPos));
		gl_FragData[0].w   = 1.0;
		// Normal XY; Material ID
		// gl_FragData[1].xy  = vec2(0.0);
		gl_FragData[1].z   = encodeMask(genSkyMask());
		gl_FragData[1].w   = 1.0;
		return;
	}

	// HDR
	gl_FragData[0] = texture2D(colortex0, v_TexCoord);
	// Normal XY; Material ID
	gl_FragData[1] = texture2D(colortex1, v_TexCoord);
}

/* DRAWBUFFERS:01 */