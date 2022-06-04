#ifndef NORMALIZED_MUL
#define NORMALIZED_MUL

/**
 * Transforms position using 4x4 matrix and
 * normalizes resulting homogeneous coordinates. 
 *
 * @param matrix transformation matrix
 * @param pos    source position
 *
 * @return transformed position
 */
vec3 normalizedMul(in mat4 matrix, in vec3 pos) {
	vec4 clip = matrix * vec4(pos, 1.0);
	return clip.xyz / clip.w;
}

#endif // NORMALIZED_MUL
