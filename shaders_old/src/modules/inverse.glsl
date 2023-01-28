#ifndef INVERSE_GLSL
#define INVERSE_GLSL

/**
 * Computes the inverse of a matrix.
 * This function normally requires "#version 140" or later to be globally defined.
 *
 * @param m matrix to invert
 *
 * @return m<sup>-1</sup>
 */
mat4 inverse(in mat4 m) {
	float s0 = m[0][0] * m[1][1] - m[0][1] * m[1][0];
	float s1 = m[0][0] * m[2][1] - m[0][1] * m[2][0];
	float s2 = m[0][0] * m[3][1] - m[0][1] * m[3][0];
	float s3 = m[1][0] * m[2][1] - m[1][1] * m[2][0];
	float s4 = m[1][0] * m[3][1] - m[1][1] * m[3][0];
	float s5 = m[2][0] * m[3][1] - m[2][1] * m[3][0];
	
	float c5 = m[2][2] * m[3][3] - m[2][3] * m[3][2];
	float c4 = m[1][2] * m[3][3] - m[1][3] * m[3][2];
	float c3 = m[1][2] * m[2][3] - m[1][3] * m[2][2];
	float c2 = m[0][2] * m[3][3] - m[0][3] * m[3][2];
	float c1 = m[0][2] * m[2][3] - m[0][3] * m[2][2];
	float c0 = m[0][2] * m[1][3] - m[0][3] * m[1][2];

	float det = s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0;

	return mat4(
		 m[1][1] * c5 - m[2][1] * c4 + m[3][1] * c3,
		-m[0][1] * c5 + m[2][1] * c2 - m[3][1] * c1,
		 m[0][1] * c4 - m[1][1] * c2 + m[3][1] * c0,
		-m[0][1] * c3 + m[1][1] * c1 - m[2][1] * c0,
		-m[1][0] * c5 + m[2][0] * c4 - m[3][0] * c3,
		 m[0][0] * c5 - m[2][0] * c2 + m[3][0] * c1,
		-m[0][0] * c4 + m[1][0] * c2 - m[3][0] * c0,
		 m[0][0] * c3 - m[1][0] * c1 + m[2][0] * c0,
		 m[1][3] * s5 - m[2][3] * s4 + m[3][3] * s3,
		-m[0][3] * s5 + m[2][3] * s2 - m[3][3] * s1,
		 m[0][3] * s4 - m[1][3] * s2 + m[3][3] * s0,
		-m[0][3] * s3 + m[1][3] * s1 - m[2][3] * s0,
		-m[1][2] * s5 + m[2][2] * s4 - m[3][2] * s3,
		 m[0][2] * s5 - m[2][2] * s2 + m[3][2] * s1,
		-m[0][2] * s4 + m[1][2] * s2 - m[3][2] * s0,
		 m[0][2] * s3 - m[1][2] * s1 + m[2][2] * s0
	) * (1.0 / det);
}

#endif // INVERSE_GLSL
