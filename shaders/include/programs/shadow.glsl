varying vec4 v_Color;
varying vec3 v_Entity;
varying vec2 v_TexCoord;

///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

#include "include/modules/shadow.glsl"
#include "include/modules/wave.glsl"

void main() {
	v_Color = gl_Color;
	v_Entity = mc_Entity;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	vec3 vertexPos = waveBlock(gl_Vertex.xyz, mc_Entity, mc_midTexCoord.y > gl_MultiTexCoord0.y);
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * vec4(vertexPos, 1.0);
	gl_Position.xy *= getShadowDistortionFactor(gl_Position.xy);
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "include/modules/gamma.glsl"
#include "include/modules/remap_pbr_values.glsl"

void main() {
	vec4 albedoOpacity = texture2D(texture. v_TexCoord) * v_Color;
	albedoOpacity.xyz = gammaToLinear(albedoOpacity.xyz);
	albedoOpacity = remapBlockAlbedoOpacity(albedoOpacity, v_Entity);
	vec3 albedo = albedoOpacity.xyz;
	float opacity = albedoOpacity.w;

	// shadowcolor0: sRGB Shadow Color
	gl_FragData[0].xyz = linearToGamma(albedo * (1.0 - opacity));
	gl_FragData[0].w = opacity;
}

/* DRAWBUFFERS:0 */

#endif // FSH
