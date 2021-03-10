#version 120
#include "include/common.glsl"
#include "include/encoding.glsl"
#include "include/pbr.glsl"
#include "include/shadow.glsl"

varying vec4 v_Color;
varying vec3 v_Entity;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;
varying vec3 v_Normal;
varying mat3 v_TBN;
varying vec3 v_FragPos;
varying vec3 v_ShadowCoord;

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2DShadow shadowtex0; // All entities
uniform sampler2DShadow shadowtex1; // Opaque entities only
uniform sampler2D shadowcolor0;

void main() {
	// Read data from textures
	vec4 albedoOpacity = texture2D(texture, v_TexCoord) * v_Color;
	vec3 albedo = gammaToLinear(albedoOpacity.xyz);
	float opacity = albedoOpacity.w;

	// Perceptual Smoothness; Metallic; Emission
	vec3 RME = texture2D(specular, v_TexCoord).xyz;
	// Convert perceptual dmoothness to linear roughness:
	RME.x = pow(1.0 - RME.x, 2.0);
	float roughness = RME.x;
	float metallic  = RME.y;
	float emission  = RME.z;

	vec3 N = normalize((texture2D(normals, v_TexCoord).xyz * 2.0 - 1.0) * v_TBN);
	vec3 V = normalize(-v_FragPos);
	vec3 L = normalize(shadowLightPosition);
	vec3 H = normalize(V + L);

	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float NdotH = max(dot(N, H), 0.0);
	float HdotV = max(dot(H, V), 0.0);

	vec3 specular = mix(vec3(0.04), albedo, metallic);
	specular = fresnelSchlick(NdotV, specular, roughness);

	vec3 shadowFactor = getShadowColor(shadowtex0, shadowtex1, shadowcolor0, v_ShadowCoord);
	shadowFactor *= NdotL;
	vec3 emissionFactor = albedo * emission;
	emissionFactor += entityColor.xyz * entityColor.w * entityColor.w * entityColor.w; // Cubed entity coloring factor looks way better

	vec3 shadowBRDF = cookTorrance(albedo, roughness, metallic, NdotV, NdotL, NdotH, HdotV);
	vec3 ambientDiffuseBRDF = (vec3(1.0) - specular) * (1.0 - metallic) * albedo;

	vec3 shadowEnergy   = (sunColor * shadowFactor) * shadowBRDF;
	vec3 skyEnergy      = (sunColor * 0.125 * v_AmbientLight.x) * ambientDiffuseBRDF;
	vec3 torchEnergy    = (torchColor * v_AmbientLight.y) * ambientDiffuseBRDF;
	vec3 emissionEnergy = EMISSION_ILLUMINANCE * emissionFactor;

	// colortex0 (HDR)
	gl_FragData[0].xyz = shadowEnergy + skyEnergy + torchEnergy + emissionEnergy; // Ambient specular is computed in composite
	gl_FragData[0].w   = opacity;
}

/* DRAWBUFFERS:0 */
