#include "include/common.glsl"
#include "include/material.glsl"

varying vec4 v_Color;
varying vec2 v_TexCoord;

uniform sampler2D texture;

void main() {
	vec4 albedoAlpha = texture2D(texture, v_TexCoord) * v_Color;
	float alpha = albedoAlpha.w;
	vec3 albedo = gammaToLinear(albedoAlpha.xyz) * alpha;

	// HDR
	gl_FragData[0].xyz = albedo; // TODO Fix stars, sun, moon, everything
	gl_FragData[0].w   = alpha; // Low alpha (mostly) eliminates stars during night (preasumably additive blending is involved)
	// Normal XY; Material ID
	// gl_FragData[1].xy  = vec2(0.0);
	gl_FragData[1].z   = encodeMask(genUnlitMask());
	gl_FragData[1].w   = 1.0;
	// Albedo
	// gl_FragData[2].xyz = vec3(0.0);
	// gl_FragData[2].w   = 1.0;
	// Roughness; Metallic; Transmittance
	// gl_FragData[3].xyz = vec3(0.0);
	// gl_FragData[3].w   = 1.0;
	// Ambient light
	// gl_FragData[4].xyz = vec3(0.0);
	// gl_FragData[4].w   = 1.0;
}
