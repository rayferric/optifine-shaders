varying vec4 v_Color;
varying vec3 v_Entity;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;
varying mat3 v_TBN;
varying vec3 v_WorldPos;

///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

#include "/include/modules/temporal_jitter.glsl"
#include "/include/modules/wave.glsl"

void main() {
	v_Color = gl_Color;
	v_Entity = mc_Entity;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	v_AmbientLight = (gl_TextureMatrix[1] * gl_MultiTexCoord1).yx;
	v_AmbientLight = (v_AmbientLight - 0.025) / 0.975;
	v_AmbientLight = pow(v_AmbientLight, vec2(SKY_FALLOFF, TORCH_FALLOFF));

	vec3 normal = gl_NormalMatrix * gl_Normal;
	vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(cross(tangent, normal) * at_tangent.w);
	   
	v_TBN = mat3(
		tangent.x, binormal.x, normal.x,
		tangent.y, binormal.y, normal.y,
		tangent.z, binormal.z, normal.z
	);

	// We can use the fact that most waving vertices will have integer coordinates to fix precision errors by flooring
	v_WorldPos = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz + cameraPosition;
	vec3 vertexPos = gl_Vertex.xyz; // Either chunk space or camera space
	vertexPos += getBlockWave(floor(v_WorldPos + vec3(0.5)), mc_Entity, mc_midTexCoord.y > gl_MultiTexCoord0.y);

	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * vec4(vertexPos, 1.0);
	gl_Position.xy /= gl_Position.w;
	// Multiply by 2 to convert from screen space to NDC
	gl_Position.xy += getTemporalOffset() * 2.0;
	gl_Position.xy *= gl_Position.w;
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/include/modules/blocks.glsl"
#include "/include/modules/encode.glsl"
#include "/include/modules/gamma.glsl"
#include "/include/modules/material_mask.glsl"
#include "/include/modules/remap_pbr_values.glsl"
#include "/include/modules/wave.glsl"

/* DRAWBUFFERS:234 */

void main() {
	// Albedo is sRGB
	vec4 albedoOpacity = texture2D(texture, v_TexCoord) * v_Color;
	albedoOpacity.xyz = gammaToLinear(albedoOpacity.xyz);
	albedoOpacity = remapBlockAlbedoOpacity(albedoOpacity, v_Entity);
	vec3 albedo = albedoOpacity.xyz;
	float opacity = albedoOpacity.w;

	// Perceptual Smoothness; Metallic; Emission
	vec3 rme = texture2D(specular, v_TexCoord).xyz;
	// Convert perceptual smoothness to roughness
	rme.x = pow(1.0 - rme.x, 2.0);
	rme = remapBlockRme(rme, v_Entity);
	float roughness = rme.x;
	float metallic  = rme.y;
	float emission  = rme.z;

	vec3 normal = normalize((texture2D(normals, v_TexCoord).xyz * 2.0 - 1.0) * v_TBN);

	if (isWater(v_Entity)) {
		vec3 worldNormal = getWaterWaveNormal(v_WorldPos.xz);
		normal = mat3(gbufferModelView) * worldNormal;
	}

	// Initialization is required by OptiFine
	gl_FragData[0] = vec4(1.0);

	// colortex2: Packed Normal
	gl_FragData[0].xy = encodeNormal(normal);
	gl_FragData[0].w  = isTranslucent(v_Entity) ? 1.0 : opacity;

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

#endif // FSH
