#ifndef PACK_GLSL
#define PACK_GLSL

/**
 * @brief Encodes normal to a two-component vector using the sphere-map
 * transform method. https://aras-p.info/texts/CompactNormalStorage.html
 *
 * @param normal normalized direction vector
 *
 * @return two-component vector value
 */
vec2 packNormal(in vec3 normal) {
	return normal.xy / sqrt(normal.z * 8.0 + 8.0) + 0.5;
}

/**
 * @brief Decodes normal from a two-component vector using the sphere-map
 * transform method. https://aras-p.info/texts/CompactNormalStorage.html
 *
 * @param value two-component vector value
 *
 * @return normalized direction vector
 */
vec3 unpackNormal(in vec2 value) {
	vec2  fv = value * 4.0 - 2.0;
	float f  = dot(fv, fv);
	return vec3(fv * sqrt(1.0 - f * 0.25), 1.0 - f * 0.5);
}

/**
 * @brief Encodes vec3 in a 24-bit floating-point value.
 *
 * @param vec three-component vector in range [0.0, 1.0] on all axes
 *
 * @return floating-point value in range [0.0, 1.0]
 */
float pack8BitVec3(in vec3 vec) {
	uvec3 uvec = uvec3(vec * 255.0 + 0.5);
	uint  i    = (uvec.x << 16) | (uvec.y << 8) | uvec.z;
	return float(i) / 16777215.0; // / (2 ^ 24 - 1)
}

/**
 * @brief Decodes vec3 from a 24-bit floating-point value.
 *
 * @param value floating-point value in range [0.0, 1.0]
 *
 * @return three-component vector in range [0.0, 1.0] on all axes
 */
vec3 unpack8BitVec3(in float value) {
	uint i = uint(value * 16777215.0 + 0.5); // * (2 ^ 24 - 1)

	uint x = i >> 16;
	uint y = (i >> 8) & 0xFFU;
	uint z = i & 0xFFU;

	return vec3(x, y, z) / 255.0;
}

/**
 * @brief Encodes vec2 in a 16-bit floating-point value.
 *
 * @param vec two-component vector in range [0.0, 1.0] on all axes
 *
 * @return floating-point value in range [0.0, 1.0]
 */
float pack8BitVec2(in vec2 vec) {
	uvec2 uvec = uvec2(vec * 255.0 + 0.5);
	uint  i    = (uvec.x << 8) | uvec.y;
	return float(i) / 65535.0; // / (2 ^ 16 - 1)
}

/**
 * @brief Decodes vec2 from a 16-bit floating-point value.
 *
 * @param value floating-point value in range [0.0, 1.0]
 *
 * @return two-component vector in range [0.0, 1.0] on all axes
 */
vec2 unpack8BitVec2(in float value) {
	uint i = uint(value * 65535.0 + 0.5); // * (2 ^ 16 - 1)

	uint x = i >> 8;
	uint y = i & 0xFFU;

	return vec2(x, y) / 255.0;
}

/**
 * @brief Encodes vec2 in a 32-bit floating-point value.
 *
 * @param vec two-component vector in range [0.0, 1.0] on all axes
 *
 * @return floating-point value in range [0.0, 1.0]
 */
float pack16BitVec2(in vec2 vec) {
	uvec2 uvec = uvec2(vec * 65535.0 + 0.5);
	uint  i    = (uvec.x << 16) | uvec.y;
	return float(i) / 4294967295.0; // / (2 ^ 32 - 1)
}

/**
 * @brief Encodes vec2 in a 32-bit floating-point value.
 *
 * @param vec two-component vector in range [0.0, 1.0] on all axes
 *
 * @return floating-point value in range [0.0, 1.0]
 */
vec2 unpack16BitVec2(in float value) {
	uint i = uint(value * 4294967295.0 + 0.5); // * (2 ^ 16 - 1)

	uint x = i >> 8;
	uint y = i & 0xFFU;

	return vec2(x, y) / 255.0;
}

#endif // PACK_GLSL
