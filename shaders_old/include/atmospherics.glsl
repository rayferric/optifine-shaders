#ifndef ATMOSPHERICS_GLSL
#define ATMOSPHERICS_GLSL

// Dimensions
#define SKY_PLANET_RADIUS     6371e3
#define SKY_ATMOSPHERE_HEIGHT 100e3
#define SKY_RAYLEIGH_HEIGHT   8e3
#define SKY_MIE_HEIGHT        1.2e3
#define SKY_OZONE_PEAK_LEVEL  30e3
#define SKY_OZONE_FALLOFF     3e3
// Scattering coefficients
#define SKY_BETA_RAY   vec3(4e-6, 10e-6, 27e-6) // vec3(5.5e-6, 13.0e-6, 22.4e-6) // vec3(3.8e-6, 13.5e-6, 33.1e-6) // vec3(5.5e-6, 13.0e-6, 22.4e-6)
#define SKY_BETA_MIE   vec3(21e-6)
#define SKY_BETA_OZONE vec3(2.04e-5, 4.97e-5, 1.95e-6)
#define SKY_G          0.5
// Samples
#define SKY_SAMPLES          4
#define SKY_LIGHT_SAMPLES    4 // Set to more than 1 for a realistic, less vibrant sunset

const float ATMOSPHERE_RADIUS = SKY_PLANET_RADIUS + SKY_ATMOSPHERE_HEIGHT;

// 0 indicates shadow light switch
float getSunHeight() { // Sunrise: 23215; Sunset: 12785
	// int time = (worldTime + 785 + 6000) % 24000; // Range <0, 23999> with midnight at 0 and noon at 12000
	// if(time >= 12000)time = 23999 - time; // Range <0, 11999>, both 0 and 11999 occur two times in a row
	// return (time / 11999.0) * 2.0 - 1.0; // Range <-1, 1>
	if(23215 <= worldTime || worldTime < 12785) { // Day time
		int time = (worldTime + 785) % 24000;
		return 1.0 - abs(1.0 - 2.0 * (time / 13570.0));
	} else { // Night time
		int time = worldTime - 12785;
		return -(1.0 - abs(1.0 - 2.0 * (time / 10430.0)));
	}
}

/**
 * Computes entry and exit points of ray intersecting a sphere.
 *
 * @param origin    ray origin
 * @param dir       normalized ray direction
 * @param radius    radius of the sphere
 *
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
 * Phase function used for Rayleigh scattering.
 *
 * @param cosTheta    cosine of the angle between light vector and view direction
 *
 * @return    Rayleigh phase function value
 */
float phaseR(in float cosTheta) {
	return (3.0 * (1.0 + cosTheta * cosTheta)) / (16.0 * PI);
}

/**
 * Henyey-Greenstein phase function, used for Mie scattering.
 *
 * @param cosTheta    cosine of the angle between light vector and view direction
 * @param g           scattering factor | -1 to 0 - backward | 0 - isotropic | 0 to 1 - forward
 *
 * @return    Henyey-Greenstein phase function value
 */
float phaseM(in float cosTheta, in float g) {
	float gg = g * g;
	return (1.0 - gg) / (4.0 * PI * pow(1.0 + gg - 2.0 * g * cosTheta, 1.5));
}

/**
 * Approximates density values for a given point around the planet.
 *
 * @param pos    position of the point, for which densities are calculated
 *
 * @return    .x - Rayleigh density | .y - Mie density | .z - ozone density
 */
vec3 avgDensities(in vec3 pos) {
	float height = length(pos) - SKY_PLANET_RADIUS; // Height above surface
	vec3 density;
	density.x = exp(-height / SKY_RAYLEIGH_HEIGHT);
	density.y = exp(-height / SKY_MIE_HEIGHT);
	density.z = (1.0 / cosh((SKY_OZONE_PEAK_LEVEL - height) / SKY_OZONE_FALLOFF)) * density.x; // Ozone absorption scales with rayleigh
	return density;
}

/**
 * Calculates atmospheric scattering value for a ray intersecting the planet.
 *
 * @param pos         ray origin
 * @param dir         ray direction
 * @param lightDir    light vector
 *
 * @return    sky color
 */
vec3 atmosphere(
	in vec3 pos,
	in vec3 dir,
	in vec3 lightDir
) {
	// Intersect the atmosphere
	vec2 intersect = raySphereIntersect(pos, dir, ATMOSPHERE_RADIUS);

	// Accumulators
	vec3 opticalDepth = vec3(0.0); // Accumulated density of particles participating in Rayleigh, Mie and ozone scattering respectively
	vec3 sumR = vec3(0.0);
	vec3 sumM = vec3(0.0);
	
	// Here's the trick - we clamp the sampling length to keep precision at the horizon
	// This introduces banding, but we can compensate for that by scaling the clamp according to horizon angle
	float rayPos = max(0.0, intersect.x);
	float maxLen = SKY_ATMOSPHERE_HEIGHT;
	maxLen *= (1.0 - abs(dir.y) * 0.5);
	float stepSize = min(intersect.y - rayPos, maxLen) / float(SKY_SAMPLES);
	rayPos += stepSize * 0.5; // Let's sample in the center
	
	for(int i = 0; i < SKY_SAMPLES; i++) {
		vec3 samplePos = pos + dir * rayPos; // Current sampling position

		// Similar to the primary iteration
		vec2 lightIntersect = raySphereIntersect(samplePos, lightDir, ATMOSPHERE_RADIUS); // No need to check if intersection happened as we already are inside the sphere

		vec3 lightOpticalDepth = vec3(0.0);

		// We're inside the sphere now, hence we don't have to clamp ray pos
		float lightStep = lightIntersect.y / float(SKY_LIGHT_SAMPLES);
		float lightRayPos = lightStep * 0.5; // Let's sample in the center

		for(int j = 0; j < SKY_LIGHT_SAMPLES; j++) {
			vec3 lightSamplePos = samplePos + lightDir * (lightRayPos);

			lightOpticalDepth += avgDensities(lightSamplePos) * lightStep;

			lightRayPos += lightStep;
		}

		// Accumulate optical depth
		vec3 densities = avgDensities(samplePos) * stepSize;
		opticalDepth += densities;

		// Accumulate scattered light
		vec3 scattered = exp(-(SKY_BETA_RAY * (opticalDepth.x + lightOpticalDepth.x) + SKY_BETA_MIE * (opticalDepth.y + lightOpticalDepth.y) + SKY_BETA_OZONE * (opticalDepth.z + lightOpticalDepth.z)));
		sumR += scattered * densities.x;
		sumM += scattered * densities.y;

		rayPos += stepSize;
	}

	float cosTheta = dot(dir, lightDir);
	
	return max(
		phaseR(cosTheta)        * SKY_BETA_RAY * sumR + // Rayleigh color
	   	phaseM(cosTheta, SKY_G) * SKY_BETA_MIE * sumM,  // Mie color
		0.0
	);
}

/**
 * Draws a blackbody as seen from the planet.
 *
 * @param dir         ray direction
 * @param lightDir    light vector
 *
 * @return    blackbody color
 */
float renderBlackbody(in vec3 dir, in vec3 lightDir) {
	float cosSun = cos(radians(SUN_ANGULAR_RADIUS));
	float cosTheta = dot(dir, lightDir);

	return step(cosSun, cosTheta);
}

/**
 * Calculates daylight factor at given sun height.
 *
 * @param sunHeight    sun height
 *
 * @return    daylight factor in range <0.0, 1.0>
 */
float getDayFactor(in float sunHeight) {
	return pow(smoothstep(-0.6, 0.6, sunHeight), 8.0);
}

/**
 * Computes shadow light illuminance at given sun height.
 *
 * @param sunHeight    sun height
 *
 * @return    shadow light illuminance
 */
float getShadowIlluminance() {
	return mix(MOON_ILLUMINANCE, SUN_ILLUMINANCE, getDayFactor(getSunHeight() - 0.2));
}

float getShadowSwitchFactor() { // Hide shadows while switching
	float sunHeight = getSunHeight();
	return 1.0 - (smoothstep(-0.05, 0.0, sunHeight) - smoothstep(0.0, 0.05, sunHeight));
}

vec3 avgSkyRadiance() {
	return vec3(0.4, 0.8, 1.0) * getShadowIlluminance() * 0.125;
}

// Post-scattered color of the sky used as reflection fallback
vec3 getSkyEnergy(in vec3 dir) {
	vec3 pos = vec3(0.0, SKY_PLANET_RADIUS + 2.0, 0.0);

	dir = mat3(gbufferModelViewInverse) * dir;
	dir.y = dir.y < 0.03 ? (dir.y - 0.03) * 0.2 + 0.03 : dir.y;
	vec3 sunDir = mat3(gbufferModelViewInverse) * normalize(sunPosition);
	vec3 moonDir = mat3(gbufferModelViewInverse) * normalize(moonPosition);

	vec3 sky = renderBlackbody(dir, sunDir) * SUN_COLOR + renderBlackbody(dir, moonDir) * MOON_COLOR;
	sky += atmosphere(pos, dir, sunDir) * SUN_COLOR; // TODO use proper scattering function
	sky += atmosphere(pos, dir, moonDir) * MOON_COLOR; // TODO use proper scattering function

	return sky;
}

// The unscattered color of the sky
vec3 getSpaceEnergy(in vec3 dir) {
	vec3 pos = vec3(0.0, SKY_PLANET_RADIUS + 2.0, 0.0);

	dir = mat3(gbufferModelViewInverse) * dir;
	dir.y = dir.y < 0.03 ? (dir.y - 0.03) * 0.2 + 0.03 : dir.y;
	vec3 sunDir = mat3(gbufferModelViewInverse) * normalize(sunPosition);
	vec3 moonDir = mat3(gbufferModelViewInverse) * normalize(moonPosition);

	return renderBlackbody(dir, sunDir) * SUN_COLOR + renderBlackbody(dir, moonDir) * MOON_COLOR;
}

#endif // ATMOSPHERICS_GLSL