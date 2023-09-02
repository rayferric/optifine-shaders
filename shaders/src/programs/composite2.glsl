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
	// Pass-through the exposure temporal storage
	if (gl_FragCoord.x < 1.0 && gl_FragCoord.y < 1.0) {
		gl_FragData[0] = texture(colortex0, v_TexCoord);
		return;
	}

	// Tone-mapped floating-point LDR
	vec3 color = texture(colortex1, v_TexCoord).xyz;

	color = linearToGamma(color);
	color = dither8X8(color, ivec2(gl_FragCoord.xy), 255);

	gl_FragData[0].xyz = color;
	gl_FragData[0].w   = 1.0;
}

/* DRAWBUFFERS:0 */

#endif // FSH
