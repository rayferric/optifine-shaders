varying vec4 v_Color;
varying vec2 v_TexCoord;

///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

#include "/src/modules/shadow.glsl"

void main() {
	v_Color    = gl_Color;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();

	v_Color    = gl_Color;
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	// We can use the fact that most waving vertices will have integer
	// coordinates to fix precision errors by rounding
	vec3 worldPos =
	    (shadowModelViewInverse * shadowProjectionInverse * ftransform()).xyz +
	    cameraPosition;
	vec3 vertexPos = gl_Vertex.xyz; // Either chunk space or camera space
	// vertexPos      += getBlockWave(
	//     floor(worldPos + vec3(0.5)),
	//     mc_Entity,
	//     mc_midTexCoord.y > gl_MultiTexCoord0.y
	// );

	gl_Position =
	    gl_ProjectionMatrix * gl_ModelViewMatrix * vec4(vertexPos, 1.0);
	gl_Position.xy *= getShadowDistortionFactor(gl_Position.xy);
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/src/modules/constants.glsl"

void main() {
	vec4 color  = texture(texture, v_TexCoord);
	color      *= v_Color;

	// alpha test
	if (color.w < EPSILON) {
		discard;
	}

	outColor0 = color;
}

/* RENDERTARGETS: 0 */

#endif // FSH
