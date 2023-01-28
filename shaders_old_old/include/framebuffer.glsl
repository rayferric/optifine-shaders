#define RG16   0
#define RGB8   0
#define RGB16  0
#define RGB16F 0
#define RGBA32F 0

const int colortex0Format = RGB16F;  // HDR 
const int colortex1Format = RGB16;   // Normal XY; Material ID
const int colortex2Format = RGB16;   // Albedo RG; (Albedo B + Roughness); (Metallic + Transmittance)
const int colortex3Format = RG16;    // Ambient light
const int colortex4Format = RGB8;    // Bloom bright-pass
const int colortex5Format = RGBA32F; // TAA data: Color; Depth
// colortex6 -> Moon texture
// colortex7 -> Color correction LUT

const bool colortex5Clear = false;
const vec4 colortex5ClearColor = vec4(0.0);