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

#include "/include/modules/bloom.glsl"
#include "/include/modules/gamma.glsl"

/* DRAWBUFFERS:1 */

// Reading temporal history and mipmapping for bloom

void main() {
	gl_FragData[0].xyz = gammaToLinear(writeBloomAtlas(colortex0, v_TexCoord));
	gl_FragData[0].w   = 1.0;
}

#endif // FSH
