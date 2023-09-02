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
#include "/src/modules/dither.glsl"
#include "/src/modules/gamma.glsl"
#include "/src/modules/luminance.glsl"

void main() {
	vec3 color = texture(colortex0, v_TexCoord).xyz;
	color      = gammaToLinear(color);

	// vec3 bloom = readBloomAtlas(colortex1, v_TexCoord);
	// color      = max(color, bloom);
	// // color      = bloom;
	// // color += bloom * 1.0;
	// color = clamp(color, 0.0, 1.0);

	// color = pow(color, vec3(GAMMA));
	// color = clamp(mix(vec3(luminance(color)), color, SATURATION), 0.0, 1.0);
	// color = clamp(mix(vec3(0.5), color, CONTRAST), 0.0, 1.0);

	color = linearToGamma(color);

	gl_FragData[0].xyz = color;
	gl_FragData[0].w   = 1.0;

#ifdef SHOW_DEBUG_OUTPUT
	if (v_TexCoord.x < 0.5 && v_TexCoord.y < 0.5) {
		gl_FragData[0] = texture(colortex6, v_TexCoord * 2.0);
	}
#endif
}

/* DRAWBUFFERS:0 */

#endif // FSH
