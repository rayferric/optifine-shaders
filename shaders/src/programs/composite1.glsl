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

#include "/src/modules/encode.glsl"
#include "/src/modules/halton.glsl"
#include "/src/modules/hash.glsl"
#include "/src/modules/luminance.glsl"
#include "/src/modules/tonemap.glsl"

/* DRAWBUFFERS:01 */

// Auto exposure and tonemapping

void main() {
	float brightness = tonemapCustomReinhardInverse(encode8BitVec3(
		texture2D(colortex0, vec2(0.5 / viewWidth, 0.5 / viewHeight)).xyz
	), 4.0);

	if (gl_FragCoord.x < 1.0 && gl_FragCoord.y < 1.0) {
		float maxLod = log2(viewHeight);
		float newBrightness = 0.0;
		for (int i = 0; i < 5; i++) {
			newBrightness += luminance(
				texture2DLod(colortex1, halton16[(i + frameCounter) % 16], float(i)).xyz
			);
		}
		newBrightness *= 0.2;

		if (newBrightness > EPSILON) // OptiFine mipmapping likes to flicker with pure black sometimes
			newBrightness = mix(brightness, newBrightness, 0.5 * frameTime);
		else
			newBrightness = brightness;

		newBrightness = clamp(newBrightness, MIN_SCENE_BRIGHTNESS, MAX_SCENE_BRIGHTNESS);

		// colortex0: Temporal History
		gl_FragData[0].xyz = decode8BitVec3(tonemapCustomReinhard(newBrightness, 4.0));
		gl_FragData[0].w   = 1.0;
	} else {
		// colortex0: Temporal History
		gl_FragData[0] = texture2D(colortex0, v_TexCoord);
	}

	vec3 hdr = texture2D(colortex1, v_TexCoord).xyz;
	hdr /= 10.0 * brightness; // EXPOSURE
	hdr = tonemapAces(hdr);

	// colortex1: HDR Buffer
	gl_FragData[1].xyz = hdr;
	gl_FragData[1].w   = 1.0;
}

#endif // FSH
