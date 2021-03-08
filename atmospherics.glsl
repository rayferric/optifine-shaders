#ifndef ATMOSPHERICS_GLSL
#define ATMOSPHERICS_GLSL

#define ATMOSPHERICS_RADIUS_PLANET     6371e3
#define ATMOSPHERICS_RADIUS_ATMOSPHERE 6471e3
#define ATMOSPHERICS_HEIGHT_RAY        8e3
#define ATMOSPHERICS_HEIGHT_MIE        1.2e3
#define ATMOSPHERICS_OZONE_LEVEL       30e3
#define ATMOSPHERICS_OZONE_FALLOFF     3e3

#define ATMOSPHERICS_BETA_RAY   vec3(5e-6, 13e-6, 23e-6)
#define ATMOSPHERICS_BETA_MIE   vec3(1e-6)
#define ATMOSPHERICS_BETA_OZONE vec3(2.04e-5, 4.97e-5, 1.95e-6)
#define ATMOSPHERICS_G          0.85

#define ATMOSPHERICS_SAMPLES          8
#define ATMOSPHERICS_SAMPLES_LIGHT    1

/**
 * Returns entry and exit points of ray intersecting a sphere.
 *
 * @param origin    ray origin
 * @param dir       normalized ray direction
 * @param radius    radius of the sphere
 * @return    .x - position of entry point relative to the ray origin | .y - position of exit point relative to the ray origin | if there's no intersection in front of the ray, .x is smaller than 0 | if there's no intersection at all, .x is larger than .y
 */
vec2 raySphereIntersect(in vec3 origin, in vec3 dir, in float radius) {
	float a = dot(dir, dir);
	float b = 2.0 * dot(dir, origin);
	float c = dot(origin, origin) - (radius * radius);
	float d = (b * b) - 4.0 * a * c;
	if(d < 0.0)return vec2(1.0, -1.0);
	return vec2(
		(-b - sqrt(d)) / (2.0 * a),
		(-b + sqrt(d)) / (2.0 * a)
	);
}

/**
 * Approximates density values for a given point around the sphere.
 *
 * @param pos             position of the point, for which densities are calculated
 * @param radius          radius of the sphere
 * @param rayHeight       maximum height of influence for Rayleigh
 * @param mieHeight       maximum height of influence for Mie
 * @param ozoneLevel      at what height the ozone layer is most dense
 * @param ozoneFalloff    how ozone density decreases over distance
 *
 * @return    .x - Rayleigh density | .y - Mie density | .z - ozone density
 */
vec3 densitiesRMO(in vec3 pos, in float radius, in float rayHeight, in float mieHeight, in float ozoneLevel, in float ozoneFalloff) {
	float height = length(pos) - radius; // Height above surface
	vec3 density;
	density.x = exp(-height / rayHeight);
	density.y = exp(-height / mieHeight);
    density.z = (1.0 / cosh((ozoneLevel - height) / ozoneFalloff)) * density.x; // Ozone absorption scales with rayleigh
    return density;
}

/**
 * Rayleigh phase function, used for Rayleigh scattering.
 *
 * @param cosTheta    cosine of the angle between light vector and view direction
 *
 * @return    Rayleigh phase function value
 */
float rayleighPhase(in float cosTheta) {
    return (3.0 * (1.0 + cosTheta * cosTheta)) / (16.0 * PI);
}

/**
 * Henyey-Greenstein phase function, used for Mie scattering.
 *
 * @param cosTheta    cosine of the angle between light vector and view direction
 * @param g           scattering factor | -1 to 0 - backwards | 0 - isotropic | 0 to 1 - forward | 0.76 is the sweet spot
 *
 * @return    Henyey-Greenstein phase function value
 */
float henyeyGreensteinPhase(in float cosTheta, in float g) {
	float gg = g * g;
	return (1.0 - gg) / (4.0 * PI * pow(1.0 + gg - 2.0 * g * cosTheta, 1.5));
}

/**
 * Calculates atmospheric scattering value for a ray intersecting a planet.
 *
 * @param color               background color
 * @param depth               background depth
 * @param pos                 ray origin
 * @param dir                 ray direction
 * @param sunDir              light vector
 * @param energy              sun energy
 * @param samples             primary ray sample count
 * @param secSamples          secondary ray sample count
 * @param rayBeta             Rayleigh coefficient (scattered sky color)
 * @param mieBeta             Mie coefficient (scattered sun color)
 * @param ozoneBeta           ozone absorption coefficient (absorbed color)
 * @param g                   Henyey-Greenstein scattering factor, controls size of the blob around the sun (0.76 is the sweet spot)
 * @param planetRadius        radius of the planet
 * @param atmosphereRadius    radius of the atmosphere, must be larger than planet radius
 * @param rayHeight           maximum height of influence for Rayleigh
 * @param mieHeight           maximum height of influence for Mie
 * @param ozoneLevel          at what height the ozone layer is most dense
 * @param ozoneFalloff        how ozone density decreases over distance
 *
 * @return    background color after applying the scattering algorithm
 */
vec3 atmosphere(
	in vec3 color,
	in float depth,
	in vec3 pos,
	in vec3 dir,
	in vec3 sunDir,
	in vec3 energy,
	in int samples,
	in int secSamples,
	in vec3 rayBeta,
	in vec3 mieBeta,
	in vec3 ozoneBeta,
	in float g,
	in float planetRadius,
	in float atmosphereRadius,
	in float rayHeight,
	in float mieHeight,
	in float ozoneLevel,
	in float ozoneFalloff
) {
	// Intersect the atmosphere
    vec2 intersect = raySphereIntersect(pos, dir, atmosphereRadius);
    if(intersect.x > intersect.y)return color;
    
	float rayPos = max(intersect.x, 0.0);
	float step = (min(intersect.y, depth) - rayPos) / float(samples); // min(intersect.y, depth) ensures that the tracing ends on collision

	// Accumulators
	vec3 opticalRMO = vec3(0.0); // Optical depth (accumulated density) of Rayleigh, Mie and ozone
    vec3 sumR = vec3(0.0);
    vec3 sumM = vec3(0.0);
    
    for(int i = 0; i < samples; i++) {
        vec3 samplePos = pos + dir * (rayPos + step * 0.5); // Current sampling position

		// Similar to the primary iteration
		vec2 secIntersect = raySphereIntersect(samplePos, sunDir, atmosphereRadius); // No need to check if intersection happened as we already are inside the sphere

		float secRayPos = 0.0; // secIntersect.x < 0, so max(secIntersect.x, 0.0) = 0
        float lightStep = secIntersect.y / float(secSamples);

        vec3 lightOpticalRMO = vec3(0.0);
        
        for(int j = 0; j < secSamples; j++) {
            vec3 lightSamplePos = samplePos + sunDir * (secRayPos + lightStep * 0.5);

			vec3 lightDensities = densitiesRMO(lightSamplePos, planetRadius, rayHeight, mieHeight, ozoneLevel, ozoneFalloff) * lightStep;
			lightOpticalRMO += lightDensities;

            secRayPos += lightStep;
        }

		// Accumulate densities
		vec3 densities = densitiesRMO(samplePos, planetRadius, rayHeight, mieHeight, ozoneLevel, ozoneFalloff) * step;
		opticalRMO += densities;

		// Accumulate scattered light scaled by proper density factors
        vec3 scattered = exp(-(rayBeta * (opticalRMO.x + lightOpticalRMO.x) + mieBeta * (opticalRMO.y + lightOpticalRMO.y) + ozoneBeta * (opticalRMO.z + lightOpticalRMO.z)));
        sumR += scattered * densities.x;
        sumM += scattered * densities.y;

        rayPos += step;
    }

	// Apply phase functions
    float cosTheta = dot(dir, sunDir);
    float rayPhase = rayleighPhase(cosTheta);
    float miePhase = henyeyGreensteinPhase(cosTheta, g);
	
    // How much light can pass through the atmosphere
    vec3 opacity = exp(-(rayBeta * opticalRMO.x + mieBeta * opticalRMO.y + ozoneBeta * opticalRMO.z));

	vec3 light = (
        rayPhase * rayBeta * sumR + // Rayleigh color
       	miePhase * mieBeta * sumM   // Mie color
    ) * energy;
    return max(light, 0.0) + color * opacity;
}

vec3 getSkyEnergy(in vec3 dir) {
	//return vec3(0.3, 0.8, 1.0) * 8.0;

	vec3 color = vec3(0.0);
    float depth = INFINITY;

	vec3 pos = vec3(0.0, ATMOSPHERICS_RADIUS_PLANET + 2.0, 0.0);
	dir = (gbufferModelViewInverse * vec4(dir, 0.0)).xyz;
	vec3 lightDir = (gbufferModelViewInverse * vec4(normalize(shadowLightPosition), 0.0)).xyz;
	vec3 energy = vec3(SUN_ILLUMINANCE) * 5.0;
	
	return atmosphere(
		color, depth, pos, dir, lightDir, energy,
		ATMOSPHERICS_SAMPLES,
		ATMOSPHERICS_SAMPLES_LIGHT,
		ATMOSPHERICS_BETA_RAY,
		ATMOSPHERICS_BETA_MIE,
		ATMOSPHERICS_BETA_OZONE,
		ATMOSPHERICS_G,
		ATMOSPHERICS_RADIUS_PLANET,
		ATMOSPHERICS_RADIUS_ATMOSPHERE,
		ATMOSPHERICS_HEIGHT_RAY,
		ATMOSPHERICS_HEIGHT_MIE,
		ATMOSPHERICS_OZONE_LEVEL,
		ATMOSPHERICS_OZONE_FALLOFF
	);
}

vec3 avgSkyRadiance() {
	return vec3(0.3, 0.8, 1.0) * 8.0;
}

#endif // ATMOSPHERICS_GLSL