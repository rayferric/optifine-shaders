#ifndef MATERIAL_PROPERTIES
#define MATERIAL_PROPERTIES

#include "/src/modules/blocks.glsl"
#include "/src/modules/hsv.glsl"
#include "/src/modules/luminance.glsl"

struct MaterialProperties {
	vec3  albedo;
	float opacity;
	float roughness;
	float metallic;
	float emissive;
};

MaterialProperties makeMaterialProperties() {
	MaterialProperties properties;

	properties.albedo    = vec3(1.0, 0.0, 1.0);
	properties.opacity   = 1.0;
	properties.roughness = 1.0;
	properties.metallic  = 0.0;
	properties.emissive  = 0.0;

	return properties;
}

/**
 * @brief Remaps material properties for an entity.
 *
 * @param properties MaterialProperties instance
 * @param entity     entity data
 *
 * @return modified MaterialProperties instance
 */
MaterialProperties
remapMaterialProperties(in MaterialProperties properties, in vec3 entity) {
	int id = int(entity.x + 0.5);

	properties.roughness = min(properties.roughness, 0.8);

	if (isWater(entity)) {
		properties.albedo    = WATER_ALBEDO_OPACITY.xyz;
		properties.opacity   = WATER_ALBEDO_OPACITY.w;
		properties.roughness = 0.005;
		properties.metallic  = 1.0;
		properties.emissive  = 0.0;
	} else if (isStainedGlass(entity)) {
		properties.roughness = 0.005;
		properties.metallic  = 0.0;
		properties.emissive  = 0.0;
	} else if (id == 41 || id == 42 || id == 57 || id == 133) {
		// Blocks of: Gold, Iron, Diamond, Emerald
		properties.roughness = min(properties.roughness, 0.6);
		properties.metallic  = 1.0;
	} else if (isLava(entity) || id == 89 || id == 169 || id == 124) {
		// Lava, Glowstone, Sea Lantern, Lit Redstone Lamp
		properties.emissive = 1.0;
	} else if (id == 76 || id == 55 || id == 27 || id == 152 || id == 149 || id == 94) {
		// Redstone: Torch, Wire, Rail, Block, Comparator, Repeater
		vec3 hsv = rgbToHsv(properties.albedo);
		if (hsv.y > 0.5 && hsv.x < 0.05 || hsv.z > 0.95) { // Find red spots
			properties.albedo   *= 0.5;
			properties.emissive  = 1.0;
		}
	} else if (id == 10014 || id == 10015) {
		// Lit Redstone Ore
		vec3 hsv            = rgbToHsv(properties.albedo);
		properties.emissive = step(0.2, hsv.y);
	} else if (id == 10018) {
		// Glow Lichen
		properties.albedo   *= luminance(properties.albedo) * 2.0;
		properties.emissive  = 1.0;
	}

	// #ifdef GLOWING_ORES
	else if (id >= 10000 && id <= 10013) {
		// Unlit Ores
		vec3 hsv            = rgbToHsv(properties.albedo);
		properties.emissive = step(0.2, hsv.y);
		properties.albedo =
		    min(properties.albedo * mix(1.0, 2.0, properties.emissive), 1.0);
	} else if (id == 10016) {
		// Nether Gold Ore
		vec3 hsv            = rgbToHsv(properties.albedo);
		properties.emissive = step(0.02, hsv.x);
		properties.albedo =
		    min(properties.albedo * mix(1.0, 2.0, properties.emissive), 1.0);
	} else if (id == 10017) {
		// Quartz Ore
		vec3 hsv            = rgbToHsv(properties.albedo);
		properties.emissive = step(0.3, 1.0 - hsv.y);
		properties.albedo =
		    min(properties.albedo * mix(1.0, 2.0, properties.emissive), 1.0);
	}
	// #endif

	return properties;
}

#endif // MATERIAL_PROPERTIES
