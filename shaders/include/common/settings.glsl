// Adjustable Settings

// Post-Processing
#define EXPOSURE   0.0 // [-2.0 -1.0 0.0 1.0 2.0]
#define GAMMA      1.0 // [0.5 0.75 1.0 1.25 1.5]
#define SATURATION 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define CONTRAST   1.0 // [0.75 0.875 1.0 1.125 1.25]

// Lighting & Shadows
const int shadowMapResolution =    2048; // [1024 2048 4096]
#define   SOFT_SHADOW_SAMPLES      8     // [4 8 12]
#define   VARIABLE_PENUMBRA_SHADOW
#define   COLORED_SHADOW
#define   CONTACT_SHADOW_SAMPLES   8     // [0 4 8 12]
#define   SUN_TEMPERATURE          5800  // [5200 5500 5800 6100 6400] // 5777 -> https://en.wikipedia.org/wiki/Sun#Photosphere
#define   MOON_TEMPERATURE         4100  // [3500 3800 4100 4400 4700] // 4100 -> https://physics.stackexchange.com/questions/244922/why-does-moonlight-have-a-lower-color-temperature
#define   TORCH_TEMPERATURE        2300  // [1700 2000 2300 2600 2900]
#define   TORCH_FALLOFF            8.0   // [4.0 6.0 8.0 12.0 16.0]
#define   SKY_FALLOFF              8.0   // [1.0 2.0 4.0 6.0 8.0 12.0 16.0]
#define   SSAO_SAMPLES             8     // [0 4 8 16 32] // TODO: Hardcode once TAA is implemented

// Waving
#define WAVING_AMPLITUDE 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define WAVING_FREQUENCY 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define WAVING_WATER
#define WAVING_LAVA
#define WAVING_LEAVES
#define WAVING_FIRE
#define WAVING_SINGLE_PLANTS
#define WAVING_MULTI_PLANTS

// Non-Adjustable Settings

const float shadowDistance          = 120.0; // 120.0 is the sweet spot
const float shadowDistanceRenderMul = 1.0;   // Required to work with shadowDistance
const bool 	shadowHardwareFiltering = false; // Must be disabled in order to have plain sampler2D shadow textures
const float	sunPathRotation	        = -45.0; // The sun indicates south at noon

#define SUN_ILLUMINANCE      128000.0 // https://en.wikipedia.org/wiki/Sunlight#Intensity_in_the_Solar_System
#define MOON_ILLUMINANCE     0.32     // https://en.wikipedia.org/wiki/Moonlight#Illumination
#define TORCH_ILLUMINANCE    8.0
#define EMISSION_ILLUMINANCE 1.0
