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
#include "/include/modules/dither.glsl"
#include "/include/modules/gamma.glsl"
#include "/include/modules/luminance.glsl"
#include "/include/modules/tonemap.glsl"

// Reading temporal history, mixing-in bloom and final post processing

void main() {
	vec3 color = texture2D(colortex0, v_TexCoord).xyz; // colortex0 is RGB8 (Teporal History)
	color = gammaToLinear(color);

	color += readBloomAtlas(colortex1, v_TexCoord); // colortex1 is RGB16F (Reused HDR Buffer)
	color = pow(color, vec3(GAMMA));
	color = clamp(mix(vec3(luminance(color)), color, SATURATION), 0.0, 1.0);
	color = clamp(mix(vec3(0.5), color, CONTRAST), 0.0, 1.0);
	color = linearToGamma(color);
	color = dither8x8(color, gl_FragCoord.xy, 255.0);
	
	gl_FragData[0].xyz = color;
	gl_FragData[0].w   = 1.0;

#if SHOW_DEBUG_OUTPUT
	gl_FragData[0] = texture2D(colortex7, v_TexCoord);
#endif
}

#endif // FSH
