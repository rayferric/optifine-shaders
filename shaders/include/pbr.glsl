#ifndef PBR_GLSL
#define PBR_GLSL

// Fresnel function: Schlick
vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

// Fresnel function accounting for roughness: Schlick
vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness) {
	return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
} 

// Fresnel strength function: Schlick
float fresnelSchlickStrength(float cosTheta, float F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

// Normal distribution function: GGX (Towbridge-Reitz) 
float distributionGGX(float NdotH, float roughness) {
    float a  = roughness * roughness;
    float a2 = a * a;
	
    float d = (NdotH * NdotH) * (a2 - 1.0) + 1.0;
    return a2 / (PI * d * d);
}

// Single term for the Smith (Schlick-GGX) equation below.
float geometrySmithG1(float cosTheta, float k) {
    return cosTheta / (cosTheta * (1.0 - k) + k);
}

// Geometric shadowing approximation function: Smith (Schlick-GGX).
float geometrySmith(float NdotV, float NdotL, float roughness) {
	float r = (roughness + 1.0);
    float k = (r * r) / 8.0;
	return geometrySmithG1(NdotV, k) * geometrySmithG1(NdotL, k);
}

// Light contribution: Cook-Torrance
vec3 cookTorrance(vec3 albedo, float roughness, float metallic, float NdotV, float NdotL, float NdotH, float HdotV) {
	vec3 F0 = mix(vec3(0.04), albedo, metallic);
	vec3 F  = fresnelSchlick(HdotV, F0);

	float D = distributionGGX(NdotH, roughness);
	float G = geometrySmith(NdotV, NdotL, roughness);

	vec3 kD = (vec3(1.0) - F) * (1.0 - metallic) / PI;
	vec3 kS = F;

	vec3 diffuseBRDF  = kD * albedo;
	vec3 specularBRDF = kS * ((D * G) / max(4.0 * NdotV * NdotL, EPSILON));  
		
	return max(diffuseBRDF + specularBRDF, 0.0);
}

#endif // PBR_GLSL