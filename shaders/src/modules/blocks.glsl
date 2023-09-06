#ifndef BLOCKS_GLSL
#define BLOCKS_GLSL

// /**
//  * @brief Tells whether the entity is a single plant, i.e.
//  * its bottom vertices should touch the ground.
//  *
//  * @param entity entity data
//  *
//  * @return true if single plant
//  */
// bool isSinglePlant(in vec3 entity) {
// 	int id = int(entity.x + 0.5);
// 	return id == 6 ||   // Sapling
// 	       id == 31 ||  // Dead Shrub
// 	       id == 32 ||  // Grass
// 	       id == 37 ||  // Dandelion
// 	       id == 38 ||  // Poppy + Other Flowers
// 	       id == 39 ||  // Brown Mushroom
// 	       id == 40 ||  // Red Mushroom
// 	       id == 59 ||  // Wheat Crops
// 	       id == 104 || // Pumpkin Stem
// 	       id == 105 || // Melon Stem
// 	       id == 115 || // Nether Wart
// 	       id == 141 || // Carrots
// 	       id == 142 || // Potatoes
// 	       id == 207;   // Betroots
// }

// /**
//  * @brief Tells whether the entity is a multi-block
//  * plant, that does not have a stable base.
//  *
//  * @param entity entity data
//  *
//  * @return true if double-plant or sugar cane
//  */
// bool isMultiPlant(in vec3 entity) {
// 	int id = int(entity.x + 0.5);
// 	// Sugar Canes; Double Plants
// 	return id == 83 || id == 175;
// }

// /**
//  * @brief Tells whether the entity is plant.
//  *
//  * @param entity entity data
//  *
//  * @return true if plant
//  */
// bool isPlant(in vec3 entity) {
// 	return isSinglePlant(entity) || isMultiPlant(entity);
// }

// /**
//  * @brief Tells whether the entity is water.
//  *
//  * @param entity entity data
//  *
//  * @return true if water
//  */
// bool isWater(in vec3 entity) {
// 	int id = int(entity.x + 0.5);
// 	// Flowing Water; Still Water
// 	return id == 8 || id == 9;
// }

// /**
//  * @brief Tells whether the entity is lava.
//  *
//  * @param entity entity data
//  *
//  * @return true if lava
//  */
// bool isLava(in vec3 entity) {
// 	int id = int(entity.x + 0.5);
// 	// Flowing Lava; Still Lava
// 	return id == 10 || id == 11;
// }

// /**
//  * @brief Tells whether the entity is ice.
//  *
//  * @param entity entity data
//  *
//  * @return true if ice
//  */
// bool isIce(in vec3 entity) {
// 	return int(entity.x + 0.5) == 79;
// }

// /**
//  * @brief Tells whether the entity is fire.
//  *
//  * @param entity entity data
//  *
//  * @return true if fire
//  */
// bool isFire(in vec3 entity) {
// 	return int(entity.x + 0.5) == 51;
// }

// /**
//  * @brief Tells whether the entity is stained glass.
//  *
//  * @param entity entity data
//  *
//  * @return true if stained glass
//  */
// bool isStainedGlass(in vec3 entity) {
// 	int id = int(entity.x + 0.5);
// 	// Stained Glass; Stained Glass Pane
// 	return id == 95 || id == 160;
// }

// /**
//  * @brief Tells whether the entity is translucent.
//  *
//  * @param entity entity data
//  *
//  * @return true if water, ice or stained glass
//  */
// bool isTranslucent(in vec3 entity) {
// 	int id = int(entity.x + 0.5);
// 	// Flowing Water; Still Water; Ice; Stained Glass; Stained Glass Pane
// 	return id == 8 || id == 9 || id == 79 || id == 95 || id == 160;
// }

// /**
//  * @brief Tells whether the entity is leaves.
//  *
//  * @param entity entity data
//  *
//  * @return true if leaves
//  */
// bool isLeaves(in vec3 entity) {
// 	int id = int(entity.x + 0.5);
// 	return id == 18 || id == 161;
// }

// Needed for custom effects in gbuffers
#define BLOCKS_WATER         1
#define BLOCKS_LAVA          2
#define BLOCKS_SINGLE_PLANT  3
#define BLOCKS_MULTI_PLANT   4
#define BLOCKS_LEAVES        5
#define BLOCKS_ICE           6
#define BLOCKS_FIRE          7
#define BLOCKS_STAINED_GLASS 8

#endif // BLOCKS_GLSL
