#ifndef TONEMAP_GLSL
#define TONEMAP_GLSL

// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
const mat3 acesIn = mat3(
	0.59719, 0.07600, 0.02840,
	0.35458, 0.90834, 0.13383,
	0.04823, 0.01566, 0.83777
);

// ODT_SAT => XYZ => D60_2_D65 => sRGB
const mat3 acesOut = mat3(
	 1.60475, -0.10208, -0.00327,
	-0.53108,  1.10813, -0.07276,
	-0.07367, -0.00605,  1.07602
);

vec3 rttAndOdtFit(in vec3 color) {
	vec3 a = color * (color + 0.0245786) - 0.000090537;
	vec3 b = color * (0.983729 * color + 0.4329510) + 0.238081;
	return a / b;
}

/**
 * Transforms HDR color to LDR using ACES operator.
 * Ported from original source by Stephen Hill:
 * https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
 * https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ToneMapping.hlsl
 *
 * @param hdr HDR color
 *
 * @return LDR color
 */
vec3 tonemapAces(in vec3 color) {
	color *= 1.8;
	color = acesIn * color;
	color = rttAndOdtFit(color);
	color = acesOut * color;
	return clamp(color, 0.0, 1.0);
}

/**
 * Transforms HDR color to LDR using ACES operator approximation.
 * Ported from original source by Krzysztof Narkowicz:
 * https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve
 *
 * @param hdr HDR color
 *
 * @return LDR color
 */
vec3 tonemapApproxAces(in vec3 hdr) {
	const float a = 2.51;
	const float b = 0.03;
	const float c = 2.43;
	const float d = 0.59;
	const float e = 0.14;
	return clamp((hdr * (a * hdr + b)) / (hdr * (c * hdr + d) + e), 0.0, 1.0);
}

/**
 * Transforms HDR value to LDR using modified Reinhard
 * operator that mimics ACES curve with infinite white point.
 *
 * @param hdr   HDR value
 * @param ratio positive precision distribution ratio - higher values give more precision to larger HDR values
 *
 * @return LDR value
 */
float tonemapCustomReinhard(in float hdr, in float ratio) {
	return hdr / (hdr + ratio);
}

/**
 * Transforms LDR value to HDR using inverse of modified Reinhard
 * operator that mimics ACES curve with infinite white point.
 *
 * @param hdr   LDR value
 * @param ratio ratio value used during Reinhard tonemapping
 *
 * @return HDR value
 */
float tonemapCustomReinhardInverse(in float ldr, in float ratio) {
	return (ratio * ldr) / (1.0 - ldr);
}

/**
 * Transforms HDR color to LDR using modified Reinhard
 * operator that mimics ACES curve with infinite white point.
 *
 * @param hdr HDR color
 *
 * @return LDR color
 */
vec3 tonemapAcesReinhard(in vec3 hdr) {
	return vec3(
		tonemapCustomReinhard(hdr.x, 0.25),
		tonemapCustomReinhard(hdr.y, 0.25),
		tonemapCustomReinhard(hdr.z, 0.25)
	);
}

/**
 * Transforms LDR color to HDR using inverse of modified Reinhard
 * operator that mimics ACES curve with infinite white point.
 *
 * @param hdr LDR color
 *
 * @return HDR color
 */
vec3 tonemapAcesReinhardInverse(in vec3 ldr) {
	return vec3(
		tonemapCustomReinhardInverse(ldr.x, 0.25),
		tonemapCustomReinhardInverse(ldr.y, 0.25),
		tonemapCustomReinhardInverse(ldr.z, 0.25)
	);
}

#endif // TONEMAP_GLSL
