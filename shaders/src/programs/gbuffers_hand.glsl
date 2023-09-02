varying vec4 v_Color;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;

///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

void main() {
	v_Color = gl_Color;

	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	v_AmbientLight = (gl_TextureMatrix[1] * gl_MultiTexCoord1).yx;
	v_AmbientLight = (v_AmbientLight - 0.025) / 0.975;

	gl_Position = ftransform();
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/src/modules/gamma.glsl"

void main() {
	gl_FragData[0]    = texture(texture, v_TexCoord) * v_Color;
	gl_FragData[1].xy = linearToGamma(v_AmbientLight);
	gl_FragData[1].w  = 1.0;
}

/* DRAWBUFFERS:25 */

#endif // FSH
