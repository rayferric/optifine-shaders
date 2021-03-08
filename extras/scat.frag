#define PI 3.14159265359
#define INFINITY 1e12

// Dimensions
#define PLANET_RADIUS     6371e3
#define ATMOSPHERE_RADIUS 6471e3
#define RAYLEIGH_HEIGHT   8e3
#define MIE_HEIGHT        1.2e3
#define OZONE_LEVEL       30e3
#define OZONE_FALLOFF     3e3
// Scattering coefficients
#define RAY_BETA   vec3(3.8e-6, 13.5e-6, 33.1e-6) // vec3(5.5e-6, 13.0e-6, 22.4e-6)
#define MIE_BETA   vec3(21e-6)
#define OZONE_BETA vec3(2.04e-5, 4.97e-5, 1.95e-6)
#define G          0.76
// Samples
#define SAMPLES          32
#define LIGHT_SAMPLES    4

vec2 raySphereIntersect(in vec3 pos, in vec3 dir, in float radius);
vec3 densitiesRMO(in vec3 pos, in float radius, in float rayleighHeight, in float mieHeight, in float ozoneLevel, in float ozoneFalloff);
float rayleighPhase(float cosTheta);
float henyeyGreensteinPhase(float cosTheta, float g);

/**
 * Calculates atmospheric scattering value for a ray intersecting a planet.
 *
 * @param pos                 ray origin
 * @param dir                 ray direction
 * @param sunDir              light vector
 * @param energy              sun energy
 * @param scene               background color
 * @param depth               background depth
 * @param samples             primary ray sample count
 * @param secSamples          secondary ray sample count
 * @param rayBeta             Rayleigh coefficient (scattered sky color)
 * @param mieBeta             Mie coefficient (scattered sun color)
 * @param ozoneBeta           ozone absorption coefficient (absorbed color)
 * @param g                   Henyey-Greenstein scattering factor, controls size of the blob around the sun (0.76 is the sweet spot)
 * @param planetRadius        radius of the planet
 * @param atmosphereRadius    radius of the atmosphere, must be larger than planet radius
 * @param rayleighHeight      maximum height of influence for Rayleigh
 * @param mieHeight           maximum height of influence for Mie
 * @param ozoneLevel          at what height the ozone layer is most dense
 * @param ozoneFalloff        how ozone density decreases over distance
 * @return    background color after applying the scattering algorithm
 */
vec3 atmosphere(
	in vec3 pos,
	in vec3 dir,
	in vec3 sunDir,
	in vec3 energy,
	in vec3 scene,
	in float depth,
	in int samples,
	in int secSamples,
	in vec3 rayBeta,
	in vec3 mieBeta,
	in vec3 ozoneBeta,
	in float g,
	in float planetRadius,
	in float atmosphereRadius,
	in float rayleighHeight,
	in float mieHeight,
	in float ozoneLevel,
	in float ozoneFalloff
) {
	// Intersect the atmosphere
	vec2 intersect = raySphereIntersect(pos, dir, atmosphereRadius);
	if(intersect.x > intersect.y)return scene;
	
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

			vec3 lightDensities = densitiesRMO(lightSamplePos, planetRadius, rayleighHeight, mieHeight, ozoneLevel, ozoneFalloff) * lightStep;
			lightOpticalRMO += lightDensities;

			secRayPos += lightStep;
		}

		// Accumulate densities
		vec3 densities = densitiesRMO(samplePos, planetRadius, rayleighHeight, mieHeight, ozoneLevel, ozoneFalloff) * step;
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
	return max(light, 0.0) + scene * opacity;
}

/**
 * Henyey-Greenstein phase function, used for Mie scattering.
 *
 * @param cosTheta    cosine of the angle between light vector and view direction
 * @param g           scattering factor | -1 to 0 - backwards | 0 - isotropic | 0 to 1 - forward | 0.76 is the sweet spot
 * @return    Henyey-Greenstein phase function value
 */
float henyeyGreensteinPhase(in float cosTheta, in float g) {
	float gg = g * g;
	return (1.0 - gg) / (4.0 * PI * pow(1.0 + gg - 2.0 * g * cosTheta, 1.5));
}

/**
 * Rayleigh phase function, used for Rayleigh scattering.
 *
 * @param cosTheta    cosine of the angle between light vector and view direction
 * @return    Rayleigh phase function value
 */
float rayleighPhase(in float cosTheta) {
	return (3.0 * (1.0 + cosTheta * cosTheta)) / (16.0 * PI);
}

/**
 * Approximates density values for a given point around the sphere.
 *
 * @param pos               position of the point, for which densities are calculated
 * @param radius            radius of the sphere
 * @param rayleighHeight    maximum height of influence for Rayleigh
 * @param mieHeight         maximum height of influence for Mie
 * @param ozoneLevel        at what height the ozone layer is most dense
 * @param ozoneFalloff      how ozone density decreases over distance
 * @return    .x - Rayleigh density | .y - Mie density | .z - ozone density
 */
vec3 densitiesRMO(in vec3 pos, in float radius, in float rayleighHeight, in float mieHeight, in float ozoneLevel, in float ozoneFalloff) {
	float height = length(pos) - radius; // Height above surface
	vec3 density;
	density.x = exp(-height / rayleighHeight);
	density.y = exp(-height / mieHeight);
	density.z = (1.0 / cosh((ozoneLevel - height) / ozoneFalloff)) * density.x; // Ozone absorption scales with rayleigh
	return density;
}

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
 * Calculates view direction of a pixel based on its location.
 *
 * @param uv    fragment position in range <0, 1> on both axes
 * @return    normalized view direction
 */
vec3 viewDir(in vec2 uv, in float ratio) {
	// uv = uv * vec2(2.0) - vec2(1.0);
	// uv.x *= ratio;
	// return normalize(vec3(uv.x, uv.y, -1.0));

	vec2 t = ((uv * 2.0) - vec2(1.0)) * vec2(PI, PI * 0.5); 
	return vec3(cos(t.y) * cos(t.x), sin(t.y), cos(t.y) * sin(t.x));
}

vec4 render(in vec3 pos, in vec3 dir, in vec3 lightDir) {
	vec2 intersect = raySphereIntersect(pos, dir, PLANET_RADIUS);
	if(intersect.y < 0.0)return vec4(0.0, 0.0, 0.0, INFINITY);
	float depth = max(intersect.x, 0.0);
	vec3 color = vec3(0.0, 0.0, 0.0);
	return vec4(color, depth);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 uv = fragCoord.xy / iResolution.xy;

	vec3 pos = vec3(0.0, PLANET_RADIUS + 2.0, 0.0);
	vec3 dir = viewDir(uv, iResolution.x / iResolution.y);
	vec3 lightDir = iMouse.y == 0.0 ? 
		normalize(vec3(0.0, cos(-iTime/8.0), sin(-iTime/8.0))) : 
		normalize(vec3(0.0, cos(iMouse.y * -5.0 / iResolution.y), sin(iMouse.y * -5.0 / iResolution.y)));
	vec3 energy = vec3(64.0);
	
	vec4 scene = render(pos, dir, lightDir);
	vec3 color = scene.xyz;
	float depth = scene.w;
	color = atmosphere(pos, dir, lightDir, energy, color, depth, SAMPLES, LIGHT_SAMPLES, RAY_BETA, MIE_BETA, OZONE_BETA, G, PLANET_RADIUS, ATMOSPHERE_RADIUS, RAYLEIGH_HEIGHT, MIE_HEIGHT, OZONE_LEVEL, OZONE_FALLOFF);
	color = 1.0 - exp(-color);
	color = pow(color, vec3(1.0 / 2.2));
	
	fragColor = vec4(color, 1.0);
}