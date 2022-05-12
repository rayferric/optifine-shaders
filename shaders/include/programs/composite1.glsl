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

#include "/include/modules/encode.glsl"
#include "/include/modules/luminance.glsl"
#include "/include/modules/tonemap.glsl"

/* DRAWBUFFERS:01 */

// Auto exposure and tonemapping

void main() {
	float brightness = tonemapCustomReinhardInverse(encodeVec3(texture2D(colortex0, vec2(0.5 / viewWidth, 0.5 / viewHeight)).xyz), 4.0);

	if (gl_FragCoord.x < 1.0 && gl_FragCoord.y < 1.0) {
		float brightnessLod = log2(viewHeight);
		float newBrightness = luminance(texture2DLod(colortex1, vec2(0.5), brightnessLod).xyz);

		if (newBrightness > EPSILON) // OptiFine mipmapping likes to flicker with pure black sometimes
			newBrightness = mix(brightness, newBrightness, 0.05);
		else
			newBrightness = brightness;

		newBrightness = clamp(newBrightness, 0.1, 10.0);

		// colortex0: Temporal History
		gl_FragData[0].xyz = decodeVec3(tonemapCustomReinhard(newBrightness, 4.0));
		gl_FragData[0].w   = 1.0;
	} else {
		// colortex0: Temporal History
		gl_FragData[0] = texture2D(colortex0, v_TexCoord);
	}

	vec3 hdr = texture2D(colortex1, v_TexCoord).xyz;
	hdr /= 5.0 * brightness; // EXPOSURE
	hdr = tonemapAces(hdr);

	// colortex1: HDR Buffer
	gl_FragData[1].xyz = hdr;
	gl_FragData[1].w   = 1.0;
}

#endif // FSH
