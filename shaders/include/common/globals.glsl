// Interpreted by OptiFine

// 120.0 is the sweet spot
const float shadowDistance = 180.0;

// Required to work with shadowDistance
const float shadowDistanceRenderMul = 1.0;

// Must be disabled in order to have plain sampler2D shadow textures
const bool shadowHardwareFiltering = false;

// The sun indicates south at noon
const float	sunPathRotation = -45.0;

// Definitions for Advanced Customization

#define SUN_ILLUMINANCE      100.0
#define MOON_ILLUMINANCE     0.01
#define TORCH_ILLUMINANCE    1.0
#define EMISSION_ILLUMINANCE 1.0

#define WATER_ALBEDO_OPACITY vec4(0.6, 0.8, 1.0, 0.25)
#define ICE_ALBEDO           vec3(0.2, 0.6, 1.0)
