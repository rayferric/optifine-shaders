#ifndef RP_GLSL
#define RP_GLSL

#include "/src/modules/blocks.glsl"
#include "/src/modules/gamma.glsl"
#include "/src/modules/luminance.glsl"

struct RPSample {
	// color texture
	vec3  albedo;
	float opacity;

	// specular texture
	float smoothness, roughness;
	float metallic;
	float porosity;
	float subsurface;
	float emissive;

	// normals texture
	vec3  normal;
	float occlusion;
	float height;
};

RPSample
sampleVanillaPBR(in vec2 texCoord, in vec3 entity, in vec2 blockFacePos) {
	vec4 colorSample = texture(texture, texCoord);

	RPSample rp;
	rp.albedo     = gammaToLinear(colorSample.xyz);
	rp.opacity    = colorSample.w;
	rp.smoothness = 0.0;
	rp.roughness  = 0.8;
	rp.metallic   = 0.0;
	rp.porosity   = 0.0;
	rp.subsurface = 0.0;
	rp.emissive   = 0.0;
	rp.normal     = vec3(0.0, 0.0, 1.0);
	rp.occlusion  = 1.0;
	rp.height     = 0.0;

	int id = int(entity.x + 0.5);

	if (id == BLOCKS_CLEAR_GLASS) {
		if (rp.opacity < EPSILON) {
			// Fix albedo in the normally invisible area of clear glass.
			rp.albedo = vec3(1.0);
		}
		rp.roughness = 0.0;
	}

	if (id == BLOCKS_STAINED_GLASS) {
		rp.roughness = 0.0;
	}

	if (id == BLOCKS_METAL) {
		rp.metallic  = 1.0;
		rp.roughness = 0.2;
	}

	// automatic normal map generation
	if (id != BLOCKS_UNKNOWN && id != BLOCKS_CLEAR_GLASS) {
		rp.height = luminance(rp.albedo);

		vec2  pos   = abs(blockFacePos);
		float bound = max(pos.x, pos.y);
		if (bound < 0.494) {
			vec2 rightCoord =
			    vec2(texCoord.x + 0.1 / float(atlasSize.x), texCoord.y);
			vec2 upCoord =
			    vec2(texCoord.x, texCoord.y + 0.1 / float(atlasSize.y));
			float rightH =
			    luminance(gammaToLinear(texture(texture, rightCoord).xyz));
			float upH = luminance(gammaToLinear(texture(texture, upCoord).xyz));
			vec3  upVec    = vec3(0.0, 5.0, upH - rp.height);
			vec3  rightVec = vec3(5.0, 0.0, rightH - rp.height);
			rp.normal      = normalize(cross(rightVec, upVec));
		}
	}

	if (id == BLOCKS_STONE) {
		// Add low roughness spots for nice reflections underground.
		if (luminance(rp.albedo) < 0.18) {
			rp.roughness = 0.5;
		}
	}

	if (id == BLOCKS_HONEY) {
		rp.roughness = 0.2;
	}

	if (id == BLOCKS_LEAVES) {
		rp.roughness = 0.7;
	}

	if (id == BLOCKS_ICE) {
		float lum             = luminance(rp.albedo);
		float roughnessFactor = smoothstep(0.4, 0.7, lum);
		rp.roughness          = mix(0.1, 0.5, roughnessFactor);
	}

	return rp;
}

RPSample sampleLabPBR(in vec2 texCoord) {
	// See: https://wiki.shaderlabs.org/wiki/LabPBR_Material_Standard

	// Sample OptiFine textures.
	vec4 colorSample    = texture(texture, texCoord);
	vec4 specularSample = texture(specular, texCoord);
	vec4 normalsSample  = texture(normals, texCoord);

	// Extract LabPBR parameters.
	RPSample rp;

	// color texture
	rp.albedo  = gammaToLinear(colorSample.xyz);
	rp.opacity = colorSample.w;

	// specular texture
	// NOTE: rp.metallic is stored in range [0, 229].
	// [230, 255] are predefined conductors.
	// (229/255 is not intended to be remapped to 100%)
	// TODO: Implement F0 for predefined conductors. (Requires a custom
	// GBuffer.)
	// NOTE: rp.porosity and rp.subsurface use specularSample.z
	// directly instead of specularBlue to make use of texture filtering.
	// NOTE: rp.emissive is stored in range [0, 254].
	rp.smoothness     = specularSample.x;
	rp.roughness      = pow(1.0 - rp.smoothness, 2.0);
	int specularGreen = int(specularSample.y * 255.0 + 0.5);
	// bool isPredefined     = specularGreen >= 230; // 26 values
	rp.metallic = clamp(specularSample.y, 0.0, 1.0);
#ifndef MC_TEXTURE_FORMAT_LAB_PBR_1_3
	// Changelog:
	// LabPBR v1.3
	// F0 is now stored linearly.
	// Previously, linear F0 was stored by taking the square root of it and
	// decoded by squaring it.

	rp.metallic *= rp.metallic;
#endif
	int  specularBlue     = int(specularSample.z * 255.0 + 0.5);
	bool enablePorosity   = specularBlue <= 64; // 65 values
	bool enableSubsurface = specularBlue >= 65; // 191 values
	rp.porosity           = enablePorosity
	                          ? clamp((specularSample.z * 255.0) / 64.0, 0.0, 1.0)
	                          : 0.0;
	rp.subsurface =
	    enableSubsurface
	        ? clamp(
	              (specularSample.z * 255.0 - 65.0) / (255.0 - 65.0), 0.0, 1.0
	          )
	        : 0.0;
	rp.emissive = clamp(specularSample.w * 255.0 / 254.0, 0.0, 1.0);

	// normals texture
	// NOTE: LabPBR uses DirectX normal map format.
	rp.normal.x  = normalsSample.x * 2.0 - 1.0;
	rp.normal.y  = -(normalsSample.y * 2.0 - 1.0);
	rp.normal.z  = sqrt(1.0 - dot(rp.normal.xy, rp.normal.xy));
	rp.normal    = normalize(rp.normal);
	rp.occlusion = normalsSample.z;
	rp.height    = normalsSample.w;

	// TODO: Remap PBR values for Vanilla compatibility.
	return rp;
}

RPSample sampleRp(in vec2 texCoord, in vec3 entity, in vec2 blockFacePos) {
#if RP_MODE == 0 // Vanilla PBR
	return sampleVanillaPBR(texCoord, entity, blockFacePos);
#elif RP_MODE == 1 // LabPBR
	return sampleLabPBR(texCoord);
#endif
}

#endif // RP_GLSL