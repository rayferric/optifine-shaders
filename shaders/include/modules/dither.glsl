#ifndef DITHER_GLSL
#define DITHER_GLSL

const mat4 bayer4x4 = mat4(
    vec4( 0.0, 12.0,  3.0, 15.0),
    vec4( 8.0,  4.0, 11.0,  7.0),
    vec4( 2.0, 14.0,  1.0, 13.0),
    vec4(10.0,  6.0,  9.0,  5.0)
) / 16.0;

const float[8][8] bayer8x8 = float[8][8](
	float[8]( 0.0 / 64.0, 32.0 / 64.0,  8.0 / 64.0, 40.0 / 64.0,  2.0 / 64.0, 34.0 / 64.0, 10.0 / 64.0, 42),
	float[8](48.0 / 64.0, 16.0 / 64.0, 56.0 / 64.0, 24.0 / 64.0, 50.0 / 64.0, 18.0 / 64.0, 58.0 / 64.0, 26),
	float[8](12.0 / 64.0, 44.0 / 64.0,  4.0 / 64.0, 36.0 / 64.0, 14.0 / 64.0, 46.0 / 64.0,  6.0 / 64.0, 38),
	float[8](60.0 / 64.0, 28.0 / 64.0, 52.0 / 64.0, 20.0 / 64.0, 62.0 / 64.0, 30.0 / 64.0, 54.0 / 64.0, 22),
	float[8]( 3.0 / 64.0, 35.0 / 64.0, 11.0 / 64.0, 43.0 / 64.0,  1.0 / 64.0, 33.0 / 64.0,  9.0 / 64.0, 41),
	float[8](51.0 / 64.0, 19.0 / 64.0, 59.0 / 64.0, 27.0 / 64.0, 49.0 / 64.0, 17.0 / 64.0, 57.0 / 64.0, 25),
	float[8](15.0 / 64.0, 47.0 / 64.0,  7.0 / 64.0, 39.0 / 64.0, 13.0 / 64.0, 45.0 / 64.0,  5.0 / 64.0, 37),
	float[8](63.0 / 64.0, 31.0 / 64.0, 55.0 / 64.0, 23.0 / 64.0, 61.0 / 64.0, 29.0 / 64.0, 53.0 / 64.0, 21)
);

float dither4x4(float value, vec2 fragCoord, float maxValue) {
    value *= maxValue;
    float floorValue = floor(value);
    
    float delta = value - floorValue;
    float edge = bayer4x4[int(fragCoord.x) % 4][int(fragCoord.y) % 4];
    
    //return edge;
    return (delta < edge ? floorValue : floorValue + 1.0) / maxValue;
}

float dither8x8(float value, vec2 fragCoord, float maxValue) {
    value *= maxValue;
    float floorValue = floor(value);
    
    float delta = value - floorValue;
    float edge = bayer8x8[int(fragCoord.x) % 8][int(fragCoord.y) % 8];
    
    //return edge;
    return (delta < edge ? floorValue : floorValue + 1.0) / maxValue;
}

vec3 dither4x4(vec3 color, vec2 fragCoord, float maxValue) {
    return vec3(
        dither4x4(color.x, fragCoord, maxValue),
        dither4x4(color.y, fragCoord, maxValue),
        dither4x4(color.z, fragCoord, maxValue)
    );
}

vec3 dither8x8(vec3 color, vec2 fragCoord, float maxValue) {
    return vec3(
        dither8x8(color.x, fragCoord, maxValue),
        dither8x8(color.y, fragCoord, maxValue),
        dither8x8(color.z, fragCoord, maxValue)
    );
}

#endif // DITHER_GLSL
