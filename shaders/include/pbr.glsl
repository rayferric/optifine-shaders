#ifndef PBR_GLSL
#define PBR_GLSL

/**
 * Approximates fresnel factor using Schlick's method.
 *
 * @param NdotV non-negative cosine of the view angle
 *
 * @return fresnel factor
 */
float fresnelSchlickFactor(in float NdotV) {
	return pow(1.0 - NdotV, 5.0);
}

/**
 * Applies Schlick's fresnel factor to specularity.
 *
 * @param NdotV     non-negative cosine of the view angle
 * @param specular  specularity
 * @param roughness material roughness
 *
 * @return angle-dependent specularity
 */
vec3 fresnelSchlick(in float NdotV, in vec3 specular, in float roughness) {
	return mix(specular, max(vec3(1.0 - roughness), specular), fresnelSchlickFactor(NdotV));
}

/**
 * Computes GGX (Trowbridge-Reitz) normal distribution.
 *
 * @param NdotH     non-negative cosine of the halfway angle
 * @param roughness material roughness
 *
 * @return normal distribution
 */
float distributionGGX(in float NdotH, in float roughness) {
	float r2 = roughness * roughness;
	float r4 = r2 * r2;
	float d = mix(1.0, r4, cosTheta * cosTheta);
	return r4 / (PI * d * d);
}

/**
 * Single term for Smith's geometric shadowing
 * approximation function below: Schlick-GGX.
 *
 * @param cosTheta  non-negative cosine of the angle
 * @param roughness material roughness
 *
 * @return partial value
 */
float geometrySmithG1(in float cosTheta, in float roughness) {
	return cosTheta / mix(roughness, 1.0, cosTheta);
}

/**
 * Approximates geometric shadowing using
 * Smith's method with Schlick-GGX terms.
 *
 * @param NdotV     non-negative cosine of the view angle
 * @param NdotL     non-negative cosine of the shadow angle
 * @param roughness material roughness
 *
 * @return Geometric shadowing
 */
float geometrySmith(in float NdotV, in float NdotL, in float roughness) {
	float r = (roughness + 1.0);
	float k = (r * r) / 8.0;
	return geometrySmithG1(NdotV, k) * geometrySmithG1(NdotL, k);
}

/**
 * Computes light contribution using the Cook-Torrance method.
 *
 * @param albedo    material albedo
 * @param roughness material roughness
 * @param metallic  material metallic factor
 * @param NdotV     non-negative cosine of the view angle
 * @param NdotL     non-negative cosine of the shadow angle
 * @param NdotH     non-negative cosine of the normal-halfway angle
 * @param HdotV     non-negative cosine of the halfway-view angle
 *
 * @return light contribution
 */
vec3 cookTorrance(in vec3 albedo, in float roughness, in float metallic, in float NdotV, in float NdotL, in float NdotH, in float HdotV) {
	vec3 specular = mix(vec3(0.04), albedo, metallic);
	specular = fresnelSchlick(HdotV, specular, roughness);

	float D = distributionGGX(NdotH, roughness);
	float G = geometrySmith(NdotV, NdotL, roughness);

	vec3 diffuseEnergy  = (vec3(1.0) - specular) * (1.0 - metallic) * albedo / PI;
	vec3 specularEnergy = specular * D * G / max(4.0 * NdotV * NdotL, EPSILON);  
		
	return max(diffuseEnergy + specularEnergy, 0.0);
}

#endif // PBR_GLSL
