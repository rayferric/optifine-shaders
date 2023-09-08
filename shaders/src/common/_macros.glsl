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

#define CONTACT_SHADOW_RAY_LENGTH 0.3 // Ray marching distance
#define CONTACT_SHADOW_BIAS                                                    \
	0.02 // Offset ray origin to avoid self-shading at grazing angles
#define CONTACT_SHADOW_TOLERANCE     0.05 // Max Z difference to score a hit
#define CONTACT_SHADOW_VIEW_DISTANCE 12.0
#define CONTACT_SHADOW_FADE_DISTANCE 2.0

#define SOFT_SHADOW_SAMPLES 4

#define MAX_SSR_ROUGHNESS 0.8

#define SSAO_RADIUS   0.25
#define SSAO_EXPONENT 0.75
#define SSAO_SAMPLES  4

#define WATER_ABSORPTION vec3(1.0, 0.5, 0.5)
#define ICE_ABSORPTION   WATER_ABSORPTION * 2.0
#define HONEY_ABSORPTION vec3(0.1, 0.5, 0.5)

#define UNDERWATER_SKYLIGHT_TINT vec3(0.0, 0.4, 0.5)
#define UNDERWATER_SUNLIGHT_TINT vec3(0.0, 0.2, 0.5)