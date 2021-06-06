#ifndef REMAP_PBR_VALUES
#define REMAP_PBR_VALUES

#include "/include/modules/blocks.glsl"

/**
 * Remaps albedo and opacity values for an entity.
 *
 * @param albedoOpacity albedo (XYZ) + opacity (W)
 * @param entity        entity data
 *
 * @return new albedo (XYZ) + new opacity (W)
 */
vec4 remapBlockAlbedoOpacity(in vec4 albedoOpacity, in vec3 entity) {
	return isWater(entity) ? WATER_ALBEDO_OPACITY : albedoOpacity;
}

/**
 * Remaps PBR values for an entity.
 *
 * @param rme    roughness (X) + metallic (Y) + emission (Z)
 * @param entity entity data
 *
 * @return new roughness (X) + new metallic (Y) + new emission (Z)
 */
vec3 remapBlockRme(in vec3 rme, in vec3 entity) {
	// Better not to have many metallic surfaces
	// TODO: This sure breaks RPs - to be removed
	rme.y = 0.0;

	int id = int(entity.x + 0.5);
	if(isWater(entity)) {
		rme = vec3(0.05, 1.0, 0.0);
	} else if(isStainedGlass(entity)) {
		rme.xy = vec2(0.05, 0.0);
	} else if(id == 41 || id == 42 || id == 57 || id == 133) {
		// Blocks of: Gold, Iron, Diamond, Emerald
		rme.x = min(rme.x, 0.6);
	} else if(id == 89) {
		// Glowstone
		rme.z = 1.0;
	}

	return rme;
}

#endif // REMAP_PBR_VALUES
