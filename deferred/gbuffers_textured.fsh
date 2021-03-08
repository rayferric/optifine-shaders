#include "include/common.glsl"
#include "include/atmospherics.glsl"
#include "include/material.glsl"

varying vec4 v_Color;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;

uniform sampler2D texture;
uniform sampler2D lightmap;

void main() {
	vec4 albedoAlpha = texture2D(texture, v_TexCoord) * v_Color;
	float alpha = albedoAlpha.w;
	vec3 albedo = gammaToLinear(albedoAlpha.xyz) * alpha;

	vec3 skyEnergy = (v_AmbientLight.y) * albedo;
	vec3 torchEnergy = (TORCH_COLOR * v_AmbientLight.x) * albedo;

	// HDR
	gl_FragData[0].xyz = skyEnergy;// + torchEnergy;
	gl_FragData[0].w   = alpha;
	// Normal XY; Material ID
	// gl_FragData[1].xy  = vec2(0.0);
	gl_FragData[1].z   = encodeMask(genUnlitMask());
	gl_FragData[1].w   = 1.0;
	// Albedo
	// gl_FragData[2].xyz = vec3(0.0);
	// gl_FragData[2].w   = 1.0;
	// Roughness; Metallic; Transmittance
	// gl_FragData[3].xyz = vec3(0.0);
	// gl_FragData[3].w   = 1.0;
	// Ambient light
	// gl_FragData[4].xyz = vec3(0.0);
	// gl_FragData[4].w   = 1.0;
}