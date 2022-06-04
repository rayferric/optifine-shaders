// Block ID (X); Render Type (Y)
attribute vec3 mc_Entity;

// UV coordinate of the middle of the whole face
attribute vec2 mc_midTexCoord;

// Tangent Vector (XYZ); Handedness (W)
attribute vec4 at_tangent;

// Vertex offset to previous frame
attribute vec3 at_velocity;

// Offset to block center in (1/64) m units
attribute vec3 at_midBlock;
