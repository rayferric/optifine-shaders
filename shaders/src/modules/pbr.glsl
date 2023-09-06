#ifndef PBR_GLSL
#define PBR_GLSL

#include "/src/modules/rand_cone_dir.glsl"

/**
 * @brief Approximates fresnel factor using Schlick's method.
 *
 * @param cosTheta non-negative cosine of the view angle
 *
 * @return fresnel factor
 */
float fresnelSchlick(in float cosTheta) {
	return pow(1.0 - cosTheta, 5.0);
}

/**
 * @brief Applies fresnel factor to specularity.
 * See: https://learnopengl.com/PBR/Lighting
 *
 * @param cosTheta  non-negative cosine of the view angle
 * @param specular  specularity
 *
 * @return angle-dependent specularity
 */
vec3 fresnelSchlick(float cosTheta, vec3 specular) {
	return mix(vec3(fresnelSchlick(cosTheta)), vec3(1.0), specular);
}

/**
 * @brief Applies fresnel factor to specularity while accounting for roughness.
 * See: https://learnopengl.com/PBR/IBL/Diffuse-irradiance
 *
 * @param cosTheta  non-negative cosine of the view angle
 * @param specular  specularity
 * @param roughness material roughness
 *
 * @return angle-dependent specularity
 */
vec3 fresnelSchlick(float cosTheta, vec3 specular, float roughness) {
	vec3 one = max(vec3(1.0 - roughness), specular); // = 1 without roughness
	return specular + (one - specular) * fresnelSchlick(cosTheta);
}

/**
 * @brief Computes GGX (Trowbridge-Reitz) normal distribution.
 *
 * @param cosTheta  non-negative cosine of the halfway angle
 * @param roughness material roughness
 *
 * @return normal distribution
 */
float distributionGgx(in float cosTheta, in float roughness) {
	float r2 = roughness * roughness;
	float r4 = r2 * r2;

	float cosTheta2 = cosTheta * cosTheta;
	float d         = mix(1.0, r4, cosTheta * cosTheta);

	return r4 / (PI * d * d);
}

/**
 * @brief Single term for Smith's geometric shadowing
 * approximation function below: Schlick-GGX.
 *
 * @param cosTheta  non-negative cosine of the angle
 * @param roughness material roughness
 *
 * @return partial value
 */
float geometrySmithG1(in float cosTheta, in float roughness) {
	return cosTheta / mix(cosTheta, 1.0, roughness);
}

/**
 * @brief Approximates geometric shadowing using
 * Smith's method with Schlick-GGX terms.
 *
 * @param cosNl     non-negative cosine of the light angle
 * @param cosNe     non-negative cosine of the eye angle
 * @param roughness material roughness
 *
 * @return geometric shadowing
 */
float geometrySmith(in float cosNl, in float cosNe, in float roughness) {
	float r = (roughness + 1.0);
	float k = (r * r) / 8.0;
	return geometrySmithG1(cosNl, k) * geometrySmithG1(cosNe, k);
}

vec3 importanceLambert(in vec2 rand, in vec3 normal) {
	float theta = acos(2.0 * rand.x - 1.0) * 0.5;
	return randConeDir(rand.y, normal, cos(theta));
}

vec3 importanceGgx(
    in vec2 rand, in vec3 normal, in vec3 outcoming, in float roughness
) {
	roughness *= roughness;
	roughness *= roughness;

	float cosTheta = sqrt((1.0 - rand.x) / (1.0 + (roughness - 1.0) * rand.x));
	vec3  halfway  = randConeDir(rand.y, normal, cosTheta);

	return reflect(-outcoming, halfway);
}

// Approximates the two specular BRDF sub-integrals shown here:
// https://learnopengl.com/PBR/IBL/Specular-IBL
// .x = specular scale
// .y = specular bias

vec2 approxBrdf(float cosNe, float roughness) {
	vec2 uv = vec2(cosNe, roughness);

	// base red brdf
	vec2 brdf = vec2(1.0, 0.0);

	// green radial gradient in the bottom-left corner
	float gradFactor =
	    pow(1.0 - 0.707 * distance(uv * vec2(1.0, 0.6), vec2(0.0, 0.0)), 6.0);
	brdf = mix(brdf, vec2(0.0, 1.0), gradFactor);

	// dark red gradient in the top-right corner
	gradFactor =
	    pow(1.0 - 0.707 * distance(uv * vec2(0.6, 1.0), vec2(0.9 * 0.6, 1.0)),
	        2.0) *
	    0.7;
	brdf = mix(brdf, vec2(0.0), gradFactor);

	// dark green triangle at the bottom-left corner, next to the left edge
	vec2 coneNormal = normalize(vec2(0.15, 1.0));
	vec2 uvNormal   = normalize(uv);
	gradFactor      = pow(dot(coneNormal, uvNormal), 30.0) * 0.3;
	brdf            = mix(brdf, vec2(0.0), gradFactor);

	return brdf;
}

/**
 * @brief Computes light contribution using the Cook-Torrance method.
 *
 * @param albedo    material albedo
 * @param roughness material roughness
 * @param metallic  material metallic factor
 * @param normal    surface normal
 * @param lightDir  direction towards the light
 * @param eyeDir    direction towards the camera
 *
 * @return light contribution
 */
vec3 directContribution(
    in vec3  albedo,
    in float roughness,
    in float metallic,
    in float transmissive,
    in vec3  normal,
    in vec3  eyeDir,
    in vec3  lightDir,
    in bool  fakeSss
) {
	vec3 halfwayDir = normalize(lightDir + eyeDir);

	float cosNl = max(dot(normal, lightDir), 0.0);
	float cosNe = max(dot(normal, eyeDir), 0.0);
	float cosNh = max(dot(normal, halfwayDir), 0.0);
	float cosHe = max(dot(halfwayDir, eyeDir), 0.0);

	vec3 specular = mix(vec3(0.04), albedo, metallic);
	specular      = fresnelSchlick(cosHe, specular);
	vec3 diffuse  = (vec3(1.0) - specular) * (1.0 - metallic) * albedo;
	// vec3 transmitted = diffuse * transmissive;
	// diffuse          -= transmitted;
	diffuse *= (1.0 - transmissive); // equivalent

	float d = distributionGgx(cosNh, roughness);
	float g = geometrySmith(cosNl, cosNe, roughness);

	diffuse  = diffuse / PI;
	specular = specular * d * g / max(4.0 * cosNe * cosNl, EPSILON);

	diffuse  *= (fakeSss ? 1.0 : cosNl);
	specular *= (fakeSss ? 1.0 : cosNl);

	return max(diffuse + specular, 0.0);
}

struct IndirectContribution {
	vec3 diffuse;
	vec3 specular;
	vec3 transmitted;
};

IndirectContribution indirectContribution(
    in vec3  albedo,
    in float roughness,
    in float metallic,
    in float transmissive,
    in vec3  normal,
    in vec3  eyeDir
) {
	float cosNe = max(dot(normal, eyeDir), 0.0);

	vec3 specular = mix(vec3(0.04), albedo, metallic);
	specular      = fresnelSchlick(cosNe, specular, roughness);

	vec3 diffuse = (vec3(1.0) - specular) * (1.0 - metallic) * albedo;

	vec2 brdf = approxBrdf(cosNe, roughness);
	specular  = specular * brdf.x + brdf.y;

	vec3 transmitted = diffuse * transmissive;
	diffuse          -= transmitted;

	return IndirectContribution(diffuse, specular, transmitted);
}

#endif // PBR_GLSL
