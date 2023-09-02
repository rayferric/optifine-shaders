#ifndef CURVE_GLSL
#define CURVE_GLSL

// TODO: docs
float sCurve(float x) {
	return 1.0 / (1 + exp(-x));
}

// TODO: docs
float bellCurve(float x) {
	return exp(-x * x);
}

#endif // CURVE_GLSL
