#ifndef IS_INSIDE_RECT_GLSL
#define IS_INSIDE_RECT_GLSL

/**
 * @brief Tests whether a 2D point is inside a rectangle.
 *
 * @param pos        point to test
 * @param bottomLeft bottom right vertex of the rectangle
 * @param topRight   top right vertex of the rectangle
 *
 * @return m<sup>-1</sup>
 */

bool isInsideRect(in vec2 pos, in vec2 bottomLeft, in vec2 topRight) {
	vec2 s = step(bottomLeft, pos) - step(topRight, pos);
	return bool(s.x * s.y);
}

#endif // IS_INSIDE_RECT_GLSL
