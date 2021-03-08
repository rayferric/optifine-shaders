#include "include/common.glsl"
#include "include/atmospherics.glsl"

varying vec2 v_TexCoord;

uniform sampler2D colortex0;

// Dynamic range of this is about 8.0 units (preferred sun energy at exposure 1.0)
vec3 tonemapACES(in vec3 color) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

float computeExposure() {
	float torchEnergy = TORCH_ILLUMINANCE * pow(eyeBrightnessSmooth.x / 240.0, TORCH_FALLOFF * 0.25);
	float skyEnergy = mix(MOON_ILLUMINANCE, SUN_ILLUMINANCE, getDayFactor(32.0, 0.0)) * pow(eyeBrightnessSmooth.y / 240.0, SKY_FALLOFF * 0.5);

	float minExposure = pow(2.0, MIN_EXPOSURE);
	float maxExposure = pow(2.0, MAX_EXPOSURE);

	float exposure = pow(2.0, BASE_EXPOSURE + EXPOSURE) / max(torchEnergy + skyEnergy, EPSILON);
	
	exposure = clamp(exposure, minExposure, maxExposure);
	exposure = mix(exposure, minExposure, isEyeInWater); // Correct the exposure underwater

	if(v_TexCoord.y > 0.9)gl_FragColor.xyz = vec3(exposure / maxExposure);

	return exposure;
}

void main() {
	vec3 color = texture2D(colortex0, v_TexCoord).xyz;

	color = color * computeExposure();
	color = tonemapACES(color);
	color = linearToGamma(color);
	color = pow(color, vec3(GAMMA));
	color = clamp(mix(vec3(luma(color)), color, SATURATION), 0.0, 1.0);
	color = clamp(mix(vec3(0.5), color, CONTRAST), 0.0, 1.0);
	
	if(v_TexCoord.y < 0.9)gl_FragColor.xyz = color;
	gl_FragColor.w   = 1.0;
}
