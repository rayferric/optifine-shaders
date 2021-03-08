#include "include/common.glsl"
#include "include/material.glsl"
#include "include/shadow.glsl"

attribute vec3 mc_Entity;
attribute vec4 at_tangent;

varying vec3 v_Entity;
varying vec4 v_Color;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;
varying vec3 v_Normal;
varying mat3 v_TBN;
varying vec3 v_FragPos;
varying vec3 v_ShadowCoord;

void main() {
	v_Entity = mc_Entity;
	v_Color = gl_Color;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	v_AmbientLight = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	v_AmbientLight = (v_AmbientLight - 0.025) / 0.975;
	v_AmbientLight = pow(v_AmbientLight, vec2(TORCH_FALLOFF, SKY_FALLOFF));

	v_Normal = normalize(gl_NormalMatrix * gl_Normal);

	vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	v_TBN = mat3(
		tangent.x, binormal.x, v_Normal.x,
		tangent.y, binormal.y, v_Normal.y,
		tangent.z, binormal.z, v_Normal.z
	);

	v_FragPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	float cosTheta = dot(v_Normal, normalize(shadowLightPosition));
	v_ShadowCoord = getShadowCoord(v_FragPos, cosTheta, isPlant(v_Entity));

	gl_Position = gl_ProjectionMatrix * vec4(v_FragPos, 1.0);
}