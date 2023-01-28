#ifndef PBR_GLSL
#define PBR_GLSL

/**
 * Approximates fresnel factor using Schlick's method.
 *
 * @param cosTheta non-negative cosine of the view angle
 *
 * @return fresnel factor
 */
float fresnelSchlick(in float cosTheta) {
	return pow(1.0 - cosTheta, 5.0);
}

/**
 * Applies fresnel factor to specularity.
 *
 * @param cosTheta  non-negative cosine of the view angle
 * @param specular  specularity
 * @param roughness material roughness
 *
 * @return angle-dependent specularity
 */
vec3 fresnelSchlick(in float cosTheta, in vec3 specular, in float roughness) {
	return mix(specular, max(vec3(1.0 - roughness), specular), fresnelSchlick(cosTheta));
}

/**
 * Computes GGX (Trowbridge-Reitz) normal distribution.
 *
 * @param cosTheta  non-negative cosine of the halfway angle
 * @param roughness material roughness
 *
 * @return normal distribution
 */
float distributionGgx(in float cosTheta, in float roughness) {
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
 * @param cosNl     non-negative cosine of the shadow angle
 * @param cosNv     non-negative cosine of the view angle
 * @param roughness material roughness
 *
 * @return geometric shadowing
 */
float geometrySmith(in float cosNl, in float cosNv, in float roughness) {
	float r = (roughness + 1.0);
	float k = (r * r) / 8.0;
	return geometrySmithG1(cosNl, k) * geometrySmithG1(cosNv, k);
}

/**
 * Computes light contribution using the Cook-Torrance method.
 *
 * @param albedo    material albedo
 * @param roughness material roughness
 * @param metallic  material metallic factor
 * @param normal    surface normal
 * @param lightDir  direction towards the light
 * @param viewDir   direction towards the camera
 *
 * @return light contribution
 */
vec3 cookTorrance(
		in vec3  albedo,
		in float roughness,
		in float metallic,
		in vec3  normal,
		in vec3  lightDir,
		in vec3  viewDir,
		in bool  fakeSss
		) {
	vec3 halfwayDir = normalize(lightDir + viewDir);
	
	float cosNl = max(dot(normal, lightDir), 0.0);
	float cosNv = max(dot(normal, viewDir), 0.0);
	float cosNh = max(dot(normal, halfwayDir), 0.0);
	float cosVh = max(dot(viewDir, halfwayDir), 0.0);

	vec3 specular = mix(vec3(0.04), albedo, metallic);
	specular = fresnelSchlick(cosVh, specular, roughness);
	vec3 diffuse = (vec3(1.0) - specular) * (1.0 - metallic) * albedo;

	float D = distributionGgx(cosNh, roughness);
	float G = geometrySmith(cosNv, cosNl, roughness);

	vec3 diffuseEnergy  = diffuse * (fakeSss ? 1.0 : cosNl) / PI;
	vec3 specularEnergy = specular * D * G / max(4.0 * cosNv * cosNl, EPSILON);  
		
	return max(diffuseEnergy + specularEnergy, 0.0);
}

vec3 cookTorrance(
		in vec3  albedo,
		in float roughness,
		in float metallic,
		in vec3  normal,
		in vec3  lightDir,
		in vec3  viewDir) {
	return cookTorrance(albedo, roughness, metallic, normal, lightDir, viewDir, false);
}

#endif // PBR_GLSL
