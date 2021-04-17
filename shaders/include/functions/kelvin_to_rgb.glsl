#ifndef KELVIN_TO_RGB_GLSL
#define KELVIN_TO_RGB_GLSL

/**
 * Approximates RGB tint value of given color temperature in kelvin.
 * Ported from original algorithm by Tanner Helland:
 * https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
 *
 * @param kelvin temperature in kelvin from 1000 up to 40000
 *
 * @return RGB tint value
 */
vec3 kelvinToRGB(in float kelvin) {
	float scaled = clamp(kelvin, 1000.0, 40000.0) * 0.01;
	
	vec3 rgb;
	
	if(scaled <= 66.0) {
		rgb.x = 1.0;
		rgb.y = 0.39008157876 * log(scaled) - 0.63184144378;
	} else {
		rgb.x = 1.29293618606 * pow(scaled - 60.0, -0.1332047592);
		rgb.y = 1.1298908609 * pow(scaled - 60.0, -0.0755148492);
	}
	
	if (scaled >= 66.0) rgb.z = 1.0;
	else if (scaled <= 19.0) rgb.z = 0.0;
	else rgb.z = 0.54320678911 * log(scaled - 10.0) - 1.19625408914;
	
	return clamp(rgb, 0.0, 1.0);
}

#endif // KELVIN_TO_RGB_GLSL
