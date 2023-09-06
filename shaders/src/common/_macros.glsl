// Advanced settings

#define MIN_EXPOSURE 0.5
#define MAX_EXPOSURE 20.0

#define MIN_LIGHT_FACTOR      0.0
#define BLOCK_LIGHT_LUMINANCE (vec3(1.0, 0.7, 0.4) * 0.5)
#define EMISSIVE_LUMINANCE    0.03

#define AUTO_EXPOSURE_LUMINANCE_SAMPLES 10

// Defines precision gain towards the center of the shadow map in range
// (0.0, 1.0)
#define SHADOW_MAP_DISTORTION_STRENGTH 0.9
// How much the distorted shadow map is stretched to a rectangular shape [1.0,
// inf)
#define SHADOW_MAP_DISTORTION_STRETCH  5.0
