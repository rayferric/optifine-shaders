#ifndef MATERIAL_MASK_GLSL
#define MATERIAL_MASK_GLSL

#include "/src/modules/blocks.glsl"

/**
 * @brief Classifies materials.
 */
struct MaterialMask {
	bool isLit;
	bool isEmissive;
	bool isTranslucent;
	bool isPlayer;
	bool isFoliage;
};

/**
 * @brief Encodes MaterialMask as a normalized float.
 *
 * @param mask material mask
 *
 * @return 8-bit precise floating-point value in range [0, 1]
 */
float encodeMask(in MaterialMask mask) {
	int i = 0;
	i     |= int(mask.isLit) << 0;
	i     |= int(mask.isEmissive) << 1;
	i     |= int(mask.isTranslucent) << 2;
	i     |= int(mask.isPlayer) << 3;
	i     |= int(mask.isFoliage) << 4;
	return i / 255.0; // Minimum 8-bit buffer is required
}

/**
 * @brief Decodes MaterialMask from a normalized float.
 *
 * @param value floating-point value in range [0, 1]
 *
 * @return material mask
 */
MaterialMask decodeMask(in float value) {
	int          i = int(value * 255.0 + 0.5);
	MaterialMask mask;
	mask.isLit         = bool((i >> 0) & 1);
	mask.isEmissive    = bool((i >> 1) & 1);
	mask.isTranslucent = bool((i >> 2) & 1);
	mask.isPlayer      = bool((i >> 3) & 1);
	mask.isFoliage     = bool((i >> 4) & 1);
	return mask;
}

#endif // MATERIAL_MASK_GLSL
