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

#include "/src/modules/temporal_jitter.glsl"
#include "/src/modules/wave.glsl"

void main() {
	v_Color = gl_Color;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	v_AmbientLight = (gl_TextureMatrix[1] * gl_MultiTexCoord1).yx;
	v_AmbientLight = (v_AmbientLight - 0.025) / 0.975;
	v_AmbientLight = pow(v_AmbientLight, vec2(3.0, 6.0));

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

	if (gl_Position.x > 0.0)
		v_Entity = vec3(float(heldItemId), 0.0, 0.0);
	else 
		v_Entity = vec3(float(heldItemId2), 0.0, 0.0);
	
	gl_Position.xy *= gl_Position.w;
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/src/modules/blocks.glsl"
#include "/src/modules/encode.glsl"
#include "/src/modules/gamma.glsl"
#include "/src/modules/material_mask.glsl"
#include "/src/modules/material_properties.glsl"
#include "/src/modules/wave.glsl"

/* DRAWBUFFERS:234 */

void main() {
	MaterialProperties properties = makeMaterialProperties();

	// Albedo is sRGB
	vec4 albedoOpacity = texture2D(texture, v_TexCoord) * v_Color;
	albedoOpacity.xyz = gammaToLinear(albedoOpacity.xyz);
	properties.albedo = albedoOpacity.xyz;
	properties.opacity = albedoOpacity.w;

	// Perceptual Smoothness; Metallic; Emission
	vec3 rme = texture2D(specular, v_TexCoord).xyz;
	// Convert perceptual smoothness to roughness
	rme.x = pow(1.0 - rme.x, 2.0);
	properties.roughness = rme.x;
	properties.metallic  = rme.y;
	properties.emission  = rme.z;

	properties = remapMaterialProperties(properties, v_Entity);

	vec3 normal = normalize((texture2D(normals, v_TexCoord).xyz * 2.0 - 1.0) * v_TBN);

	MaterialMask mask;
	mask.isLit         = true;
	mask.isEmissive    = properties.emission > 0.5;
	mask.isTranslucent = isTranslucent(v_Entity);
	mask.isPlayer      = true;
	mask.isFoliage     = false;

	// Initialization is required by OptiFine
	gl_FragData[0] = vec4(1.0);

	// colortex2: Packed Normal
	gl_FragData[0].xy = encodeNormal(normal);
	gl_FragData[0].w  = isTranslucent(v_Entity) ? 1.0 : properties.opacity;

	// colortex3: Packed sRGB Albedo RG; Packed (sRGB Albedo B + Opacity); Packed (Roughness + Metallic)
	vec3 albedoGamma = linearToGamma(properties.albedo);
	gl_FragData[1].x = encode8BitVec2(albedoGamma.xy);
	gl_FragData[1].y = encode8BitVec2(vec2(albedoGamma.z, properties.opacity));
	gl_FragData[1].z = encode8BitVec2(vec2(properties.roughness, properties.metallic));
	gl_FragData[1].w = 1.0;

	// colortex4: Gamma-Space Sky Light; Gamma-Space Block Light; Material ID
	gl_FragData[2].xy = linearToGamma(v_AmbientLight);
	gl_FragData[2].z  = encodeMask(mask);
	gl_FragData[2].w  = 1.0;
}

#endif // FSH
