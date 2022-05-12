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

#include "/include/modules/encode.glsl"
#include "/include/modules/gamma.glsl"
#include "/include/modules/kelvin_to_rgb.glsl"
#include "/include/modules/material_mask.glsl"
#include "/include/modules/pbr.glsl"
#include "/include/modules/screen_to_view.glsl"
#include "/include/modules/shadow.glsl"
#include "/include/modules/ssr.glsl"

/* DRAWBUFFERS:1 */

// Translucent shading + translucent and opaque reflections

void main() {
	float depth = texture2D(depthtex0, v_TexCoord).x;
	if (depth == 1.0) { // Sky
		gl_FragData[0] = texture2D(colortex1, v_TexCoord);
		return;
	}

	vec3 normal = decodeNormal(texture2D(colortex2, v_TexCoord).xy);

	vec3 albedoOpacityRm = texture2D(colortex3, v_TexCoord).xyz;
	vec2 rg = decodeVec2(albedoOpacityRm.x);
	vec2 bo = decodeVec2(albedoOpacityRm.y);
	vec2 rm = decodeVec2(albedoOpacityRm.z);
	vec3 albedo     = gammaToLinear(vec3(rg, bo.x));
	float opacity   = bo.y;
	float roughness = rm.x;
	float metallic  = rm.y;

	vec3 ambientLightMask = texture2D(colortex4, v_TexCoord).xyz;
	vec2 ambientLight = gammaToLinear(ambientLightMask.xy);
	MaterialMask mask = decodeMask(ambientLightMask.z);

	vec3 viewPos = screenToView(v_TexCoord, depth);

	vec3 lightDir = normalize(shadowLightPosition);
	vec3 viewDir = normalize(-viewPos);
	vec3 refractionDir = refract(viewDir, normal, 1.0);

	float cosNv = max(dot(normal, viewDir), 0.0);
	vec3 specular = mix(vec3(0.04), albedo, metallic);
	specular = fresnelSchlick(cosNv, specular, roughness);

	vec3 hdr = vec3(0.0);

	if (roughness < 0.5)
		hdr += specular * computeSSReflection(colortex1, depthtex0, viewPos, normal, roughness);

	if (mask.isTranslucent) {
		vec3 coloredShadowIlluminance = kelvinToRgb(SUN_TEMPERATURE) * SUN_ILLUMINANCE;
		vec3 coloredTorchIlluminance  = kelvinToRgb(TORCH_TEMPERATURE) * TORCH_ILLUMINANCE;

		vec3 shadowColor = softShadow(viewPos, normal, lightDir);
		shadowColor *= contactShadow(viewPos, lightDir);
		vec3 shadowContribution = cookTorrance(albedo, roughness, metallic, normal, lightDir, viewDir);
		vec3 shadowEnergy = (coloredShadowIlluminance * shadowColor) * shadowContribution;
		
		vec3 ambientDiffuseContribution = (vec3(1.0) - specular) * (1.0 - metallic) * albedo;
		vec3 skyDiffuseEnergy   = (coloredShadowIlluminance * 0.125 * ambientLight.x) * ambientDiffuseContribution;
		vec3 torchDiffuseEnergy = (coloredTorchIlluminance * ambientLight.y) * ambientDiffuseContribution;

		hdr += shadowEnergy + skyDiffuseEnergy + torchDiffuseEnergy;
		hdr = mix(texture2D(colortex1, v_TexCoord).xyz * albedo, hdr, opacity);
	} else {
		hdr += texture2D(colortex1, v_TexCoord).xyz;
	}

	// colortex1: HDR Buffer
	gl_FragData[0].xyz = hdr;
	gl_FragData[0].w   = 1.0;
}

#endif // FSH
