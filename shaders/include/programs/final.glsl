varying vec2 v_TexCoord;

///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

void main() {
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/include/modules/gamma.glsl"
#include "/include/modules/luminance.glsl"
#include "/include/modules/tonemap.glsl"

void main() {
	vec3 color = texture2D(colortex1, v_TexCoord).xyz;

	color = pow(color, vec3(GAMMA));
	color = clamp(mix(vec3(luminance(color)), color, SATURATION), 0.0, 1.0);
	color = clamp(mix(vec3(0.5), color, CONTRAST), 0.0, 1.0);
	
	gl_FragData[0].xyz = linearToGamma(color);
	gl_FragData[0].w   = 1.0;

#ifdef SHOW_DEBUG_OUTPUT
	gl_FragData[0] = texture2D(colortex7, v_TexCoord);
#endif
}

#endif // FSH
