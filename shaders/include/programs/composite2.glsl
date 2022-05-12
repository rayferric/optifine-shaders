varying vec2 v_TexCoord;

///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

#include "/include/modules/temporal_jitter.glsl"

void main() {
	// Compensate for temporal jitter here
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy + getTemporalOffset();

	gl_Position = ftransform();
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/include/modules/gamma.glsl"
#include "/include/modules/is_inside_rect.glsl"
#include "/include/modules/normalized_mul.glsl"
#include "/include/modules/screen_to_view.glsl"

#define TAA_MIX_FACTOR 0.05

/* DRAWBUFFERS:0 */

// Temporal history mixing

void main() {
	if (gl_FragCoord.x < 1.0 && gl_FragCoord.y < 1.0) {
		// This area is used to store scene brightness

		// colortex0: Temporal History
		gl_FragData[0] = texture2D(colortex0, vec2(0.5 / viewWidth, 0.5 / viewHeight));
		return;
	}

	vec3 viewPos = screenToView(v_TexCoord, depthtex0);
	vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;

	vec3 viewPosPrev = (gbufferPreviousModelView * vec4(worldPos - previousCameraPosition, 1.0)).xyz;
	vec2 screenPosPrev = normalizedMul(gbufferPreviousProjection, viewPosPrev).xy * 0.5 + 0.5;

	vec3 color = texture2D(colortex1, v_TexCoord).xyz;

	vec3 colorMin = color;
	vec3 colorMax = color;

	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			if (x == 0 && y == 0)
				continue;
			
			vec3 sample = texture2D(colortex1, v_TexCoord + vec2(x / viewWidth, y / viewHeight)).xyz;
			colorMin = min(colorMin, sample);
			colorMax = max(colorMax, sample);
		}
	}

	vec3 prevColor = texture2D(colortex0, screenPosPrev).xyz;
	prevColor = gammaToLinear(prevColor);
	prevColor = clamp(prevColor, colorMin, colorMax);

	if(isInsideRect(screenPosPrev, vec2(0.0), vec2(1.0)))
		color = mix(prevColor, color, TAA_MIX_FACTOR);

	// colortex0: Temporal History
	gl_FragData[0].xyz = linearToGamma(color);
	gl_FragData[0].w   = 1.0;
}

#endif // FSH
	