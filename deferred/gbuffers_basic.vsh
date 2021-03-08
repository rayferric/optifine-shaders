#include "include/common.glsl"

varying vec4 v_Color;

void main() {
	v_Color = gl_Color;

	gl_Position = ftransform();
}
