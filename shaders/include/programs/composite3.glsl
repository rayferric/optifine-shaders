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

// #include "/include/modules/bloom.glsl"
#include "/include/modules/gamma.glsl"
#include "/include/modules/luminance.glsl"
#include "/include/modules/tonemap.glsl"

/* DRAWBUFFERS:1 */

// Reading temporal history and mipmapping for bloom

void main() {
	vec3 color; // LDR temporal history

	// This one pixel stores scene brightness data
	if (gl_FragCoord.x < 1.0 && gl_FragCoord.y < 1.0)
		color = texture2D(colortex0, v_TexCoord + vec2(1.0 / viewWidth, 0)).xyz;
	else
		color = texture2D(colortex0, v_TexCoord).xyz;
	
	color = gammaToLinear(color);
	
	gl_FragData[0].xyz = color;
	gl_FragData[0].w   = 1.0;
}

#endif // FSH
