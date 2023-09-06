///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

void main() {
	gl_Position = ftransform();
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/src/modules/gbuffer.glsl"

void main() {
	GBuffer gbuffer;
	gbuffer.layer = GBUFFER_LAYER_SKY;

	// outColor0 = renderGBuffer0(gbuffer);
	// outColor1 = renderGBuffer1(gbuffer);
	// outColor2 = renderGBuffer2(gbuffer);
	// outColor3 = renderGBuffer3(gbuffer);
	// outColor4 = renderGBuffer4(gbuffer);
	outColor0 = renderGBuffer4(gbuffer);
}

// /* RENDERTARGETS: 0,1,2,3,4 */
/* RENDERTARGETS: 4 */

#endif // FSH
