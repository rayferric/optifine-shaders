#include "include/common.glsl"

varying vec3 v_FragPos;

void main() {
	v_FragPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	gl_Position = gl_ProjectionMatrix * vec4(v_FragPos, 1.0);
}
