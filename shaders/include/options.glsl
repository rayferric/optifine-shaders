#ifndef OPTIONS_GLSL
#define OPTIONS_GLSL

// This file is intended to be included only by common.glsl

// Adjustable Options

// Post-Processing
#define EXPOSURE   0.0 // [-2.0 -1.0 0.0 1.0 2.0]
#define GAMMA      1.0 // [0.5 0.75 1.0 1.25 1.5]
#define SATURATION 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define CONTRAST   1.0 // [0.75 0.875 1.0 1.125 1.25]

// Lighting & Shadows
const int shadowMapResolution = 2048; // [512 1024 2048 3072 4096]
#define   SHADOW_FILTER
#define   COLORED_SHADOWS
#define   SUN_TEMPERATURE       5800  // [5200 5500 5800 6100 6400] // 5777 -> https://en.wikipedia.org/wiki/Sun#Photosphere
#define   MOON_TEMPERATURE      4100  // [3500 3800 4100 4400 4700] // 4100 -> https://physics.stackexchange.com/questions/244922/why-does-moonlight-have-a-lower-color-temperature
#define   TORCH_TEMPERATURE     2300  // [1700 2000 2300 2600 2900]
#define   TORCH_FALLOFF         8.0   // [4.0 6.0 8.0 12.0 16.0]
#define   SKY_FALLOFF           8.0   // [1.0 2.0 4.0 6.0 8.0 12.0 16.0]

// Non-Adjustable Options

const float shadowDistance          = 120.0; // 120.0 is the sweet spot
const float shadowDistanceRenderMul = 1.0;   // Required to work with shadowDistance
const bool 	shadowHardwareFiltering = true;  // Must be enabled in order to use shadow2D()
const float	sunPathRotation	        = -45.0; // The sun indicates south at noon
const float eyeBrightnessHalflife   = 1.0;   // Eye adaptation speed in seconds
const float ambientOcclusionLevel   = 0.0;

#define MIN_EXPOSURE  -16.0 // Lowest exposure value reachable by the camera in EV
#define MAX_EXPOSURE  0.0   // Highest exposure value reachable by the camera in EV

#define SUN_ILLUMINANCE      128000.0 // 128000.0 -> https://en.wikipedia.org/wiki/Sunlight#Intensity_in_the_Solar_System
#define MOON_ILLUMINANCE     0.32     // 0.32 -> https://en.wikipedia.org/wiki/Moonlight#Illumination
#define TORCH_ILLUMINANCE    8.0
#define EMISSION_ILLUMINANCE 1.0

#define SUN_ENERGY   (blackbody(SUN_TEMPERATURE)   * SUN_ILLUMINANCE)
#define MOON_ENERGY  (blackbody(MOON_TEMPERATURE)  * MOON_ILLUMINANCE)
#define TORCH_ENERGY (blackbody(TORCH_TEMPERATURE) * TORCH_ILLUMINANCE)

#endif // OPTIONS_GLSL
