// This stage is responsible for blending the temporal history.

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

#include "/src/modules/dither.glsl"
#include "/src/modules/gamma.glsl"

void main() {
	// // Pass-through the exposure temporal storage
	// if (gl_FragCoord.x < 1.0 && gl_FragCoord.y < 1.0) {
	// 	outColor0 = texture(colortex6, v_TexCoord);
	// 	return;
	// }

	// // Tone-mapped floating-point LDR
	// vec3 ldr = texture(colortex5, v_TexCoord).xyz;

	// ldr = linearToGamma(ldr);
	// ldr = dither8X8(ldr, ivec2(gl_FragCoord.xy), 255);

	// outColor0.xyz = ldr;
	// outColor0.w   = 1.0;
	outColor0 = texture(colortex0, v_TexCoord);
}

/* RENDERTARGETS: 0 */

#endif // FSH
