#ifndef PBR_GLSL
#define PBR_GLSL

// Fresnel factor function: Schlick
float fresnelSchlickFactor(in float cosTheta) {
	return pow(1.0 - cosTheta, 5.0);
}

// Fresnel function: Schlick
vec3 fresnelSchlick(in float cosTheta, in vec3 specular) {
	return mix(specular, vec3(1.0), fresnelSchlickFactor(cosTheta));
}

// Fresnel function accounting for roughness: Schlick
vec3 fresnelSchlick(in float cosTheta, in vec3 specular, in float roughness) {
	return mix(specular, max(vec3(1.0 - roughness), specular), fresnelSchlickFactor(cosTheta));
}

// Normal distribution function: GGX (Towbridge-Reitz) 
float distributionGGX(in float cosTheta, in float roughness) {
	float r2 = roughness * roughness;
	float r4 = r2 * r2;
	float d = mix(1.0, r4, cosTheta * cosTheta);
	return r4 / (PI * d * d);
}

// Single term for the Smith function below: Schlick-GGX.
float geometrySmithG1(in float cosTheta, in float k) {
	return cosTheta / mix(k, 1.0, cosTheta);
}

// Geometric shadowing approximation: Smith + Schlick-GGX.
float geometrySmith(in float NdotV, in float NdotL, in float roughness) {
	float r = (roughness + 1.0);
	float k = (r * r) / 8.0;
	return geometrySmithG1(NdotV, k) * geometrySmithG1(NdotL, k);
}

// Light contribution: Cook-Torrance
vec3 cookTorrance(in vec3 albedo, in float roughness, in float metallic, in float NdotV, in float NdotL, in float NdotH, in float HdotV) {
	vec3 specular = mix(vec3(0.04), albedo, metallic);
	specular = fresnelSchlick(HdotV, specular);

	float D = distributionGGX(NdotH, roughness);
	float G = geometrySmith(NdotV, NdotL, roughness);

	vec3 diffuseEnergy  = (vec3(1.0) - specular) * (1.0 - metallic) * albedo / PI;
	vec3 specularEnergy = specular * D * G / max(4.0 * NdotV * NdotL, EPSILON);  
		
	return max(diffuseEnergy + specularEnergy, 0.0);
}

#endif // PBR_GLSL
