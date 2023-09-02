// Scene brightness is evaluated here and used to adjust the exposure. The
// resulting color is then tone-mapped and written back to the HDR buffer.
// This stage is also responsible for blending in auto-exposure cache into the
// history. It additionally caches many other things for the next frame thus
// executing the workload only once per frame instead of for every pixel.

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

#include "/src/modules/hash.glsl"
#include "/src/modules/luminance.glsl"
#include "/src/modules/pack.glsl"
#include "/src/modules/sky.glsl"
#include "/src/modules/tonemap.glsl"

#include "/src/modules/gamma.glsl"

#define AUTO_EXPOSURE_LUMINANCE_SAMPLES 10
void main() {
	float exposure = pack8BitVec3(
	    texture(colortex0, vec2(0.5 / viewWidth, 0.5 / viewHeight)).xyz
	);
	exposure = exposure * (MAX_EXPOSURE - MIN_EXPOSURE) + MIN_EXPOSURE;

	if (gl_FragCoord.y < 1.0 && gl_FragCoord.x < 1.0) {
		// auto-exposure: x = 0
		float lum = 0.0;
		for (int i = 0; i < AUTO_EXPOSURE_LUMINANCE_SAMPLES; i++) {
			vec2 uv = hash(hash(fract(vec3(
			                   frameTimeCounter * float(i),
			                   frameTimeCounter * float(i) * 2.0,
			                   frameTimeCounter * float(i) * 3.0
			               ))))
			              .xy;
			lum += luminance(textureLod(colortex1, uv, 4).xyz);
		}
		lum /= float(AUTO_EXPOSURE_LUMINANCE_SAMPLES);

		float newExposure = 0.2 / lum;
		// float newExposure = 5.0;
		newExposure = clamp(newExposure, MIN_EXPOSURE, MAX_EXPOSURE);
		newExposure = pow(newExposure, 0.5);
		exposure    = pow(exposure, 0.5);
		newExposure = mix(exposure, newExposure, frameTime);
		newExposure = pow(newExposure, 2.0);
		exposure    = pow(exposure, 2.0);

		exposure = (newExposure - MIN_EXPOSURE) / (MAX_EXPOSURE - MIN_EXPOSURE);

		gl_FragData[0].xyz = unpack8BitVec3(exposure);
		gl_FragData[0].w   = 1.0;
	} else {
		// colortex0: temporal history
		gl_FragData[0] = texture(colortex0, v_TexCoord);
	}

	// HDR Tonemapping
	vec3 hdr = texture(colortex1, v_TexCoord).xyz;
	hdr      *= exposure;
	hdr      = tonemapAces(hdr);

	// colortex1: HDR multipurpose
	gl_FragData[1].xyz = hdr;
	gl_FragData[1].w   = 1.0;
}

/* DRAWBUFFERS:01 */

#endif // FSH
