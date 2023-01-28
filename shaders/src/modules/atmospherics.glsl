#ifndef ATMOSPHERICS_GLSL
#define ATMOSPHERICS_GLSL

#include "/src/modules/cosh.glsl"
#include "/src/modules/hash.glsl"
#include "/src/modules/shadow.glsl"

// Dimensions
#define ATMOSPHERICS_PLANET_RADIUS     6371e3
#define ATMOSPHERICS_ATMOSPHERE_HEIGHT 100e3
#define ATMOSPHERICS_RAYLEIGH_HEIGHT   8e3
#define ATMOSPHERICS_MIE_HEIGHT        1.2e3
#define ATMOSPHERICS_OZONE_PEAK_LEVEL  30e3
#define ATMOSPHERICS_OZONE_FALLOFF     3e3
#define ATMOSPHERICS_VIEW_HEIGHT       2.0

// Probabilities of scattering each RGB wavelength of light for every type of moleque
#define ATMOSPHERICS_RAYLEIGH_PROB vec3(2e-6, 6e-6, 12e-6)
#define ATMOSPHERICS_MIE_PROB      vec3(20e-6) // e-6
#define ATMOSPHERICS_OZONE_PROB    vec3(2.04e-5, 4.97e-5, 1.95e-6)

// Henyey Greenstein scattering function coefficient
#define ATMOSPHERICS_G -0.8

// Samples
#define ATMOSPHERICS_SKY_SAMPLES   3
#define ATMOSPHERICS_FOG_SAMPLES   8
#define ATMOSPHERICS_LIGHT_SAMPLES 1 // Set to more than 1 for a realistic, less vibrant sunset

// Clouds
#define ATMOSPHERICS_CLOUD_PLANE_LEVEL 1e3
#define ATMOSPHERICS_CLOUD_PLANE_HEIGHT 1e3
#define ATMOSPHERICS_CLOUD_SAMPLES 16
#define ATMOSPHERICS_CLOUD_COVERAGE 0.5

const float atmosphereRadius = ATMOSPHERICS_PLANET_RADIUS + ATMOSPHERICS_ATMOSPHERE_HEIGHT;

// 0 indicates shadow light switch
// float getSunHeight() { // Sunrise: 23215; Sunset: 12785
// 	// int time = (worldTime + 785 + 6000) % 24000; // Range <0, 23999> with midnight at 0 and noon at 12000
// 	// if(time >= 12000)time = 23999 - time; // Range <0, 11999>, both 0 and 11999 occur two times in a row
// 	// return (time / 11999.0) * 2.0 - 1.0; // Range <-1, 1>
// 	if(23215 <= worldTime || worldTime < 12785) { // Day time
// 		int time = (worldTime + 785) % 24000;
// 		return 1.0 - abs(1.0 - 2.0 * (time / 13570.0));
// 	} else { // Night time
// 		int time = worldTime - 12785;
// 		return -(1.0 - abs(1.0 - 2.0 * (time / 10430.0)));
// 	}
// }

struct Intersection {
	float near, far;
};

/**
 * Computes entry and exit points of ray intersecting a sphere.
 *
 * @param origin    ray origin
 * @param dir       normalized ray direction
 * @param radius    radius of the sphere
 *
 * @return    .near - position of entry point relative to the ray origin | .far - position of exit point relative to the ray origin | if there's no intersection at all, .x is larger than .y
 */
Intersection raySphereIntersect(in vec3 origin, in vec3 dir, in float radius) {
	float a = dot(dir, dir);
	float b = 2.0 * dot(dir, origin);
	float c = dot(origin, origin) - (radius * radius);

	float d = (b * b) - 4.0 * a * c;
	if(d < 0.0) 
		return Intersection(1.0, -1.0);
	
	return Intersection(
		(-b - sqrt(d)) / (2.0 * a),
		(-b + sqrt(d)) / (2.0 * a)
	);
}

/**
 * Phase function used for Rayleigh scattering.
 *
 * @param cosTheta cosine of the angle between light vector and view direction
 *
 * @return Rayleigh phase function value
 */
float phaseRayleigh(in float cosTheta) {
	return (1.0 + cosTheta * cosTheta) * (3.0 / (16.0 * PI));
}

/**
 * Henyey-Greenstein phase function, used for Mie/cloud scattering.
 *
 * @param cosTheta cosine of the angle between light vector and view direction
 * @param g        scattering factor | -1 to 0 - backward | 0 - isotropic | 0 to 1 - forward
 *
 * @return Henyey-Greenstein phase function value
 */
float phaseHenyeyGreenstein(in float cosTheta, in float g) {
	float gg = g * g;
	return (1.0 - gg) / (4.0 * PI * pow(1.0 + gg - 2.0 * g * cosTheta, -1.5));
}

/**
 * Approximates density values for a given point around the planet.
 *
 * @param pos    position of the point, for which densities are calculated
 *
 * @return    .x - Rayleigh density | .y - Mie density | .z - ozone density
 */
vec3 avgDensities(in vec3 pos) {
	float height = length(pos) - ATMOSPHERICS_PLANET_RADIUS; // Height above surface

	vec3 density;
	density.x = exp(-height / ATMOSPHERICS_RAYLEIGH_HEIGHT);
	density.y = exp(-height / ATMOSPHERICS_MIE_HEIGHT);
	density.z = (1.0 / cosh((ATMOSPHERICS_OZONE_PEAK_LEVEL - height) / ATMOSPHERICS_OZONE_FALLOFF)) * density.x; // Ozone absorption scales with rayleigh
	return density;
}

// float noise3D(in vec3 value) {
// 	vec3 f = floor(value);
// 	vec3 c = ceil(value);
// 	vec3 m = smoothstep(0.0, 1.0, fract(value));

// 	// Cube vertices
// 	float fXfYfZ = hash(vec3(f.x, f.y, f.z));
// 	float fXfYcZ = hash(vec3(f.x, f.y, c.z));
// 	float fXcYfZ = hash(vec3(f.x, c.y, f.z));
// 	float fXcYcZ = hash(vec3(f.x, c.y, c.z));
// 	float cXfYfZ = hash(vec3(c.x, f.y, f.z));
// 	float cXfYcZ = hash(vec3(c.x, f.y, c.z));
// 	float cXcYfZ = hash(vec3(c.x, c.y, f.z));
// 	float cXcYcZ = hash(vec3(c.x, c.y, c.z));
	
// 	// Z mix
// 	float fXfY = mix(fXfYfZ, fXfYcZ, m.z);
// 	float fXcY = mix(fXcYfZ, fXcYcZ, m.z);
// 	float cXfY = mix(cXfYfZ, cXfYcZ, m.z);
// 	float cXcY = mix(cXcYfZ, cXcYcZ, m.z);

// 	// Y mix
// 	float fX = mix(fXfY, fXcY, m.y);
// 	float cX = mix(cXfY, cXcY, m.y);

// 	// X mix
// 	return mix(fX, cX, m.x);
// }

// float cloudCoverage(in vec2 pos, in vec2 windOffset) {
// 	float density = 0.0;
// 	density += texture2D(noisetex, pos * 0.000001 + windOffset * 0.000001).x;
// 	density += texture2D(noisetex, pos * 0.000004 + windOffset * 0.000003).x;
// 	density += texture2D(noisetex, pos * 0.000009 + windOffset * 0.000008).x;
// 	density *= 0.33;
// 	density = max(density - (1.0 - ATMOSPHERICS_CLOUD_COVERAGE), 0.0) / ATMOSPHERICS_CLOUD_COVERAGE;

//     return density;
// }

// float cloudHeightFalloff(in float height) {
// 	float root1 = ATMOSPHERICS_PLANET_RADIUS + ATMOSPHERICS_CLOUD_PLANE_LEVEL;
// 	float root2 = root1 + ATMOSPHERICS_CLOUD_PLANE_HEIGHT;

// 	// Parabola with vertex at [(root1 + root2) / 2, 1]
// 	return -4.0 * (height - root1) * (height - root2) /
// 			(ATMOSPHERICS_CLOUD_PLANE_HEIGHT * ATMOSPHERICS_CLOUD_PLANE_HEIGHT);
// }

// float cloudDensity(in vec3 pos) {
//     vec2 windOffset = vec2(frameTimeCounter) * 30.0;

// 	float density = cloudCoverage(pos.xz, windOffset);
// 	density *= cloudHeightFalloff(pos.y);
// 	density *= max(noise3D(pos * 0.01 + vec3(windOffset.x * 0.01, 0.0, windOffset.y * 0.01)), 0.2);

//     return density;
// }

/**
 * Calculates atmospheric scattering value for a ray intersecting the planet.
 * This function is used to calculate the sky color or trace volumetric fog.
 *
 * @param pos      ray origin
 * @param dir      ray direction
 * @param lightDir light vector
 *
 * @return sky color
 */
vec3 sky(
		in vec3 worldPos,
		in vec3 lightDir) {
	vec3 traceDir = normalize(worldPos);
	lightDir = mat3(gbufferModelViewInverse) * lightDir;

	vec3 eyePos = vec3(0.0, ATMOSPHERICS_PLANET_RADIUS + ATMOSPHERICS_VIEW_HEIGHT, 0.0);
	Intersection intersection = raySphereIntersect(eyePos, traceDir, ATMOSPHERICS_PLANET_RADIUS + ATMOSPHERICS_ATMOSPHERE_HEIGHT);
	if (intersection.near > intersection.far)
		return vec3(0.0);

	float rayPos = max(intersection.near, 0.0);
	float stepSize = (intersection.far - rayPos) / float(ATMOSPHERICS_SKY_SAMPLES);
	// Let's sample near the center for temporal stability
	rayPos += stepSize * mix(0.48, 0.52, hash(worldPos * frameTimeCounter));

	vec3 scatteredRayleigh = vec3(0.0);
	vec3 scatteredMie      = vec3(0.0);
	vec3 viewOpticalDepth  = vec3(0.0);

	for (int i = 0; i < ATMOSPHERICS_SKY_SAMPLES; i++) {
		vec3 samplePos = traceDir * rayPos; // Current sampling position
		rayPos += stepSize;

		Intersection lightIntersection = raySphereIntersect(eyePos + samplePos, lightDir, ATMOSPHERICS_PLANET_RADIUS + ATMOSPHERICS_ATMOSPHERE_HEIGHT);
		float lightStepSize = lightIntersection.far / float(ATMOSPHERICS_LIGHT_SAMPLES);
		// Let's always sample in the center for temporal stability
		float lightRayPos = lightStepSize * 0.5;

		vec3 lightOpticalDepth = vec3(0.0);
		for (int j = 0; j < ATMOSPHERICS_LIGHT_SAMPLES; j++) {
			vec3 lightSamplePos = samplePos + lightDir * lightRayPos;
			lightRayPos += lightStepSize;

			lightOpticalDepth += avgDensities(eyePos + lightSamplePos) * lightStepSize;
		}

		vec3 opticalDepth = avgDensities(eyePos + samplePos) * stepSize;
		viewOpticalDepth += opticalDepth;

		// What fraction of light survived outscattering caused by all three types
		// of moleques along the whole path from eye to sun (modeled using Beer's law)
		// Ozone actually absorbs the light without emitting
		// it again, but both phenomena are modeled in the same way
		vec3 lightAfterOutScattering = exp(-(
				ATMOSPHERICS_RAYLEIGH_PROB * (viewOpticalDepth.x + lightOpticalDepth.x) +
				ATMOSPHERICS_MIE_PROB * (viewOpticalDepth.y + lightOpticalDepth.y) +
				ATMOSPHERICS_OZONE_PROB * (viewOpticalDepth.z + lightOpticalDepth.z)));

		scatteredRayleigh += lightAfterOutScattering * opticalDepth.x;
		scatteredMie      += lightAfterOutScattering * opticalDepth.y;
		// Ozone does not scatter light but fully absorbs it instead
	}
	// scatteredRayleigh and scatteredMie are actually half-products needed for optimization
	// "optical depth * probabilities * phase" is the complete fraction of light that was in-scattered

	float cosTheta = dot(traceDir, lightDir);
	return scatteredRayleigh * ATMOSPHERICS_RAYLEIGH_PROB * phaseRayleigh(cosTheta) +
	       scatteredMie      * ATMOSPHERICS_MIE_PROB      * phaseHenyeyGreenstein(cosTheta, ATMOSPHERICS_G);
}



// vec4 traceClouds(
// 	in vec3 worldPos,
// 	in vec3 lightDir
// ) {
// 	vec3 eyePos = vec3(0.0, ATMOSPHERICS_PLANET_RADIUS + ATMOSPHERICS_VIEW_HEIGHT, 0.0);
// 	vec3 traceDir = normalize(worldPos);
// 	lightDir = mat3(gbufferModelViewInverse) * lightDir;

// 	float opacity = smoothstep(0.05, 0.1, traceDir.y);
//     if (opacity < EPSILON)
//         return vec4(0.0);
    
//     vec2 startIntersection = raySphereIntersect(eyePos, traceDir, ATMOSPHERICS_PLANET_RADIUS + ATMOSPHERICS_CLOUD_PLANE_LEVEL);
//     vec2 endIntersection = raySphereIntersect(eyePos, traceDir, ATMOSPHERICS_PLANET_RADIUS + ATMOSPHERICS_CLOUD_PLANE_LEVEL + ATMOSPHERICS_CLOUD_PLANE_HEIGHT);

//     float rayPos = startIntersection.y;
// 	float stepSize = (endIntersection.y - rayPos) / float(ATMOSPHERICS_CLOUD_SAMPLES;
//     rayPos += stepSize * hash(worldPos * frameTimeCounter);
    
//     vec4 energy = vec4(0.0);
//     vec3 cloudColor = vec3(1.0);
// 	float opticalDepth = 0.0;
// 	float CLOUD_ABSORBED_COLOR = 2.0;
// 	float earlyEndOpticalDepthThreshold = -log(0.05) / CLOUD_ABSORBED_COLOR / stepSize;
    
//     for (int i = 0; i < ATMOSPHERICS_CLOUD_SAMPLES; i++) {
//         vec3 samplePos = traceDir * rayPos; // Current sampling position
//         rayPos += stepSize;
        
// 		float lightStep = 20.0 / float(ATMOSPHERICS_LIGHT_SAMPLES);
// 		float lightRayPos = lightStep * 0.5; // Let's sample in the center

// 		for (int i = 0; i < ATMOSPHERICS_LIGHT_SAMPLES; i++) {
// 			vec3 lightSamplePos = samplePos + lightDir * lightRayPos;
// 			lightRayPos += lightStep;

// 		}

//         float density = cloudDensity(eyePos + samplePos);
// 		opticalDepth += density;

//         energy.xyz += (1.0 - energy.w) * density * cloudColor;
        
//         // End early
// 		// float absorption = exp(-(CLOUD_ABSORBED_COLOR * opticalDepth * stepSize));
// 		// if (absorption < 0.05)
//         if (opticalDepth > earlyEndOpticalDepthThreshold)
//             break;
//     }

// 	// Beer's law
// 	float absorption = exp(-(CLOUD_ABSORBED_COLOR * opticalDepth * stepSize));
// 	energy.w = 1.0 - absorption;
// 	energy.w *= opacity;

//     return energy;
// }

// /**
//  * Draws a blackbody as seen from the planet.
//  *
//  * @param dir      ray direction
//  * @param lightDir light vector
//  *
//  * @return blackbody color
//  */
// float renderBlackbody(in vec3 dir, in vec3 lightDir) {
// 	float cosSun = cos(radians(SUN_ANGULAR_RADIUS));
// 	float cosTheta = dot(dir, lightDir);

// 	return step(cosSun, cosTheta);
// }

// /**
//  * Calculates daylight factor at given sun height.
//  *
//  * @param sunHeight sun height
//  *
//  * @return daylight factor in range <0.0, 1.0>
//  */
// float getDayFactor(in float sunHeight) {
// 	return pow(smoothstep(-0.6, 0.6, sunHeight), 8.0);
// }

// /**
//  * Computes shadow light illuminance at given sun height.
//  *
//  * @param sunHeight sun height
//  *
//  * @return shadow light illuminance
//  */
// float getShadowIlluminance() {
// 	return mix(MOON_ILLUMINANCE, SUN_ILLUMINANCE, getDayFactor(getSunHeight() - 0.2));
// }

// vec3 getShadowColoredIlluminance() {
// 	vec3 coloredSunIlluminance = kelvinToRgb(SUN_TEMPERATURE) * SUN_ILLUMINANCE;
// 	vec3 coloredMoonIlluminance = kelvinToRgb(MOON_TEMPERATURE) * MOON_ILLUMINANCE;

// 	return mix(coloredMoonIlluminance, coloredSunIlluminance, getDayFactor(getSunHeight() - 0.2));
// }

// // Used to hide shadows while switching light sources
// float getShadowSwitchFactor() {
// 	float sunHeight = getSunHeight();
// 	return 1.0 - (smoothstep(-0.05, 0.0, sunHeight) - smoothstep(0.0, 0.05, sunHeight));
// }

// vec3 avgSkyRadiance() {
// 	return vec3(0.4, 0.8, 1.0) * getShadowIlluminance() * 0.125;
// }

// Post-scattered color of the sky used as reflection fallback
// vec3 getSkyEnergy(in vec3 dir) {
// 	vec3 pos = vec3(0.0, ATMOSPHERICS_PLANET_RADIUS + 2.0, 0.0);

// 	dir = mat3(gbufferModelViewInverse) * dir;
// 	dir.y = dir.y < 0.03 ? (dir.y - 0.03) * 0.2 + 0.03 : dir.y;
// 	vec3 shadowLightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

// 	vec3 sky = renderBlackbody(dir, sunDir) * SUN_COLOR + renderBlackbody(dir, moonDir) * MOON_COLOR;
// 	sky += atmosphere(pos, dir, shadowLightDir) * SUN_COLOR; // TODO use proper scattering function

// 	return sky;
// }

// The unscattered color of the sky
// vec3 getSpaceEnergy(in vec3 dir) {
// 	vec3 pos = vec3(0.0, ATMOSPHERICS_PLANET_RADIUS + 2.0, 0.0);

// 	dir = mat3(gbufferModelViewInverse) * dir;
// 	dir.y = dir.y < 0.03 ? (dir.y - 0.03) * 0.2 + 0.03 : dir.y;
// 	vec3 sunDir = mat3(gbufferModelViewInverse) * normalize(sunPosition);
// 	vec3 moonDir = mat3(gbufferModelViewInverse) * normalize(moonPosition);

// 	return renderBlackbody(dir, sunDir) * SUN_COLOR + renderBlackbody(dir, moonDir) * MOON_COLOR;
// }

#endif // ATMOSPHERICS_GLSL
