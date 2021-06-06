#ifndef MATERIAL_MASK_GLSL
#define MATERIAL_MASK_GLSL

#include "/include/modules/blocks.glsl"

/**
 * Classifies materials.
 */
struct MaterialMask {
	bool isLit;
	bool isOpaque;
	bool isHand;
};

/**
 * Encodes MaterialMask as a normalized float.
 *
 * @param mask material mask
 *
 * @return 8-bit precise floating-point value in range [0, 1]
 */
float encodeMask(in MaterialMask mask) {
	int i = 0;
	i |= int(mask.isLit)    << 0;
	i |= int(mask.isOpaque) << 1;
	i |= int(mask.isHand)   << 2;
	return i / 255.0; // Minimum 8-bit buffer is required
}

/**
 * Decodes MaterialMask from a normalized float.
 *
 * @param value floating-point value in range [0, 1]
 *
 * @return material mask
 */
MaterialMask decodeMask(in float value) {
	int i = int(value * 255.0 + 0.5);
	MaterialMask mask;
	mask.isLit    = bool((i >> 0) & 1);
	mask.isOpaque = bool((i >> 1) & 1);
	mask.isHand   = bool((i >> 2) & 1);
	return mask;
}

/**
 * Constructs unlit material mask.
 *
 * @return material mask
 */
MaterialMask makeUnlitMask() {
	return MaterialMask(false, false, false);
}

/**
 * Constructs lit material mask for an entity.
 *
 * @param entity        entity data
 *
 * @return material mask
 */
MaterialMask makeLitMask(in vec3 entity) {
	MaterialMask mask;
	mask.isLit    = true;
	mask.isOpaque = isOpaque(entity);
	mask.isHand   = false;
	return mask;
}

#endif // MATERIAL_MASK_GLSL
