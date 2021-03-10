#ifndef FRAMEBUFFER_GLSL
#define FRAMEBUFFER_GLSL

// This file is intended to be included only by common.glsl

#define RG16   0
#define RGB8   0
#define RGB16  0
#define RGB16F 0

const int colortex0Format = RGB16F;  // HDR
const int colortex1Format = RG16;    // Packed Normal
const int colortex2Format = RGB16;   // Packed sRGB Albedo RG; Packed (sRGB Albedo B + Opacity); Packed (Roughness + Metallic)
const int colortex3Format = RGB8;    // Gamma-Space Sky Light; Gamma-Space Torch Light; Material ID
const int shadowcolor0Format = RGB8; // sRGB Shadow Color

#endif // FRAMEBUFFER_GLSL
