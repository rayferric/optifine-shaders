#ifndef RAND_CONE_DIR_GLSL
#define RAND_CONE_DIR_GLSL

#include "/src/modules/constants.glsl"

/**
 * @brief Computes uniformly distributed random direction in a conic sphere
 * subsection.
 *
 * @param rand uniformly sampled random value in [0, 1]
 * @param cosTheta cosine of the half-angle of the cone
 * @param normal cone orientation
 *
 * @return normalized direction vector
 */
vec3 randConeDir(in float rand, in vec3 normal, in float cosTheta) {
	// Generate random vector in a Z-oriented cone
	float phi      = rand * 2.0 * PI;
	float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

	vec3 coneDir = vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);

	// Create coordinate system such that Z = normal

	vec3 nonParallelDir = vec3(0.0);
	if (abs(normal.x) < SQRT3_INV) {
		nonParallelDir.x = 1.0;
	} else if (abs(normal.y) < SQRT3_INV) {
		nonParallelDir.y = 1.0;
	} else {
		nonParallelDir.z = 1.0;
	}

	vec3 tangent  = normalize(cross(normal, nonParallelDir));
	vec3 binormal = cross(normal, tangent);
	mat3 tbn      = mat3(tangent, binormal, normal);

	return tbn * coneDir;
}

#endif // RAND_CONE_DIR_GLSL
