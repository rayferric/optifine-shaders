#ifndef RAYMARCH_GLSL
#define RAYMARCH_GLSL

// Call this once origin is behind the depth buffer
// void binaryRefine(inout vec3 origin, inout float depth, in sampler2D depthTex, in vec3 dir) {
// 	bool inFront = false;

// 	vec3  lastBehind      = origin;
// 	float lastBehindDepth = depth;

// 	for (int i = 0; i < RAYMARCH_REFINE_STEPS; i++) {
// 		// Go back, and then trace forward
// 		// once we got in front of the buffer
// 		dir *= 0.5;
// 		origin += inFront ? dir : -dir;

// 		vec3 coord = projPos(gbufferProjection, origin) * 0.5 + 0.5;
// 		float depth = texture2D(depthTex, coord.xy).x;

// 		inFront = depth > coord.z;

// 		// Mark more precise position, which
// 		// is still behind the depth buffer
// 		lastBehind      = inFront ? lastBehind      : origin;
// 		lastBehindDepth = inFront ? lastBehindDepth : depth;
// 	}

// 	origin = lastBehind;
// 	depth  = lastBehindDepth;
// }

// bool insideBox(in vec3 pos, in vec3 bottomLeft, in vec3 topRight) {
//     vec3 s = step(bottomLeft, pos) - step(topRight, pos);
//     return bool(s.x * s.y * s.z);
// }

// bool rayMarch(
// 		in sampler2D depthTex,
// 		in vec3      origin,
// 		in vec3      dir,
// 		in float     stepLen,
// 		in float     stepMul,
// 		in int       stepCount,
// 		in float     tolerance) {
// 	dir *= stepLen;

// 	for (int i = 0; i < stepCount; i++) {
// 		origin += dir;
// 		dir *= stepMul;

// 		vec3 coord = projPos(gbufferProjection, origin) * 0.5 + 0.5;
// 		if (!insideBox(coord, vec3(0.0), vec3(1.0)))
// 			break;

// 		float depth = texture2D(depthTex, coord.xy).x;

// 		// Once we're behind the depth buffer
// 		if (coord.z > depth) {
// 			// Refinement updates origin and depth
// 			binaryRefine(origin, depth, depthTex, dir);

// 			// Break if refinement didn't move the origin close enough
// 			if (distance(-origin.z, getLinearDepth(depth)) > tolerance)
// 				break;

// 			return true;
// 		}
// 	}

// 	return false;
// }

#define RAYMARCH_REFINE_STEPS 4

struct RayMarchResult {
	bool hasHit;
	vec2 coord;
};

bool insideBox(in vec2 pos, in vec2 bottomLeft, in vec2 topRight) {
    vec2 s = step(bottomLeft, pos) - step(topRight, pos);
    return bool(s.x * s.y);
}

RayMarchResult rayMarch(
		in sampler2D depthTex,
		in vec3      origin,
		in vec3      dir,
		in float     rayLength,
		in float     bias,
		in int       stepCount,
		in float     thickness) {
	vec3 start = origin + dir * 0.02;
	vec3 end   = origin + dir * rayLength;

	// Clip endpoint to near plane
	rayLength = -end.z > near ? rayLength : (-origin.z - near) / dir.z;
	end = origin + dir * rayLength;

	vec4 projStart = gbufferProjection * vec4(start, 1.0);
	vec4 projEnd   = gbufferProjection * vec4(end, 1.0);

	// We will interpolate 3 values between them
	// 2 of which are used to cheaply calculate ray depth
	// in sync with 2D screen coordinates
	float invWStart = 1.0 / projStart.w;
	float invWEnd   = 1.0 / projEnd.w;

	vec3 homoStart = start * invWStart;
	vec3 homoEnd   = end   * invWEnd;

	vec2 screenStart = projStart.xy * invWStart * 0.5 + 0.5;
	vec2 screenEnd   = projEnd.xy   * invWEnd   * 0.5 + 0.5;

	for (int i = 1; i <= stepCount; i++) {
		// Linear progress across 2D screen, not the 3D ray
		float progress = float(i) / float(stepCount);

		float invW   = mix(invWStart, invWEnd, progress);
		float homoZ  = mix(homoStart.z, homoEnd.z, progress);
		vec2  screen = mix(screenStart, screenEnd, progress);

		if (!insideBox(screen, vec2(0.0), vec2(1.0)))
			break;

		float rayDepth = -(homoZ / invW);

		if (rayDepth < near || rayDepth > far)
			break;

		float sampleDepth = getLinearDepth(texture2D(depthTex, screen + 0.05).x);

		// When we reach behind the depth buffer...
		// (This block is terminal)
		if (rayDepth > sampleDepth) {
			float depthDiff = rayDepth - sampleDepth;
			vec2 finalCoord = screen;

			float progressDelta = 1.0 / float(stepCount);
			bool inFront = false;

			for (int i = 0; i < RAYMARCH_REFINE_STEPS; i++) {
				// ...go back, and then trace forward
				// once we got in front of it
				progressDelta *= 0.5;
				progress += inFront ? progressDelta : -progressDelta;

				// Heavy reuse of temporary variables
				invW   = mix(invWStart, invWEnd, progress);
				homoZ  = mix(homoStart.z, homoEnd.z, progress);
				screen = mix(screenStart, screenEnd, progress);

				rayDepth    = -(homoZ / invW);
				sampleDepth = getLinearDepth(texture2D(depthTex, screen + 0.05).x);

				inFront = sampleDepth > rayDepth;

				// Mark more precise position, which
				// is still behind the depth buffer
				depthDiff  = inFront ? depthDiff : rayDepth - sampleDepth;
				finalCoord = inFront ? finalCoord : screen;
			}

			if (depthDiff > thickness)
				break;

			return RayMarchResult(true, finalCoord);
		}
	}

	return RayMarchResult(false, vec2(0.0));
}

#endif // RAYMARCH_GLSL
