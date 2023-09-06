varying vec4 v_Color;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;

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
	v_AmbientLight = gammaToLinear(v_AmbientLight);

	gl_Position = ftransform();
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/src/modules/constants.glsl"
#include "/src/modules/gamma.glsl"
#include "/src/modules/gbuffer.glsl"

void main() {
	vec4 color  = texture(texture, v_TexCoord);
	color      *= v_Color;

	// alpha test
	if (color.w * v_Color.w < EPSILON) {
		discard;
	}

	GBuffer gbuffer;
	gbuffer.albedo     = gammaToLinear(color.xyz);
	gbuffer.emissive   = 0.0; // set for lit particles and world border
	gbuffer.skyLight   = v_AmbientLight.x;
	gbuffer.blockLight = v_AmbientLight.y;
	gbuffer.layer      = GBUFFER_LAYER_BASIC;

	outColor0 = renderGBuffer0(gbuffer);
	outColor1 = renderGBuffer1(gbuffer);
	outColor2 = renderGBuffer2(gbuffer);
	outColor3 = renderGBuffer3(gbuffer);
	outColor4 = renderGBuffer4(gbuffer);
}

/* RENDERTARGETS: 0,1,2,3,4 */

#endif // FSH
