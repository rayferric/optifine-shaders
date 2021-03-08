#ifndef ATMOSPHERICS_GLSL
#define ATMOSPHERICS_GLSL

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

// Looks similar to a normalized S Curve
float getDayFactor(in float exponent = 16.0, in float shift = -0.125) {
	float height = getSunHeight() + shift;
	height = clamp(height, -1.0, 1.0);
	return (sign(height) * (1.0 - pow(1.0 - abs(height), exponent))) * 0.5 + 0.5;
}

float getRiseFactor(in float width = 0.2, in float exponent = 4.0) {
	// return min(pow(1.0 - abs(getSunHeight()) + margin, exponent), 1.0);
	float height = abs(getSunHeight());
	return (1.0 - pow(1.0 - (cos(height * PI / width) * 0.5 + 0.5), exponent)) * float(-width < height && height < width);
}

vec3 getHorizonEnergy(in vec3 sunDir) {
	vec3 night = vec3(0.2, 0.35, 0.45) * 0.125;
	vec3 day = vec3(0.7, 0.8, 0.9);

	float dayFac = getDayFactor(8.0);

	return mix(night, day, dayFac);
}

vec3 getDomeEnergy(in vec3 sunDir) {
	vec3 night = vec3(0.05, 0.15, 0.2) * 0.125;
	vec3 day = vec3(0.3, 0.5, 0.8);

	float dayFac = getDayFactor(8.0);

	return mix(night, day, dayFac);
}

vec3 getSunEnergy(in vec3 sunDir) {
	vec3 up = vec3(1.0, 1.0, 0.9);
	vec3 rise = vec3(1.0, 0.3, 0.0);

	float riseFac = pow(1.0 - abs(sunDir.y), 4.0);

	return mix(up, rise, riseFac);
}

vec3 getMoonEnergy(in vec3 moonDir) {
	vec3 up = vec3(0.9, 1.0, 1.0);
	vec3 rise = vec3(0.9, 1.0, 1.0);

	float riseFac = pow(1.0 - abs(moonDir.y), 4.0);

	return mix(up, rise, riseFac);
}

// Public interface begins here

vec3 avgSkyRadiance() {
	vec3 night = MOON_COLOR;
	vec3 day = SUN_COLOR;

	float dayFac = getDayFactor(32.0, -0.125);

	return vec3(0.4, 0.8, 1.0) * mix(night, day, dayFac) * 0.125;
}

float getShadowLightEnergy() {
	float riseFac = getRiseFactor(0.15, 4.0);
	float dayFac = getDayFactor(32.0, -0.125);

	return mix(MOON_ILLUMINANCE, SUN_ILLUMINANCE, dayFac) * (1.0 - riseFac);
}

vec3 getSkyEnergy(in vec3 dir) {
	dir = (gbufferModelViewInverse * vec4(dir, 0.0)).xyz;
	vec3 sunDir = (gbufferModelViewInverse * vec4(normalize(sunPosition), 0.0)).xyz;
	vec3 moonDir = (gbufferModelViewInverse * vec4(normalize(moonPosition), 0.0)).xyz;

	float domeFac = 1.0 - pow(1.0 - max(dir.y, 0.0), 4.0);
	float sunFac = pow(max(dot(dir, sunDir), 0.0), 8.0);
	float moonFac = pow(max(dot(dir, moonDir), 0.0), 8.0);

	vec3 sky = mix(getHorizonEnergy(sunDir), getDomeEnergy(sunDir), domeFac);
	//sky += getSunEnergy(sunDir) * sunFac;
	//sky += getMoonEnergy(moonDir) * moonFac;

	//return vec3(0.0);
	return sky * getShadowLightEnergy() * 0.125;
}

#endif // ATMOSPHERICS_GLSL