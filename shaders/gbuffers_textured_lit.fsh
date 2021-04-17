#version 120

#include "include/common.glsl"

#include "include/encoding.glsl"
#include "include/material.glsl"

varying vec4 v_Color;
varying vec3 v_Entity;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;
varying mat3 v_TBN;

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D shadowtex0; // All entities
uniform sampler2D shadowtex1; // Opaque entities only
uniform sampler2D shadowcolor0;

void main() {
	// Albedo is sRGB
	vec4 albedoOpacity = texture2D(texture, v_TexCoord) * v_Color;
	albedoOpacity.xyz = gammaToLinear(albedoOpacity.xyz);
	albedoOpacity = remapBlockAlbedoOpacity(albedoOpacity, v_Entity);
	vec3 albedo = albedoOpacity.xyz;
	float opacity = albedoOpacity.w;

	// Perceptual Smoothness; Metallic; Emission
	vec3 RME = texture2D(specular, v_TexCoord).xyz;
	// Convert perceptual smoothness to roughness
	RME.x = pow(1.0 - RME.x, 2.0);
	RME = remapBlockRME(RME, v_Entity);
	float roughness = RME.x;
	float metallic  = RME.y;
	float emission  = RME.z;

	vec3 N = normalize((texture2D(normals, v_TexCoord).xyz * 2.0 - 1.0) * v_TBN);

	// colortex2: Packed Normal
	gl_FragData[0].xy = encodeNormal(N);
	gl_FragData[0].w  = isOpaque(v_Entity) ? opacity : 1.0;

	// colortex3: Packed sRGB Albedo RG; Packed (sRGB Albedo B + Opacity); Packed (Roughness + Metallic)
	vec3 albedoGamma = linearToGamma(albedo);
	gl_FragData[1].x = encodeVec2(albedoGamma.xy);
	gl_FragData[1].y = encodeVec2(vec2(albedoGamma.z, opacity));
	gl_FragData[1].z = encodeVec2(vec2(roughness, metallic));
	gl_FragData[1].w = 1.0;

	// colortex4: Gamma-Space Sky Light; Gamma-Space Torch Light; Material ID
	gl_FragData[2].xy = linearToGamma(v_AmbientLight);
	gl_FragData[2].z  = encodeMask(makeLitMask(v_Entity));
	gl_FragData[2].w  = 1.0;
}

/* DRAWBUFFERS:234 */
