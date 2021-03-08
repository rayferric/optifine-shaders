#ifndef FRAMEBUFFER_GLSL
#define FRAMEBUFFER_GLSL

#define RG16   0
#define RGB8   0
#define RGB16  0
#define RGB16F 0

const int colortex0Format = RGB16F; // HDR
const int colortex1Format = RGB16;  // Normal XY; Material ID
const int colortex2Format = RGB8;   // Albedo
const int colortex3Format = RGB8;   // Roughness; Metallic; Transmittance
const int colortex4Format = RG16;    // Ambient light

#endif FRAMEBUFFER_GLSL