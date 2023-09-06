#ifndef DITHER_GLSL
#define DITHER_GLSL

// clang-format off
const float[8][8] bayer8X8 = float[8][8](
	float[8]( 0.0 / 64.0, 48.0 / 64.0, 12.0 / 64.0, 60.0 / 64.0,  3.0 / 64.0, 51.0 / 64.0, 15.0 / 64.0, 63.0 / 64.0),
	float[8](32.0 / 64.0, 16.0 / 64.0, 44.0 / 64.0, 28.0 / 64.0, 35.0 / 64.0, 19.0 / 64.0, 47.0 / 64.0, 31.0 / 64.0),
	float[8]( 8.0 / 64.0, 56.0 / 64.0,  4.0 / 64.0, 52.0 / 64.0, 11.0 / 64.0, 59.0 / 64.0,  7.0 / 64.0, 55.0 / 64.0),
	float[8](40.0 / 64.0, 24.0 / 64.0, 36.0 / 64.0, 20.0 / 64.0, 43.0 / 64.0, 27.0 / 64.0, 39.0 / 64.0, 23.0 / 64.0),
	float[8]( 2.0 / 64.0, 50.0 / 64.0, 14.0 / 64.0, 62.0 / 64.0,  1.0 / 64.0, 49.0 / 64.0, 13.0 / 64.0, 61.0 / 64.0),
	float[8](34.0 / 64.0, 18.0 / 64.0, 46.0 / 64.0, 30.0 / 64.0, 33.0 / 64.0, 17.0 / 64.0, 45.0 / 64.0, 29.0 / 64.0),
	float[8](10.0 / 64.0, 58.0 / 64.0,  6.0 / 64.0, 54.0 / 64.0,  9.0 / 64.0, 57.0 / 64.0,  5.0 / 64.0, 53.0 / 64.0),
	float[8](42.0 / 64.0, 26.0 / 64.0, 38.0 / 64.0, 22.0 / 64.0, 41.0 / 64.0, 25.0 / 64.0, 37.0 / 64.0, 21.0 / 64.0)
);
// clang-format on

// TODO: docs
float dither8X8(in float value, in ivec2 pixelPos, in int quantizedMax) {
	value            *= float(quantizedMax);
	float floorValue  = floor(value);

	float delta = value - floorValue;
	float edge  = bayer8X8[pixelPos.x % 8][pixelPos.y % 8];

	return (floorValue + step(edge, delta)) / float(quantizedMax);
}

// TODO: docs
vec2 dither8X8(in vec2 value, in ivec2 pixelPos, in int quantizedMax) {
	return vec2(
	    dither8X8(value.x, pixelPos, quantizedMax),
	    dither8X8(value.y, pixelPos, quantizedMax)
	);
}

// TODO: docs
vec3 dither8X8(in vec3 value, in ivec2 pixelPos, in int quantizedMax) {
	return vec3(
	    dither8X8(value.x, pixelPos, quantizedMax),
	    dither8X8(value.y, pixelPos, quantizedMax),
	    dither8X8(value.z, pixelPos, quantizedMax)
	);
}

#endif // DITHER_GLSL
