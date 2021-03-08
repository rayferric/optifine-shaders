#ifndef ENCODING_GLSL
#define ENCODING_GLSL

/**
 * Decodes linear color from sRGB value.
 *
 * @param color    color in sRGB space
 *
 * @return    color in linear space
 */
vec3 gammaToLinear(in vec3 color) {
	return pow(color, vec3(2.2));
}

/**
 * Encodes linear color to an sRGB value.
 *
 * @param color    color in linear space
 *
 * @return    color in sRGB space
 */
vec3 linearToGamma(in vec3 color) {
	return pow(color, vec3(1.0 / 2.2));
}

/**
 * Encodes normal to a two-component vector value using the spheremap transform method.
 * https://aras-p.info/texts/CompactNormalStorage.html
 *
 * @param normal    normalized direction vector
 *
 * @return    two-component vector value
 */
vec2 encodeNormal(in vec3 normal) {
    return normal.xy / sqrt(normal.z * 8.0 + 8.0) + 0.5;
}

/**
 * Decodes normal from two-component vector value using the spheremap transform method.
 * https://aras-p.info/texts/CompactNormalStorage.html
 *
 * @param value    two-component vector value
 *
 * @return    direction vector
 */
vec3 decodeNormal(in vec2 value) {
	vec2 fv = value * 4.0 - 2.0;
    float f = dot(fv, fv);
    return vec3(fv * sqrt(1.0 - f * 0.25), 1.0 - f * 0.5);
}

/**
 * Approximates RGB tint value of given color temperature in Kelvin.
 * Ported from the original algorithm by Tanner Helland.
 * https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
 *
 * @param kelvin    temperature in Kelvin from 1000 up to 40000
 *
 * @return    RGB value
 */
vec3 blackbody(in float kelvin) {
    kelvin = clamp(kelvin, 1000.0, 40000.0) * 0.01;
    
    vec3 rgb;
    
    if(kelvin <= 66.0) {
        rgb.x = 1.0;
        rgb.y = 0.39008157876 * log(kelvin) - 0.63184144378;
    } else {
        rgb.x = 1.29293618606 * pow(kelvin - 60.0, -0.1332047592);
        rgb.y = 1.1298908609 * pow(kelvin - 60.0, -0.0755148492);
	}
    
    if(kelvin >= 66.0)rgb.z = 1.0;
    else if(kelvin <= 19.0)rgb.z = 0.0;
    else rgb.z = 0.54320678911 * log(kelvin - 10.0) - 1.19625408914;
    
	return clamp(rgb, 0.0, 1.0);
}

#endif // ENCODING_GLSL