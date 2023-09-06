varying vec4 v_Color;
varying vec2 v_TexCoord;
varying vec2 v_AmbientLight;
varying mat3 v_TBN;
varying vec3 v_Entity;

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

	vec3 normal   = gl_NormalMatrix * gl_Normal;
	vec3 tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(cross(normal, tangent) * at_tangent.w);
	v_TBN         = mat3(tangent, binormal, normal);

	v_Entity = mc_Entity;

	gl_Position = ftransform();
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/src/modules/blocks.glsl"
#include "/src/modules/constants.glsl"
#include "/src/modules/gamma.glsl"
#include "/src/modules/gbuffer.glsl"
#include "/src/modules/rp.glsl"

void main() {
	RPSample rp = sampleRp(v_TexCoord);

	GBuffer gbuffer;
	gbuffer.albedo = rp.albedo * gammaToLinear(v_Color.xyz);
	gbuffer.normal = normalize(v_TBN * rp.normal);
	// gbuffer.occlusion    = rp.occlusion;
	gbuffer.roughness = rp.roughness;
	// gbuffer.metallic     = rp.metallic;
	// gbuffer.subsurface   = rp.subsurface;
	// gbuffer.emissive     = rp.emissive;
	gbuffer.transmissive = 1.0 - pow(rp.opacity * v_Color.w, 2.0);
	gbuffer.skyLight     = v_AmbientLight.x;
	gbuffer.blockLight   = v_AmbientLight.y;
	gbuffer.layer        = GBUFFER_LAYER_TRANSLUCENT;

	if (v_Entity.x == BLOCKS_WATER) {
		gbuffer.roughness = 0.0;
		gbuffer.layer     = GBUFFER_LAYER_WATER;
	}

	outColor0 = renderGBuffer0(gbuffer);
	outColor1 = renderGBuffer1(gbuffer);
	outColor2 = renderGBuffer2(gbuffer);
	outColor3 = renderGBuffer3(gbuffer);
	outColor4 = renderGBuffer4(gbuffer);
}

/* RENDERTARGETS: 0,1,2,3,4 */

#endif // FSH
