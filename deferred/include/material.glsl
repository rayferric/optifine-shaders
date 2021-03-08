#ifndef MATERIAL_GLSL
#define MATERIAL_GLSL

#define WATER_ALBEDO vec3(0.0, 0.2, 0.2)
#define ICE_ALBEDO   vec3(0.2, 0.6, 1.0)

bool isPlant(in vec3 entity) {
	int id = int(entity.x + 0.5);
	return (
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
		id == 207
	);
}

bool isWater(in vec3 entity) {
	int id = int(entity.x + 0.5);
	return id == 8 || id == 9; // Flowing Water; Still Water
}

bool isIce(in vec3 entity) {
	int id = int(entity.x + 0.5);
	return id == 79; // Ice
}

bool isStainedGlass(in vec3 entity) {
	int id = int(entity.x + 0.5);
	return id == 95 || id == 160; // Stained Glass; Stained Glass Pane
}

bool isTranslucent(in vec3 entity) {
	int id = int(entity.x + 0.5);
	return id == 8 || id == 9 || id == 79 || id == 95 || id == 160; // Flowing Water; Still Water; Ice; Stained Glass; Stained Glass Pane
}

struct MaterialMask {
	bool isLit;
	bool isWater;
	bool isIce;
	bool isTranslucent;
	bool isHand;
};

float encodeMask(in MaterialMask mask) {
	int i = 0;
	i |= int(mask.isLit)         << 0;
	i |= int(mask.isWater)       << 1;
	i |= int(mask.isIce)         << 2;
	i |= int(mask.isTranslucent) << 3;
	i |= int(mask.isHand)        << 4;
	return i / 255.0; // Minimum 8-bit buffer is required
}

MaterialMask decodeMask(in float value) {
	int i = int(value * 255.0 + 0.5);
	MaterialMask mask;
	mask.isLit         = bool((i >> 0) & 1);
	mask.isWater       = bool((i >> 1) & 1);
	mask.isIce         = bool((i >> 2) & 1);
	mask.isTranslucent = bool((i >> 3) & 1);
	mask.isHand        = bool((i >> 4) & 1);
	return mask;
}

MaterialMask genEntityMask(in vec3 entity) {
	int id = int(entity.x + 0.5);
	MaterialMask mask;
	mask.isLit         = true;
	mask.isWater       = isWater(entity);
	mask.isIce         = isIce(entity);
	mask.isTranslucent = isTranslucent(entity);
	mask.isHand        = false;
	return mask;
}

MaterialMask genUnlitMask() {
	return MaterialMask(false, false, false, false, false);
}

// Red; Green; Blue; Alpha (controls transmittance)
vec3 remapEntityAlbedo(in vec3 albedo, in vec3 entity) {
	if(isWater(entity)) {
		albedo = WATER_ALBEDO;
	}
	return albedo;
}

// Roughness; Metallic; Emission; Transmittance
vec4 remapEntityRMET(in vec4 RMET, in vec3 entity) {
	RMET.y = 0.0; // Better not to have many metallic surfaces

	int id = int(entity.x + 0.5);
	if(isWater(entity)) {
		RMET = vec4(0.01, 1.0, 0.0, 0.75);
	} if(isStainedGlass(entity)) {
		RMET.x = 0.05;
	} else if(id == 41 || id == 42 || id == 57 || id == 133) { // Block of: Gold, Iron, Diamond, Emerald
		RMET.x = min(RMET.x, 0.6); // Roughness above 0.5 doesn't produce reflections (allow them only when using a PBR resourcepack)
	} else if(id == 89) { // Glowstone
		RMET.z = 1.0;
	}
	return RMET;
}

#endif // MATERIAL_GLSL