varying vec4 v_Color;
varying vec3 v_Entity;
varying vec2 v_TexCoord;

///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

#include "/src/modules/shadow_distortion.glsl"
#include "/src/modules/wave.glsl"

void main() {
	v_Color = gl_Color;
	v_Entity = mc_Entity;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	// We can use the fact that most waving vertices will have integer coordinates to fix precision errors by flooring
	vec3 worldPos = (shadowModelViewInverse * shadowProjectionInverse * ftransform()).xyz + cameraPosition;
	vec3 vertexPos = gl_Vertex.xyz; // Either chunk space or camera space
	vertexPos += getBlockWave(floor(worldPos + vec3(0.5)), mc_Entity, mc_midTexCoord.y > gl_MultiTexCoord0.y);

	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * vec4(vertexPos, 1.0);
	gl_Position.xy *= getShadowDistortionFactor(gl_Position.xy);
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/src/modules/gamma.glsl"
#include "/src/modules/material_properties.glsl"

/* DRAWBUFFERS:0 */

void main() {
	MaterialProperties properties = makeMaterialProperties();

	vec4 albedoOpacity = texture2D(texture, v_TexCoord) * v_Color;
	albedoOpacity.xyz = gammaToLinear(albedoOpacity.xyz);
	properties.albedo = albedoOpacity.xyz;
	properties.opacity = albedoOpacity.w;

	properties = remapMaterialProperties(properties, v_Entity);

	// Initialization is required by OptiFine
	gl_FragData[0] = vec4(1.0);

	// shadowcolor0: sRGB Shadow Color
	gl_FragData[0].xyz = linearToGamma(properties.albedo);
	gl_FragData[0].w = properties.opacity;
}

#endif // FSH
