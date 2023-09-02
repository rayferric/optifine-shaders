varying vec4 v_Color;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;
varying mat3 v_TBN;

///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

#include "/src/modules/gamma.glsl"

void main() {
	v_Color = gl_Color;

	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	v_AmbientLight = (gl_TextureMatrix[1] * gl_MultiTexCoord1).yx;
	v_AmbientLight = pow(v_AmbientLight, vec2(1.5));
	v_AmbientLight =
	    v_AmbientLight * (1 - MIN_LIGHT_FACTOR) + vec2(MIN_LIGHT_FACTOR);
	// Sample from vanilla lightmap for debug.
	// v_AmbientLight.y = texture(lightmap, vec2(v_AmbientLight.y, 0.1)).x; //
	v_AmbientLight = gammaToLinear(v_AmbientLight);

	vec3 normal   = gl_NormalMatrix * gl_Normal;
	vec3 tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(cross(tangent, normal) * at_tangent.w);

	// clang-format off
	v_TBN = mat3(
		tangent.x, binormal.x, normal.x,
		tangent.y, binormal.y, normal.y,
		tangent.z, binormal.z, normal.z
	);
	// clang-format on

	gl_Position = ftransform();
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/src/modules/dither.glsl"
#include "/src/modules/gamma.glsl"
#include "/src/modules/luminance.glsl"
#include "/src/modules/pack.glsl"

void main() {
	vec3 normal =
	    normalize((texture2D(normals, v_TexCoord).xyz * 2.0 - 1.0) * v_TBN);

	gl_FragData[0]    = texture(texture, v_TexCoord) * v_Color;
	gl_FragData[1].x  = 0.8; // roughness
	gl_FragData[1].y  = 0.0; // metallic
	gl_FragData[1].z  = 0.0; // unused
	gl_FragData[1].w  = 1.0;
	gl_FragData[2].xy = packNormal(normal);
	gl_FragData[2].w  = 1.0;
	gl_FragData[3].xy = linearToGamma(v_AmbientLight);
	// gl_FragData[3].xy =
	//     dither8X8(gl_FragData[3].xy, ivec2(gl_FragCoord.xy), 255);
	gl_FragData[3].w = 1.0;
}

/* DRAWBUFFERS:2345 */

#endif // FSH
