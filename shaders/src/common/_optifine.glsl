// OptiFine configuration

// framebuffer formats
// Those MUST be enclosed in a multiline comment, otherwise the parsing will
// fail.
// clang-format off
/*
// GBuffer
const int colortex0Format = RGB8;    // albedo
const int colortex1Format = RG16;    // normal
const int colortex2Format = RGB8;    // roughness, metallic, subsurface
const int colortex3Format = RGB8;    // emissive, occlusion, transmissive
const int colortex4Format = RGB8;    // sky light, block light, ID
// screen textures
const int colortex5Format = R11F_G11F_B10F;  // HDR multipurpose
const int colortex6Format = RGB8;    // temporal history
const int colortex7Format = RGB8;    // debug !IMPORTANT! comment out with // if unused
// shadow textures
const int shadowcolor0Format = RGB8; // shadow color
*/
// clang-format on

const bool  colortex6Clear          = false; // temporal buffer
const float sunPathRotation         = -30.0;
const int   shadowMapResolution     = 2048;  // normal quality
const float shadowDistance          = 256.0; // 16 chunks
const float shadowDistanceRenderMul = 1.0;   // enables shadowDistance
const float ambientOcclusionLevel   = 1.0;   // vanilla AO
// Must be disabled in order to have plain sampler2D shadow textures
const bool shadowHardwareFiltering = true;
