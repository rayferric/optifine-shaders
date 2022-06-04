///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

void main() {
	gl_Position = vec4(0.0);
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

void main() {
	discard;
}

#endif // FSH
