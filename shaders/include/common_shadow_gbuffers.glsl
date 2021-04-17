#include "/include/common/common.glsl"

// Albedo; Opacity
uniform sampler2D texture;

// Normal Map (Y+ Up)
uniform sampler2D normals;

// Perceptual Smoothness; Metallic; Emission
uniform sampler2D specular;
