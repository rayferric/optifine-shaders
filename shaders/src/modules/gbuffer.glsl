#ifndef GBUFFER_GLSL
#define GBUFFER_GLSL

#include "/src/modules/dither.glsl"
#include "/src/modules/gamma.glsl"
#include "/src/modules/pack.glsl"

// GBuffer layout:
// const int colortex0Format = RGB8;    // albedo
// const int colortex1Format = RG16;    // normal
// const int colortex2Format = RGB8;    // roughness, metallic, subsurface
// const int colortex3Format = RGB8;    // emissive, occlusion, transmissive
// const int colortex4Format = RGB8;    // sky light, block light, ID
// See: /src/common/_optifine.glsl

#define GBUFFER_LAYER_SKY         0 // sky, clouds, sun, moon
#define GBUFFER_LAYER_OPAQUE      1 // opaque, alpha-test
#define GBUFFER_LAYER_TRANSLUCENT 2 // alpha-blend
#define GBUFFER_LAYER_BASIC       3 // lines, particles
#define GBUFFER_LAYER_WATER       4 // volumetric water
#define GBUFFER_LAYER_ICE         5 // volumetric ice

/**
 * @brief Classifies materials.
 */
struct GBuffer {
	vec3 albedo;

	vec3 normal;

	float occlusion; // only opaque
	float roughness;
	float metallic; // only opaque

	float subsurface;   // only opaque
	float emissive;     // only opaque
	float transmissive; // only translucent

	float skyLight;
	float blockLight;
	int   layer;

	float opacity; // only basic surfaces
};

#ifdef DEFERRED
GBuffer sampleGBuffer(in vec2 texCoord) {
	GBuffer gbuffer;

	vec4 sample0 = texture(colortex0, texCoord);
	vec4 sample1 = texture(colortex1, texCoord);
	vec4 sample2 = texture(colortex2, texCoord);
	vec4 sample3 = texture(colortex3, texCoord);
	vec4 sample4 = texture(colortex4, texCoord);

	gbuffer.albedo = gammaToLinear(sample0.xyz);

	gbuffer.normal = unpackNormal(sample1.xy);

	gbuffer.occlusion = gammaToLinear(sample2.x);
	gbuffer.roughness = sample2.y;
	gbuffer.metallic  = sample2.z;

	gbuffer.subsurface   = sample2.x;
	gbuffer.emissive     = sample3.y;
	gbuffer.transmissive = sample3.z;

	gbuffer.skyLight   = gammaToLinear(sample4.x);
	gbuffer.blockLight = gammaToLinear(sample4.y);
	gbuffer.layer      = int(sample4.z * 255.0 + 0.5);

	return gbuffer;
}
#endif

#ifdef FORWARD
vec4 renderGBuffer0(in GBuffer gbuffer) {
	vec3 data = linearToGamma(gbuffer.albedo);
	return vec4(data, 1.0);
}

vec4 renderGBuffer1(in GBuffer gbuffer) {
	vec2 data = packNormal(gbuffer.normal);
	return vec4(data, 0.0, 1.0);
}

vec4 renderGBuffer2(in GBuffer gbuffer) {
	vec3 data = vec3(
	    linearToGamma(gbuffer.occlusion), gbuffer.roughness, gbuffer.metallic
	);
	return vec4(data, 1.0);
}

vec4 renderGBuffer3(in GBuffer gbuffer) {
	vec3 data =
	    vec3(gbuffer.subsurface, gbuffer.emissive, gbuffer.transmissive);
	return vec4(data, 1.0);
}

vec4 renderGBuffer4(in GBuffer gbuffer) {
	vec3 data = vec3(
	    gbuffer.skyLight, gbuffer.blockLight, float(gbuffer.layer) / 255.0
	);
	data.x = dither8X8(data.x, ivec2(gl_FragCoord.xy), 255);
	data.y = dither8X8(data.y, ivec2(gl_FragCoord.xy), 255);
	return vec4(data, 1.0);
}
#endif

#endif // GBUFFER_GLSL
