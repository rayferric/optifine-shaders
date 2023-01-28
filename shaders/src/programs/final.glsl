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
#include "/src/modules/encode.glsl"
#include "/src/modules/gamma.glsl"
#include "/src/modules/luminance.glsl"
#include "/src/modules/tonemap.glsl"

// Reading temporal history, mixing-in bloom and final post processing

void main() {
	vec3 color = texture2D(colortex0, v_TexCoord).xyz; // colortex0 is RGB8 (Teporal History)
	color = gammaToLinear(color);

	float brightness = tonemapCustomReinhardInverse(encode8BitVec3(texture2D(colortex0, vec2(0.5 / viewWidth, 0.5 / viewHeight)).xyz), 4.0);
	float bloomOpacity = smoothstep(0.1 / MIN_SCENE_BRIGHTNESS, 1.0 / MIN_SCENE_BRIGHTNESS, 1.0 / brightness);
	#if BLOOM_INTENSITY != -2
		color += readBloomAtlas(colortex1, v_TexCoord) * bloomOpacity; // colortex1 is RGB16F (Reused HDR Buffer)
		color = clamp(color, 0.0, 1.0);
	#endif

	color = pow(color, vec3(GAMMA));
	color = clamp(mix(vec3(luminance(color)), color, SATURATION), 0.0, 1.0);
	color = clamp(mix(vec3(0.5), color, CONTRAST), 0.0, 1.0);
	color = linearToGamma(color);
	color = dither8X8(color, gl_FragCoord.xy, 255.0);
	
	gl_FragData[0].xyz = color;
	gl_FragData[0].w   = 1.0;

#ifdef SHOW_DEBUG_OUTPUT
	if (v_TexCoord.x < 0.25 && v_TexCoord.y < 0.25) {
		gl_FragData[0] = texture2D(colortex7, v_TexCoord * 4.0);
	}
#endif
}

#endif // FSH
