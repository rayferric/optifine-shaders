#include "/src/common/common.glsl"

// Shadow Output

// Shadow Camera Depth of All Entities
uniform sampler2D shadowtex0;

// Shadow Camera Depth of Opaque Entities
uniform sampler2D shadowtex1;

// sRGB Shadow Color
uniform sampler2D shadowcolor0;

// GBuffers Output

// Player Camera Depth of All Entities
uniform sampler2D depthtex0;

// Player Camera Depth of Opaque Entities
uniform sampler2D depthtex1;

// Temporal History
uniform sampler2D colortex0;

// HDR Buffer
uniform sampler2D colortex1;

// Packed Normal
uniform sampler2D colortex2;

// Packed sRGB Albedo RG;
// Packed (sRGB Albedo B + Opacity);
// Packed (Roughness + Metallic)
uniform sampler2D colortex3;

// Gamma-Space Sky Light;
// Gamma-Space Block Light;
// Material ID
uniform sampler2D colortex4;

// Debug Output
uniform sampler2D colortex7;