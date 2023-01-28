#ifndef RGB_TO_HSV_GLSL
#define RGB_TO_HSV_GLSL

vec3 rgbToHsv(vec3 rgb)
{
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(rgb.zy, K.wz), vec4(rgb.yy, K.xy), step(rgb.z, rgb.y));
	vec4 q = mix(vec4(p.xyw, rgb.x), vec4(rgb.x, p.yzx), step(p.x, rgb.x));

	float d = q.x - min(q.w, q.y);
	float e = 1.0E-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

#endif // RGB_TO_HSV_GLSL
