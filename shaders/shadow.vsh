#version 120

#include "include/common.glsl"

#include "include/shadow.glsl"
#include "include/wave.glsl"

attribute vec3 mc_Entity;
attribute vec2 mc_midTexCoord;

varying vec4 v_Color;
varying vec3 v_Entity;
varying vec2 v_TexCoord;

void main() {
	v_Color = gl_Color;
	v_Entity = mc_Entity;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	vec3 vertexPos = waveBlock(gl_Vertex.xyz, mc_Entity, mc_midTexCoord.y > gl_MultiTexCoord0.y);
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * vec4(vertexPos, 1.0);
	gl_Position.xy *= getShadowDistortionFactor(gl_Position.xy);
}
