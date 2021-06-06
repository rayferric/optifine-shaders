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

#include "include/modules/encode.glsl"
#include "include/modules/gamma.glsl"
#include "include/modules/material_mask.glsl"
#include "include/modules/pbr.glsl"
#include "include/modules/screen_to_view.glsl"
#include "include/modules/shadow.glsl"
#include "include/modules/ssao.glsl"

void main() {
	vec3 hdr = texture2D(colortex1, v_TexCoord).xyz;
	hdr /= 25000.0;

	vec3 color = tonemapACES(hdr);
	color = pow(color, vec3(GAMMA));
	color = clamp(mix(vec3(luminance(color)), color, SATURATION), 0.0, 1.0);
	color = clamp(mix(vec3(0.5), color, CONTRAST), 0.0, 1.0);
	
	gl_FragColor.xyz = linearToGamma(color);
	gl_FragColor.w   = 1.0;
}

#endif // FSH
