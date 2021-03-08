#include "include/common.glsl"
#include "include/material.glsl"

varying vec3 v_Entity;
varying vec4 v_Color;
varying vec2 v_TexCoord;

uniform sampler2D texture;

void main() {
	vec4 albedoAlpha = texture2D(texture, v_TexCoord) * v_Color;
	float alpha = albedoAlpha.w;
	vec3 albedo = gammaToLinear(albedoAlpha.xyz);
	albedo = remapEntityAlbedo(albedo, v_Entity);

	float transmittance = remapEntityRMET(vec4(0.0, 0.0, 0.0, 1.0 - alpha), v_Entity).w;

	gl_FragData[0].xyz = albedo * transmittance;
	gl_FragData[0].w = alpha;
}