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
 * Encodes vec3 in a 24-bit floating-point value.
 *
 * @param normal    three-component vector in range <0.0, 1.0> on all axes
 *
 * @return    floating-point value in range <0.0, 1.0>
 */
float encodeRGB8(in vec3 rgb) {
    ivec3 irgb = ivec3(rgb * 255.0 + 0.5);
	int i = (irgb.x << 16) | (irgb.y << 8) | irgb.z;
    return float(i) / 16777215.0; // / (2 ^ 24 - 1)
}

/**
 * Decodes vec3 from a 24-bit floating-point value.
 *
 * @param value    floating-point value in range <0.0, 1.0>
 *
 * @return    three-component vector in range <0.0, 1.0> on all axes
 */
vec3 decodeRGB8(in float value) {
    int i = int(value * 16777215.0 + 0.5);
	i = clamp(i - 2, 0, 0xFFFFFF); // Just to make sure there are no precision errors
    
    int r = i >> 16;
    int g = (i >> 8) & 0xFF;
    int b = i & 0xFF;
    
    return clamp(vec3(r, g, b) / 255.0, 0.0, 1.0);
}

float encodeVec2(in vec2 vector) {
	ivec2 ivector = ivec2(vector * 255.0 + 0.5);
	int x = ivector.x;
	int y = ivector.y * 256;
	return float(x + y) / 65535.0;
}

vec2 decodeVec2(in float value) {
	int i = int(value * 65535.0 + 0.5); 
	int x = i % 256;
	int y = i / 256;
	return vec2(x, y) / 255.0;
}