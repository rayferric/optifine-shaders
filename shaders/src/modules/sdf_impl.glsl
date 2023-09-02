#ifndef SDF_IMPL_GLSL
#define SDF_IMPL_GLSL

// float sdf(in vec3 point) must be defined before including this file.

vec3 sdfNormal(vec3 point) {
	// Find gradient of the 4D distance function to determine the direction of
	// the quickest ascent. The gradient is a vector of partial derivatives.

	vec2 epsilon = vec2(EPSILON, 0.0);

	return vec3(
	    sdf(point + epsilon.xyy) - sdf(point - epsilon.xyy),
	    sdf(point + epsilon.yxy) - sdf(point - epsilon.yxy),
	    sdf(point + epsilon.yyx) - sdf(point - epsilon.yyx)
	);
}

vec4 sdfRayMarch(vec3 origin, vec3 dir, uint maxSteps, float minDistance) {
	float depth = 0.0;

	for (uint i = 0; i < maxSteps; i++) {
		vec3  point = origin + depth * dir;
		float field = abs(sdf(point)); // abs - two sided

		if (field < minDistance) {
			return vec4(sdfNormal(point), depth);
		}

		depth += field;
	}

	return vec4(vec3(0.0), depth);
}

#endif // SDF_IMPL_GLSL
