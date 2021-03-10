#ifndef MATERIAL_GLSL
#define MATERIAL_GLSL

#include "options.glsl"

#define WATER_ALBEDO_OPACITY vec4(0.6, 0.8, 1.0, 0.25)
#define ICE_ALBEDO           vec3(0.2, 0.6, 1.0)

/**
 * Tells whether the entity is plant.
 *
 * @param entity entity data
 *
 * @return true if plant
 */
bool isPlant(in vec3 entity) {
	int id = int(entity.x + 0.5);
	return 
			id == 6 ||
			id == 30 ||
			id == 31 ||
			id == 32 ||
			id == 37 ||
			id == 38 ||
			id == 39 ||
			id == 40 ||
			id == 51 ||
			id == 59 ||
			id == 83 ||
			id == 104 ||
			id == 105 ||
			id == 115 ||
			id == 141 ||
			id == 142 ||
			id == 175 ||
			id == 207;
}

/**
 * Tells whether the entity is water.
 *
 * @param entity entity data
 *
 * @return true if water
 */
bool isWater(in vec3 entity) {
	int id = int(entity.x + 0.5);
	// Flowing Water; Still Water
	return id == 8 || id == 9;
}

/**
 * Tells whether the entity is ice.
 *
 * @param entity entity data
 *
 * @return true if ice
 */
bool isIce(in vec3 entity) {
	int id = int(entity.x + 0.5);
	// Ice
	return id == 79;
}

/**
 * Tells whether the entity is stained glass.
 *
 * @param entity entity data
 *
 * @return true if stained glass
 */
bool isStainedGlass(in vec3 entity) {
	int id = int(entity.x + 0.5);
	// Stained Glass; Stained Glass Pane
	return id == 95 || id == 160;
}

/**
 * Tells whether the entity is translucent.
 *
 * @param entity entity data
 *
 * @return true if water, ice or stained glass
 */
bool isTranslucent(in vec3 entity) {
	int id = int(entity.x + 0.5);
	// Flowing Water; Still Water; Ice; Stained Glass; Stained Glass Pane
	return id == 8 || id == 9 || id == 79 || id == 95 || id == 160;
}

/**
 * Encapsulates special material properties.
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
 * @return floating-point value in range [0, 1]
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
	mask.isOpaque = !isTranslucent(entity);
	mask.isHand   = false;
	return mask;
}

/**
 * Remaps albedo and opacity values for an entity.
 *
 * @param albedoOpacity albedo (xyz) + opacity (w)
 * @param entity        entity data
 *
 * @return new albedo (xyz) + new opacity (w)
 */
vec4 remapEntityAlbedoOpacity(in vec4 albedoOpacity, in vec3 entity) {
	return isWater(entity) ? WATER_ALBEDO_OPACITY : albedoOpacity;
}

/**
 * Remaps PBR values for an entity.
 *
 * @param RME    roughness (x) + metallic (y) + emission (z)
 * @param entity entity data
 *
 * @return new roughness (x) + new metallic (y) + new emission (z)
 */
vec3 remapEntityRME(in vec3 RME, in vec3 entity) {
	RME.y = 0.0; // Better not to have many metallic surfaces

	int id = int(entity.x + 0.5);
	if(isWater(entity)) {
		RME = vec3(0.0, 1.0, 0.0);
	} else if(isStainedGlass(entity)) {
		RME.x = 0;
	} else if(id == 41 || id == 42 || id == 57 || id == 133) {
		// Blocks of: Gold, Iron, Diamond, Emerald
		RME.x = min(RME.x, 0.6);
	} else if(id == 89) {
		// Glowstone
		RME.z = 1.0;
	}

	return RME;
}

#endif // MATERIAL_GLSL
