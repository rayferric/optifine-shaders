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

#include "/src/modules/bloom.glsl"

// horizontal bloom atlas blur

void main() {
	// outColor0.xyz = blurBloomAtlas(colortex5, v_TexCoord, false);
	// outColor0.w   = 1.0;
	outColor0 = texture(colortex0, v_TexCoord);
}

/* RENDERTARGETS: 0 */

#endif // FSH
