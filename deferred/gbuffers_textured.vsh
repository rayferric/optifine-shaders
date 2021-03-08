#include "include/common.glsl"

varying vec4 v_Color;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;

void main() {
	v_Color = gl_Color;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	vec2 lightCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy; 
	v_AmbientLight.x = clamp((lightCoord.x * 33.05 / 32.0) - 1.05 / 32.0, 0.0, 1.0); // Torch factor
	v_AmbientLight.y = clamp((lightCoord.y * 33.75 / 32.0) - 1.05 / 32.0, 0.0, 1.0); // Sky factor
	v_AmbientLight = pow(v_AmbientLight, vec2(TORCH_FALLOFF, SKY_FALLOFF));

	gl_Position = ftransform();
}
