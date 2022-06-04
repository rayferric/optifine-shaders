#ifndef FXAA_GLSL
#define FXAA_GLSL

// TODO Remove this file. Feature is already implemented in OptiFine

#define FXAA_THRESHOLD_MIN    0.0312
#define FXAA_THRESHOLD_MAX    0.125
#define FXAA_ITERATIONS       12
#define FXAA_SUBPIXEL_QUALITY 0.75

const float FXAA_QUALITY[12] = float[](1.0, 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0);

vec3 fxaa(in sampler2D tex, in vec2 coord, in vec2 texelSize) {
	vec3 color = texture2D(tex, coord).xyz;

	/* Detecting where to apply AA */

	// Luma at the current fragment and its four direct neighbours
	float c = luma(color);
	float t = luma(texture2DOffset(tex, coord, ivec2( 0,  1)).xyz);
	float b = luma(texture2DOffset(tex, coord, ivec2( 0, -1)).xyz);
	float l = luma(texture2DOffset(tex, coord, ivec2(-1,  0)).xyz);
	float r = luma(texture2DOffset(tex, coord, ivec2( 1,  0)).xyz);

	// Find the maximum and minimum luma around the current fragment
	float lumaMin = min(c, min(min(t, b), min(l, r)));
	float lumaMax = max(c, max(max(t, b), max(l, r)));

	// If the luma variation is lower that a threshold (or if we are in a really dark area), we are not on an edge, don't perform any AA
	float lumaDelta = lumaMax - lumaMin;
	if (lumaDelta < max(FXAA_THRESHOLD_MIN, lumaMax * FXAA_THRESHOLD_MAX))return color;

	/* Estimating gradient and choosing edge direction */

	// Query the 4 remaining corners lumas
	float tl = luma(texture2DOffset(tex, coord, ivec2(-1,  1)).xyz);
	float tr = luma(texture2DOffset(tex, coord, ivec2( 1,  1)).xyz);
	float bl = luma(texture2DOffset(tex, coord, ivec2(-1, -1)).xyz);
	float br = luma(texture2DOffset(tex, coord, ivec2( 1, -1)).xyz);

	// Combine the four edges lumas (using intermediary variables for future computations with the same values)
	float tb = t + b;
	float lr = l + r;

	// Same for corners
	float tltr = tl + tr; // Top corners
	float blbr = bl + br; // Bottom corners
	float tlbl = tl + bl; // Left corners
	float trbr = tr + br; // Right corners

	// Compute an estimation of the gradient along the horizontal and vertical axis
	float edgeH = abs(-2.0 * l + tlbl) + abs(-2.0 * c + tb) * 2.0 + abs(-2.0 * r + trbr);
	float edgeV = abs(-2.0 * t + tltr) + abs(-2.0 * c + lr) * 2.0 + abs(-2.0 * b + blbr);

	// Whether the local edge is horizontal or vertical
	bool isHorizontal = edgeH >= edgeV;

	/* Choosing edge orientation */

	// Select the two neighboring texels lumas in the opposite direction to the local edge
	float luma1 = isHorizontal ? b : l;
	float luma2 = isHorizontal ? t : r;
	
	// Compute gradients in this direction
	float gradient1 = luma1 - c;
	float gradient2 = luma2 - c;

	// Which direction is the steepest
	bool is1Steepest = abs(gradient1) > abs(gradient2);

	// Normalized gradient in the corresponding direction
	float gradientScaled = 0.25 * max(abs(gradient1), abs(gradient2));

	// Choose the step size (one pixel) according to the edge direction
	float stepSize = isHorizontal ? texelSize.y : texelSize.x;

	// Average luma in the correct direction
	float lumaLocalAvg;
	if (is1Steepest) {
		stepSize = -stepSize;
		lumaLocalAvg = 0.5 * (luma1 + c);
	} else {
		lumaLocalAvg = 0.5 * (luma2 + c);
	}

	// Shift coord in the correct direction by half a pixel
	vec2 edgeCoord = coord;
	if (isHorizontal) {
		edgeCoord.y += stepSize * 0.5;
	} else {
		edgeCoord.x += stepSize * 0.5;
	}

	/* First iteration exploration */

	// Compute offset (for each iteration step) in the right direction
	vec2 offset = isHorizontal ? vec2(texelSize.x, 0.0) : vec2(0.0, texelSize.y);

	// Compute coords to explore on each side of the edge, orthogonally. FXAA_QUALITY allows us to step faster
	vec2 coord1 = edgeCoord - offset;
	vec2 coord2 = edgeCoord + offset;

	// Read the lumas at both current extremities of the exploration segment, and compute the delta wrt to the local average luma
	float end1 = luma(texture2D(tex, coord1).xyz) - lumaLocalAvg;
	float end2 = luma(texture2D(tex, coord2).xyz) - lumaLocalAvg;

	// If the luma deltas at the current extremities are larger than the local gradient, we have reached the side of the edge
	bool reached1 = abs(end1) >= gradientScaled;
	bool reached2 = abs(end2) >= gradientScaled;
	bool reachedBoth = reached1 && reached2;

	// If the side is not reached, we continue to explore in this direction
	if (!reached1)coord1 -= offset;
	if (!reached2)coord2 += offset;

	/* Iterating */

	// If both sides have not been reached, continue to explore
	if (!reachedBoth) {
		for (int i = 2; i < FXAA_ITERATIONS; i++) {
			// If needed, read luma in both directions, compute delta
			if (!reached1)end1 = luma(texture2D(tex, coord1).xyz) - lumaLocalAvg;
			if (!reached2)end2 = luma(texture2D(tex, coord2).xyz) - lumaLocalAvg;

			// If the luma deltas at the current extremities is larger than the local gradient, we have reached the side of the edge
			reached1 = abs(end1) >= gradientScaled;
			reached2 = abs(end2) >= gradientScaled;
			reachedBoth = reached1 && reached2;

			// If the side is not reached, we continue to explore in this direction, with a variable quality
			if (!reached1)coord1 -= offset * FXAA_QUALITY[i];
			if (!reached2)coord2 += offset * FXAA_QUALITY[i];

			// If both sides have been reached, stop the exploration
			if (reachedBoth)break;
		}
	}

	/* Estimating offset */

	// Compute the distances to each extremity of the edge
	float distance1 = isHorizontal ? (coord.x - coord1.x) : (coord.y - coord1.y);
	float distance2 = isHorizontal ? (coord2.x - coord.x) : (coord2.y - coord.y);

	// In which direction is the extremity of the edge closer
	bool is1Closer = distance1 < distance2;
	float distanceFinal = min(distance1, distance2);

	// Length of the edge
	float edgeThickness = distance1 + distance2;

	// Coord offset: read in the direction of the closest side of the edge.
	float pixelOffset = -distanceFinal / edgeThickness + 0.5;

	// Is the luma at center smaller than the local average
	bool isLumaCenterSmaller = c < lumaLocalAvg;

	// If the luma at center is smaller than at its neighbour, the delta luma at each end should be positive (same variation)
	// (in the direction of the closer side of the edge.)
	bool correctVariation = ((is1Closer ? end1 : end2) < 0.0) != isLumaCenterSmaller;

	// If the luma variation is incorrect, do not offset
	float finalOffset = correctVariation ? pixelOffset : 0.0;

	/* Subpixel antialiasing */

	// Full weighted average of the luma over the 3x3 neighborhood.
	float lumaAvg = (2.0 * (tb + lr) + tlbl + trbr) / 12.0;

	// Ratio of the delta between the global average and the center luma, over the luma range in the 3x3 neighborhood.
	float subPixelOffset1 = clamp(abs(lumaAvg - c) / lumaDelta, 0.0, 1.0);
	float subPixelOffset2 = (3.0 - subPixelOffset1 * 2.0) * subPixelOffset1 * subPixelOffset1;

	// Compute a sub-pixel offset based on this delta.
	float subPixelOffsetFinal = subPixelOffset2 * subPixelOffset2 * FXAA_SUBPIXEL_QUALITY;

	// Pick the biggest of the two offsets.
	finalOffset = max(finalOffset, subPixelOffsetFinal);

	/* Final read */

	// Compute the final UV coordinates.
	vec2 finalCoord = coord;
	if (isHorizontal) {
		finalCoord.y += finalOffset * stepSize;
	} else {
		finalCoord.x += finalOffset * stepSize;
	}

	return texture2D(tex, finalCoord).xyz;
}

#endif