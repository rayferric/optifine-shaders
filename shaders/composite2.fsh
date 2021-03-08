#version 120
#include "include/common.glsl"
#include "include/bloom.glsl"

varying vec2 v_TexCoord;

uniform sampler2D colortex4;

void main() {
	// Mipmapped HDR
	gl_FragData[0].xyz = blurBloom(colortex4, v_TexCoord, ivec2(1, 0));
	gl_FragData[0].w   = 1.0;
}

/* DRAWBUFFERS:4 */