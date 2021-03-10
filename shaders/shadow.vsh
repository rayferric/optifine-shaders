#version 120

#include "include/common.glsl"
#include "include/shadow.glsl"

attribute vec3 mc_Entity;

varying vec4 v_Color;
varying vec3 v_Entity;
varying vec2 v_TexCoord;

void main() {
	v_Color = gl_Color;
	v_Entity = mc_Entity;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
	gl_Position.xy *= getShadowDistortionFactor(gl_Position.xy);
}
