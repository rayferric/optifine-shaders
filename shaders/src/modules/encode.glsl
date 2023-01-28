#ifndef ENCODE_GLSL
#define ENCODE_GLSL

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
 * Encodes vec3 in a 24-bit floating-pouint value.
 *
 * @param vec three-component vector in range [0.0, 1.0] on all axes
 *
 * @return floating-pouint value in range [0.0, 1.0]
 */
float encode8BitVec3(in vec3 vec) {
	uvec3 uvec = uvec3(vec * 255.0 + 0.5);
	uint i = (uvec.x << 16) | (uvec.y << 8) | uvec.z;
	return float(i) / 16777215.0; // / (2 ^ 24 - 1)
}

/**
 * Decodes vec3 from a 24-bit floating-pouint value.
 *
 * @param value floating-pouint value in range [0.0, 1.0]
 *
 * @return three-component vector in range [0.0, 1.0] on all axes
 */
vec3 decode8BitVec3(in float value) {
	uint i = uint(value * 16777215.0 + 0.5); // * (2 ^ 24 - 1)
	
	uint x = i >> 16;
	uint y = (i >> 8) & 0xFFU;
	uint z = i & 0xFFU;
	
	return vec3(x, y, z) / 255.0;
}

/**
 * Encodes vec2 in a 16-bit floating-pouint value.
 *
 * @param vec two-component vector in range [0.0, 1.0] on all axes
 *
 * @return floating-pouint value in range [0.0, 1.0]
 */
float encode8BitVec2(in vec2 vec) {
	uvec2 uvec = uvec2(vec * 255.0 + 0.5);
	uint i = (uvec.x << 8) | uvec.y;
	return float(i) / 65535.0; // / (2 ^ 16 - 1)
}

/**
 * Decodes vec2 from a 16-bit floating-pouint value.
 *
 * @param value floating-pouint value in range [0.0, 1.0]
 *
 * @return two-component vector in range [0.0, 1.0] on all axes
 */
vec2 decode8BitVec2(in float value) {
	uint i = uint(value * 65535.0 + 0.5); // * (2 ^ 16 - 1)

	uint x = i >> 8;
	uint y = i & 0xFFU;

	return vec2(x, y) / 255.0;
}

/**
 * Encodes vec2 in a 32-bit floating-pouint value.
 *
 * @param vec two-component vector in range [0.0, 1.0] on all axes
 *
 * @return floating-pouint value in range [0.0, 1.0]
 */
float encode16BitVec2(in vec2 vec) {
	uvec2 uvec = uvec2(vec * 65535.0 + 0.5);
	uint i = (uvec.x << 16) | uvec.y;
	return float(i) / 4294967295.0; // / (2 ^ 32 - 1)
}

/**
 * Encodes vec2 in a 32-bit floating-pouint value.
 *
 * @param vec two-component vector in range [0.0, 1.0] on all axes
 *
 * @return floating-pouint value in range [0.0, 1.0]
 */
vec2 decode16BitVec2(in float value) {
	uint i = uint(value * 4294967295.0 + 0.5); // * (2 ^ 16 - 1)

	uint x = i >> 8;
	uint y = i & 0xFFU;

	return vec2(x, y) / 255.0;
}

#endif // ENCODE_GLSL
