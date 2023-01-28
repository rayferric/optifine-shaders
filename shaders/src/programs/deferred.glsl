varying vec2 v_TexCoord;

///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

void main() {
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/src/modules/atmospherics.glsl"
#include "/src/modules/encode.glsl"
#include "/src/modules/gamma.glsl"
#include "/src/modules/kelvin_to_rgb.glsl"
#include "/src/modules/material_mask.glsl"
#include "/src/modules/pbr.glsl"
#include "/src/modules/screen_to_view.glsl"
#include "/src/modules/shadow.glsl"
#include "/src/modules/ssao.glsl"

/* DRAWBUFFERS:1 */

// Opaque shading pass

void main() {
	float depth = texture2D(depthtex0, v_TexCoord).x;
	vec3 viewPos = screenToView(v_TexCoord, depth);
	vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

	vec3 viewDir = normalize(-viewPos);
	vec3 lightDir = normalize(shadowLightPosition);

	if (depth == 1.0) { // Sky
		gl_FragData[0].xyz = sky(worldPos, lightDir) * SUN_ILLUMINANCE * 10.0;
		// gl_FragData[0].xyz =  vec3(0.0);
		gl_FragData[0].w   = 1.0;

		// vec4 clouds = traceClouds(worldPos, lightDir);
		// clouds.xyz *= SUN_ILLUMINANCE * 10.0;
		// gl_FragData[0].xyz = mix(gl_FragData[0].xyz, clouds.xyz, clouds.w);
	} else {
		vec3 normal = decodeNormal(texture2D(colortex2, v_TexCoord).xy);

		vec3 albedoOpacityRm = texture2D(colortex3, v_TexCoord).xyz;
		vec2 rg = decode8BitVec2(albedoOpacityRm.x);
		vec2 bo = decode8BitVec2(albedoOpacityRm.y);
		vec2 rm = decode8BitVec2(albedoOpacityRm.z);
		vec3 albedo     = gammaToLinear(vec3(rg, bo.x));
		float opacity   = bo.y;
		float roughness = rm.x;
		float metallic  = rm.y;

		vec3 ambientLightMask = texture2D(colortex4, v_TexCoord).xyz;
		vec2 ambientLight = gammaToLinear(ambientLightMask.xy);
		MaterialMask mask = decodeMask(ambientLightMask.z);

		float cosNv = max(dot(normal, viewDir), 0.0);

		vec3 coloredShadowLightIlluminance = kelvinToRgb(SUN_TEMPERATURE) * SUN_ILLUMINANCE;
		vec3 coloredBlockIlluminance  = kelvinToRgb(BLOCK_TEMPERATURE) * BLOCK_ILLUMINANCE;

		vec3 shadowLightColor = softShadow(worldPos, normal, lightDir, mask.isFoliage);
		if (!mask.isFoliage)
			shadowLightColor *= contactShadow(viewPos, lightDir);
		vec3 shadowLightContribution = cookTorrance(albedo, roughness, metallic, normal, lightDir, viewDir, mask.isFoliage);
		vec3 shadowLightEnergy = (coloredShadowLightIlluminance * shadowLightColor) * shadowLightContribution;
		shadowLightEnergy *= smoothstep(0.0, 0.01, ambientLight.x); // Cave light leak fix

		// Ambient specular energy is computed in composite
		vec3 specular = mix(vec3(0.04), albedo, metallic);
		specular = fresnelSchlick(cosNv, specular, roughness);
		vec3 ambientDiffuseContribution = (vec3(1.0) - specular) * (1.0 - metallic) * albedo;
		vec3 skyDiffuseEnergy   = (coloredShadowLightIlluminance * 0.125 * ambientLight.x) * ambientDiffuseContribution;
		vec3 blockDiffuseEnergy = (coloredBlockIlluminance * ambientLight.y) * ambientDiffuseContribution;
		vec3 emissionEnergy     = mask.isEmissive ? albedo * EMISSION_ILLUMINANCE : vec3(0.0);
		emissionEnergy *= emissionEnergy;
		vec3 ambientEnergy = 0.025 * ambientDiffuseContribution;
		ambientEnergy = vec3(0.0);

		skyDiffuseEnergy *= computeSsao(viewPos, normal, depthtex0);

		vec3 totalEnergy = shadowLightEnergy + skyDiffuseEnergy + blockDiffuseEnergy + emissionEnergy + ambientEnergy;
		// totalEnergy = mix(totalEnergy, vec3(SUN_ILLUMINANCE * 10.0), atmosphere(worldPos, lightDir, false));

		vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
		float fogFactor = smoothstep(far - 24.0 - 50.0, far - 24.0, length(worldPos));
		// if (fogFactor > EPSILON) {
		// 	vec3 skyEnergy = atmosphere(worldPos, lightDir, true) * SUN_ILLUMINANCE * 10.0;
		// 	totalEnergy = mix(totalEnergy, skyEnergy, fogFactor);
		// }

		// colortex1: HDR Buffer
		gl_FragData[0].xyz = totalEnergy;
		gl_FragData[0].w   = 1.0;
	}
}

#endif // FSH
