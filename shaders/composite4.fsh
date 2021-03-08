#version 120
#include "include/common.glsl"
#include "include/bloom.glsl"

#define TAA_FRAMES 15

varying vec2 v_TexCoord;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;

/**
 * Transforms HDR color to LDR space using the ACES operator.
 * Ported from the original source:
 * https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve
 * For a more accurate curve, head to:
 * https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
 *
 * @param color    HDR color
 *
 * @return    LDR color
 */
vec3 tonemapACES(in vec3 color) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

mat4 inverse(in mat4 m) {
  float
      a00 = m[0][0], a01 = m[0][1], a02 = m[0][2], a03 = m[0][3],
      a10 = m[1][0], a11 = m[1][1], a12 = m[1][2], a13 = m[1][3],
      a20 = m[2][0], a21 = m[2][1], a22 = m[2][2], a23 = m[2][3],
      a30 = m[3][0], a31 = m[3][1], a32 = m[3][2], a33 = m[3][3],

      b00 = a00 * a11 - a01 * a10,
      b01 = a00 * a12 - a02 * a10,
      b02 = a00 * a13 - a03 * a10,
      b03 = a01 * a12 - a02 * a11,
      b04 = a01 * a13 - a03 * a11,
      b05 = a02 * a13 - a03 * a12,
      b06 = a20 * a31 - a21 * a30,
      b07 = a20 * a32 - a22 * a30,
      b08 = a20 * a33 - a23 * a30,
      b09 = a21 * a32 - a22 * a31,
      b10 = a21 * a33 - a23 * a31,
      b11 = a22 * a33 - a23 * a32,

      det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

  return mat4(
      a11 * b11 - a12 * b10 + a13 * b09,
      a02 * b10 - a01 * b11 - a03 * b09,
      a31 * b05 - a32 * b04 + a33 * b03,
      a22 * b04 - a21 * b05 - a23 * b03,
      a12 * b08 - a10 * b11 - a13 * b07,
      a00 * b11 - a02 * b08 + a03 * b07,
      a32 * b02 - a30 * b05 - a33 * b01,
      a20 * b05 - a22 * b02 + a23 * b01,
      a10 * b10 - a11 * b08 + a13 * b06,
      a01 * b08 - a00 * b10 - a03 * b06,
      a30 * b04 - a31 * b02 + a33 * b00,
      a21 * b02 - a20 * b04 - a23 * b00,
      a11 * b07 - a10 * b09 - a12 * b06,
      a00 * b09 - a01 * b07 + a02 * b06,
      a31 * b01 - a30 * b03 - a32 * b00,
      a20 * b03 - a21 * b01 + a22 * b00) / det;
}

void main() {
	float depth = texture2D(depthtex0, v_TexCoord).x;

	vec3 fragPos = getFragPos(depth, v_TexCoord);
	vec3 worldPos = (gbufferModelViewInverse * vec4(fragPos, 1.0)).xyz + cameraPosition;
	vec3 fragPosPrev = (gbufferPreviousModelView * vec4(worldPos - previousCameraPosition, 1.0)).xyz;
	vec4 projPosPrev = gbufferPreviousProjection * vec4(fragPosPrev, 1.0);
	projPosPrev.xyz /= projPosPrev.w;
	vec2 sampleCoord = projPosPrev.xy * 0.5 + 0.5;

	vec4 taaData = texture2D(colortex5, sampleCoord);
	vec3 prevColor = gammaToLinear(taaData.xyz);
	float prevDepth = pow(taaData.w, 1.0 / 8.0);

	vec3 worldPosPrev = (inverse(gbufferPreviousModelView) * vec4(getFragPos(prevDepth, v_TexCoord), 1.0)).xyz + previousCameraPosition;
	
	vec3 currentColor = texture2D(colortex0, v_TexCoord).xyz;
	currentColor += getBloom(colortex4, v_TexCoord);
	currentColor = tonemapACES(currentColor);

	vec3 color;
	if(sampleCoord.x < 0.0 || 1.0 < sampleCoord.x) {
		color = currentColor;
	} else if(sampleCoord.y < 0.0 || 1.0 < sampleCoord.y) {
		color = currentColor;
	} else if(distance(worldPosPrev, worldPos) > 0.1) {
		color = currentColor;
	} else { 
		color = (currentColor + prevColor * float(TAA_FRAMES)) / float(TAA_FRAMES + 1);
	}

	color = currentColor;

	// Mipmapped HDR
	gl_FragData[0].xyz = linearToGamma(color);
	gl_FragData[0].w = pow(depth, 8.0);
}

/* DRAWBUFFERS:5 */