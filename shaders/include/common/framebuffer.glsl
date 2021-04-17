#define RG16   0
#define RGB8   0
#define RGB16  0
#define RGB16F 0

const int colortex0Format = RGB16F;  // Temporal History
const int colortex1Format = RGB16F;  // HDR Buffer
const int colortex2Format = RG16;    // Packed Normal
const int colortex3Format = RGB16;   // Packed sRGB Albedo RG; Packed (sRGB Albedo B + Opacity); Packed (Roughness + Metallic)
const int colortex4Format = RGB8;    // Gamma-Space Sky Light; Gamma-Space Torch Light; Material ID
const int shadowcolor0Format = RGB8; // sRGB Shadow Color

const bool colortex0Clear = false;
