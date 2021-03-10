#version 120
#include "include/common.glsl"

varying vec4 v_Color;
varying vec2 v_TexCoord;

void main() {
	v_Color = gl_Color;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}
