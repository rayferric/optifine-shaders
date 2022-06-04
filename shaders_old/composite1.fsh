#version 120
#include "include/common.glsl"
#include "include/bloom.glsl"

varying vec2 v_TexCoord;

uniform sampler2D colortex0;

void main() {
	// Mipmapped HDR
	gl_FragData[0].xyz = vec3(0.0);
	for (int i = 1; i <= BLOOM_LEVELS; i++) {
		gl_FragData[0].xyz += writeBloomTile(colortex0, v_TexCoord, i);
	}
	gl_FragData[0].w   = 1.0;
}

/* DRAWBUFFERS:4 */