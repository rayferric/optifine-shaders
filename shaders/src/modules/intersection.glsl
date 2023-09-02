#ifndef INTERSECTION_GLSL
#define INTERSECTION_GLSL

/**
 * @brief ray-sphere intersection result
 */
struct Intersection {
	float near, far;
};

/**
 * @brief Computes entry and exit points of ray intersecting a sphere.
 *
 * @param origin ray origin
 * @param dir    normalized ray direction
 * @param radius radius of the sphere
 *
 * @return intersection distances
 * .near - position of entry point relative to the ray origin
 * .far - position of exit point relative to the ray origin
 * if there's no intersection at all, .x is larger than .y
 */
Intersection intersectSphere(in vec3 origin, in vec3 dir, in float radius) {
	float a = dot(dir, dir);
	float b = 2.0 * dot(dir, origin);
	float c = dot(origin, origin) - (radius * radius);

	float d = (b * b) - 4.0 * a * c;
	if (d < 0.0) {
		return Intersection(1.0, -1.0);
	}

	return Intersection((-b - sqrt(d)) / (2.0 * a), (-b + sqrt(d)) / (2.0 * a));
}

/**
 * @brief Computes intersection point of ray intersecting a horizontal plane.
 *
 * @param origin ray origin
 * @param dir    normalized ray direction
 * @param height Y coordinate of the plane
 *
 * @return intersection distances
 * .near - position of entry point relative to the ray origin
 * .far - position of entry point relative to the ray origin
 */
float intersectHorizontalPlane(in vec3 origin, in vec3 dir, in float height) {
	return (height - origin.y) / dir.y;
}

#endif // INTERSECTION_GLSL
