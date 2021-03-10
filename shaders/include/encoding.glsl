#ifndef ENCODING_GLSL
#define ENCODING_GLSL

/**
 * Converts value from gamma to linear space.
 *
 * @param value value in gamma space
 *
 * @return value in linear space
 */
float gammaToLinear(in float value) {
	return pow(value, 2.2);
}

/**
 * Converts value from linear to gamma space.
 *
 * @param value value in linear space
 *
 * @return value in gamma space
 */
float linearToGamma(in float value) {
	return pow(value, 1.0 / 2.2);
}

/**
 * Converts value from gamma to linear space.
 *
 * @param value value in gamma space
 *
 * @return value in linear space
 */
vec2 gammaToLinear(in vec2 value) {
	return pow(value, vec2(2.2));
}

/**
 * Converts value from linear to gamma space.
 *
 * @param value value in linear space
 *
 * @return value in gamma space
 */
vec2 linearToGamma(in vec2 value) {
	return pow(value, vec2(1.0 / 2.2));
}

/**
 * Converts value from gamma to linear space.
 *
 * @param value value in gamma space
 *
 * @return value in linear space
 */
vec3 gammaToLinear(in vec3 value) {
	return pow(value, vec3(2.2));
}

/**
 * Converts value from linear to gamma space.
 *
 * @param value value in linear space
 *
 * @return value in gamma space
 */
vec3 linearToGamma(in vec3 value) {
	return pow(value, vec3(1.0 / 2.2));
}

/**
 * Encodes normal to a two-component vector using the spheremap transform method.
 * https://aras-p.info/texts/CompactNormalStorage.html
 *
 * @param normal normalized direction vector
 *
 * @return two-component vector value
 */
vec2 encodeNormal(in vec3 normal) {
	return normal.xy / sqrt(normal.z * 8.0 + 8.0) + 0.5;
}

/**
 * Decodes normal from a two-component vector using the spheremap transform method.
 * https://aras-p.info/texts/CompactNormalStorage.html
 *
 * @param value two-component vector value
 *
 * @return normalized direction vector
 */
vec3 decodeNormal(in vec2 value) {
	vec2 fv = value * 4.0 - 2.0;
	float f = dot(fv, fv);
	return vec3(fv * sqrt(1.0 - f * 0.25), 1.0 - f * 0.5);
}

/**
 * Encodes vec3 in a 24-bit floating-point value.
 *
 * @param vec three-component vector in range [0.0, 1.0] on all axes
 *
 * @return floating-point value in range [0.0, 1.0]
 */
float encodeVec3(in vec3 vec) {
	ivec3 ivec = ivec3(vec * 255.0 + 0.5);
	int i = (ivec.x << 16) | (ivec.y << 8) | ivec.z;
	return float(i) / 16777215.0; // / (2 ^ 24 - 1)
}

/**
 * Decodes vec3 from a 24-bit floating-point value.
 *
 * @param value floating-point value in range [0.0, 1.0]
 *
 * @return three-component vector in range [0.0, 1.0] on all axes
 */
vec3 decodeVec3(in float value) {
	int i = int(value * 16777215.0 + 0.5); // * (2 ^ 24 - 1)
	
	int x = i >> 16;
	int y = (i >> 8) & 0xFF;
	int z = i & 0xFF;
	
	return vec3(x, y, z) / 255.0;
}

/**
 * Encodes vec2 in a 16-bit floating-point value.
 *
 * @param vec two-component vector in range [0.0, 1.0] on all axes
 *
 * @return floating-point value in range [0.0, 1.0]
 */
float encodeVec2(in vec2 vec) {
	ivec2 ivec = ivec2(vec * 255.0 + 0.5);
	int i = (ivec.x << 8) | ivec.y;
	return float(i) / 65535.0; // / (2 ^ 16 - 1)
}

/**
 * Decodes vec2 from a 16-bit floating-point value.
 *
 * @param value floating-point value in range [0.0, 1.0]
 *
 * @return two-component vector in range [0.0, 1.0] on all axes
 */
vec2 decodeVec2(in float value) {
	int i = int(value * 65535.0 + 0.5); // * (2 ^ 16 - 1)

	int x = i >> 8;
	int y = i & 0xFF;

	return vec2(x, y) / 255.0;
}

#endif // ENCODING_GLSL
