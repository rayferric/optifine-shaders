#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/src/modules/constants.glsl"
#include "/src/modules/hash.glsl"
#include "/src/modules/intersection.glsl"
#include "/src/modules/sdf.glsl"

// radius of the hypothetical planet the bedrock layer is starting at
#define CLOUDS_VIEW_RADIUS  10000.0
// the radius of the cloud sphere above the surface of the planet
#define CLOUDS_INNER_RADIUS 10100.0
// the radius of the enclosing sphere of the cloud sphere
#define CLOUDS_OUTER_RADIUS 10200.0

#define CLOUDS_CLOUD_TEX colortex5

float cumulusSdf(in vec3 point, in vec3 seed) {
	vec3 rand = hash(vec3(fract(seed * vec3(12.102312, 1349.33, 0.2132))));
	vec3 signedRand = rand * 2.0 - 1.0;

	float sdf;

	// horizontal body
	sdf = sdfCapsule(
	    point - vec3(20.0, 10.0, 30.0) * signedRand.xyz,
	    vec3(40.0, 0.0, 40.0) * signedRand.zxy,
	    10.0
	);
	// first bump
	sdf = sdfSmoothUnion(
	    sdf,
	    sdfCapsule(
	        point - vec3(30.0, 0.0, 0.0) * rand,
	        vec3(0.0, 10.0, 0.0) * rand,
	        10.0
	    ),
	    5.0
	);
	// second bump
	sdf = sdfSmoothUnion(
	    sdf,
	    sdfCapsule(
	        point - vec3(0.0, 0.0, 0.0) * rand,
	        vec3(-10.0, 20.0, 0.0) * rand,
	        10.0
	    ),
	    5.0
	);
	// meltdown
	sdf = sdfSmoothUnion(
	    sdf, sdfSphere(point - vec3(0.0, -20.0, 0.0), 30.0), 20.0
	);
	// bottom boundary
	// sdf = sdfSmoothIntersection(
	//     sdf, sdfSphere(point - vec3(0.0, 190.0, 0.0), 200.0), 30
	// );
	sdf = sdfSmoothIntersection(
	    sdf, sdfPlane(-(point - vec3(0.0, -5.0, 0.0))), 20.0
	);

	return sdf;
}

float sdf(in vec3 point) {
	float sdf;

	const float cellSize = 150.0;

	vec2 f    = floor(point.xz / cellSize + 0.5);
	vec2 f2   = floor(cameraPosition.xz / cellSize);
	vec2 frac = fract(cameraPosition.xz / cellSize);
	vec2 s    = sign(frac);

	vec2 cell1 = (f2)*cellSize;
	vec2 cell2 = (f2 + vec2(s.x, 0.0)) * cellSize;
	vec2 cell3 = (f2 + vec2(0.0, s.y)) * cellSize;
	vec2 cell4 = (f2 + s) * cellSize;

	sdf = cumulusSdf(point - vec3(cell1.x, 150.0, cell1.y), vec3(f, 0.0));
	sdf = sdfSmoothUnion(
	    sdf,
	    cumulusSdf(point - vec3(cell2.x, 150.0, cell2.y), vec3(f, 0.0)),
	    20.0
	);
	sdf = sdfSmoothUnion(
	    sdf,
	    cumulusSdf(point - vec3(cell3.x, 150.0, cell3.y), vec3(f, 0.0)),
	    20.0
	);
	sdf = sdfSmoothUnion(
	    sdf,
	    cumulusSdf(point - vec3(cell4.x, 150.0, cell4.y), vec3(f, 0.0)),
	    20.0
	);
	// sdf = sdf - (fbm(point * 0.5, 1.0) * 0.5 + 0.5) * 0.3;
	sdf = sdfSmoothUnion(sdf, sdfPlane(point - vec3(0.0, 130.0, 0.0)), 100.0);

	return sdf;
}

#include "/src/modules/sdf_impl.glsl"

vec4 clouds(
    in vec3  viewDir,
    in vec3  lightDir,
    in vec3  origin,
    in float coverage,
    in float maxDistance
) {
	// Negate the view vector to get the view direction.
	viewDir = -viewDir;

	// // All of the spheres are centered at (0, 0, 0).
	// vec2 worldOffset = origin.xz;
	// origin           = vec3(0.0, origin.y + CLOUDS_VIEW_RADIUS, 0.0);

	// // Intersect the two planes that define the cloud volume.
	// Intersection innerIntersection =
	//     intersectSphere(origin, viewDir, CLOUDS_INNER_RADIUS);
	// Intersection outerIntersection =
	//     intersectSphere(origin, viewDir, CLOUDS_OUTER_RADIUS);

	// // If the outer sphere was not intersected, the clouds cannot be seen.
	// // Same if the outer sphere is all behind the viewer.
	// if (outerIntersection.near > outerIntersection.far ||
	//     outerIntersection.far < 0.0) {
	// 	return vec4(0.0);
	// }

	// // Find the bounds of the ray inside one or both of the cloud volumes.
	// Intersection front = Intersection(1.0, -1.0);
	// Intersection back  = Intersection(1.0, -1.0);

	// if (origin.y > CLOUDS_INNER_RADIUS) {
	// 	// If the viewer is above the cloud volume...

	// 	if (innerIntersection.near < innerIntersection.far &&
	// 	    innerIntersection.near > 0.0) {
	// 		// If the inner sphere is in front...

	// 		front.near = max(outerIntersection.near, 0.0);
	// 		front.far  = innerIntersection.near;

	// 		// second cloud volume after the inner sphere
	// 		back.near = innerIntersection.far;
	// 		back.far  = outerIntersection.far;
	// 	} else {
	// 		front.near = max(outerIntersection.near, 0.0);
	// 		front.far  = outerIntersection.far;
	// 	}
	// } else {
	// 	// If the viewer is underneath the cloud volume...

	// 	front.near = innerIntersection.far;
	// 	front.far  = outerIntersection.far;
	// }

	// // Abort if the cloud volume is positioned behind the obstacle at
	// // maxDistance.
	// front.far = min(front.far, maxDistance);
	// back.far  = min(back.far, maxDistance);

	// front.far = min(front.far, 1000.0);
	// back.far  = min(back.far, 1000.0);

	// vec4 clouds = vec4(0.0);

	// // first volume
	// if (front.near < front.far) {
	// 	vec4 background = discoverClouds(
	// 	    viewDir, lightDir, origin, worldOffset, coverage, front
	// 	);

	// 	clouds.xyz = mix(background.xyz, clouds.xyz, clouds.w);
	// 	clouds.w   = 1.0 - (1.0 - background.w) * (1.0 - clouds.w);
	// }

	// // second volume
	// if (back.near < back.far) {
	// 	vec4 background = discoverClouds(
	// 	    viewDir, lightDir, origin, worldOffset, coverage, back
	// 	);

	// 	clouds.xyz = mix(background.xyz, clouds.xyz, clouds.w);
	// 	clouds.w   = 1.0 - (1.0 - background.w) * (1.0 - clouds.w);
	// }

	vec4 data = sdfRayMarch(origin, viewDir, 128, 0.01);
	data.xyz  *= 50.0;
	data.w    = data.w < min(300.0, maxDistance) ? 1.0 : 0.0;
	return data;
}

#endif // CLOUDS_GLSL
