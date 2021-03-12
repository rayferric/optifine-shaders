#version 120

#include "include/common.glsl"
#include "include/material.glsl"
#include "include/shadow.glsl"
#include "include/wave.glsl"

attribute vec3 mc_Entity;
attribute vec4 at_tangent;
attribute vec2 mc_midTexCoord;

varying vec4 v_Color;
varying vec3 v_Entity;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;
varying vec3 v_Normal;
varying mat3 v_TBN;
varying vec3 v_FragPos;
varying vec3 v_ShadowCoord;

void main() {
	v_Color = gl_Color;
	v_Entity = mc_Entity;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	v_AmbientLight = (gl_TextureMatrix[1] * gl_MultiTexCoord1).yx;
	v_AmbientLight = (v_AmbientLight - 0.025) / 0.975;
	v_AmbientLight = pow(v_AmbientLight, vec2(SKY_FALLOFF, TORCH_FALLOFF));

	v_Normal = gl_NormalMatrix * gl_Normal;

	vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(cross(tangent, v_Normal) * at_tangent.w);
	   
	v_TBN = mat3(
		tangent.x, binormal.x, v_Normal.x,
		tangent.y, binormal.y, v_Normal.y,
		tangent.z, binormal.z, v_Normal.z
	);

	vec3 vertexPos = waveBlock(gl_Vertex.xyz, mc_Entity, mc_midTexCoord.y > gl_MultiTexCoord0.y);
	v_FragPos = (gl_ModelViewMatrix * vec4(vertexPos, 1.0)).xyz;
	float cosTheta = dot(v_Normal, normalize(shadowLightPosition));
	v_ShadowCoord = getShadowCoord(v_FragPos, cosTheta);

	gl_Position = gl_ProjectionMatrix * vec4(v_FragPos, 1.0);
}
