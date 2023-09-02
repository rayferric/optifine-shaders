// clang-format off

// https://github.com/sp614x/optifine/blob/master/OptiFineDoc/doc/shaders.txt

in vec3  vaPosition;     // position (x, y, z)                          1.17+, for terrain it is relative to the chunk origin, see "chunkOffset"
in vec4  vaColor;        // color (r, g, b, a)                          1.17+
in vec2  vaUV0;          // texture (u, v)                              1.17+
in ivec2 vaUV1;          // overlay (u, v)                              1.17+
in ivec2 vaUV2;          // lightmap (u, v)                             1.17+
in vec3  vaNormal;       // normal (x, y, z)                            1.17+
in vec3  mc_Entity;      // xy = blockId, renderType                    "blockId" is used only for blocks specified in "block.properties"
in vec2  mc_midTexCoord; // st = midTexU, midTexV                       Sprite middle UV coordinates
in vec4  at_tangent;     // xyz = tangent vector, w = handedness
in vec3  at_velocity;    // vertex offset to previous frame             In view space, only for entities and block entities
in vec3  at_midBlock;    // offset to block center in 1/64m units       Only for blocks

// clang-format on
