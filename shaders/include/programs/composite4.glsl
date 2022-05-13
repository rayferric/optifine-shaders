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

/* DRAWBUFFERS:1 */

// Horizontal bloom atlas blur

void main() {
	gl_FragData[0].xyz = blurBloomAtlas(colortex1, v_TexCoord, false);
	gl_FragData[0].w   = 1.0;
}

#endif // FSH
