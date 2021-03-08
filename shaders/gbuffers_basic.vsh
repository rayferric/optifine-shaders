#version 120
#include "include/common.glsl"
#include "include/shadow.glsl"

varying vec4 v_Color;
varying vec2 v_AmbientLight;
varying vec3 v_Normal;
varying vec3 v_FragPos;
varying vec3 v_ShadowCoord;

void main() {
	v_Color = gl_Color;

	v_AmbientLight = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	v_AmbientLight = (v_AmbientLight - 0.025) / 0.975;
	v_AmbientLight = pow(v_AmbientLight, vec2(TORCH_FALLOFF, SKY_FALLOFF));

	v_Normal = normalize(upPosition);

	v_FragPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	float cosTheta = dot(v_Normal, normalize(shadowLightPosition));
	v_ShadowCoord = getShadowCoord(v_FragPos, cosTheta, false);

	gl_Position = gl_ProjectionMatrix * vec4(v_FragPos, 1.0);
}
