#ifndef SKY_GLSL
#define SKY_GLSL

#include "/src/modules/constants.glsl"
#include "/src/modules/curve.glsl"
#include "/src/modules/hash.glsl"
#include "/src/modules/henyey_greenstein.glsl"
#include "/src/modules/intersection.glsl"
#include "/src/modules/luminance.glsl"

// luminance factors
#define SKY_SUN_LUMINANCE   10.0
#define SKY_MOON_LUMINANCE  0.005
#define SKY_STARS_LUMINANCE 0.01

float simpleTonemap(in float value) {
	return 1.0 - exp(-1.5 * value);
}

#define SKY_COLOR          vec3(0.0, 0.3, 0.8)
#define SKY_ACCENT_COLOR   vec3(0.4, 0.8, 1.0)
#define SKY_SUNLIGHT_COLOR vec3(0.8, 0.6, 0.05)
#define SKY_HORIZON_COLOR  vec3(1.0, 0.2, 0.1)
vec3 fakeAtmosphere(in vec3 viewDir, in vec3 lightDir) {
	// base sky color
	vec3 sky = SKY_COLOR;

	// lighter gradient from the bottom
	float accentFactor = simpleTonemap(exp(-viewDir.y * 4.0));
	sky                = mix(sky, SKY_ACCENT_COLOR, accentFactor);

	// sky luminance affected by sun visibility
	float skyLightnessFactor = smoothstep(-0.3, 0.2, lightDir.y);
	sky                      *= skyLightnessFactor;

	// sunlight fog
	float fogViewFactor = pow(dot(viewDir, lightDir) * 0.5 + 0.5, 5.0) * 0.5;
	float fogLightnessFactor = smoothstep(-0.1, 0.2, lightDir.y);
	vec3  fogColor =
	    mix(SKY_SUNLIGHT_COLOR, SKY_ACCENT_COLOR, fogLightnessFactor);
	sky = mix(sky, fogColor, fogViewFactor);

	// desaturation of the sky+accent color
	float desaturationFactor = simpleTonemap(exp(-lightDir.y * 10.0) * 0.25);
	sky = mix(sky, vec3(luminance(sky)), desaturationFactor);

	// sunlight tint
	float lightTimeFactor = 1.0 - smoothstep(0.2, 0.5, lightDir.y);
	float lightViewFactor = simpleTonemap(exp(-viewDir.y * 10.0));
	sky = mix(sky, SKY_SUNLIGHT_COLOR, lightViewFactor * lightTimeFactor);

	// horizon color
	float horizonViewFactor = simpleTonemap(exp(-viewDir.y * 20.0) * 0.2);
	sky = mix(sky, SKY_HORIZON_COLOR, horizonViewFactor * lightTimeFactor);

	// second sky luminance pass to dim the sunset light
	float sunlightLightnessFactor = smoothstep(-0.3, 0.0, lightDir.y);
	sky                           *= sunlightLightnessFactor;

	// planet shadow
	float shadowNormalTrackFactor = smoothstep(-0.1, -0.3, lightDir.y);
	vec3  shadowNormal            = normalize(
        mix(vec3(0.0, 1.0, 0.0), lightDir, shadowNormalTrackFactor * 2.0)
    );
	float lowestVisibilityDot = shadowNormalTrackFactor * 2.0 - 1.0;
	float visibilityFactor =
	    sCurve((dot(shadowNormal, viewDir) - lowestVisibilityDot) * 5.0);
	sky *= visibilityFactor;

	// Debug: draw blackbodies
	float sunShape = smoothstep(0.9995, 0.9998, dot(viewDir, lightDir));
	sky            = max(sky, vec3(sunShape) * 2.0);

	return sky / SKY_SUN_LUMINANCE;
}

vec3 fakeIndirect(in vec3 lightDir) {
	// base sky color
	vec3 sky = SKY_COLOR;

	// lighter gradient from the bottom
	// float accentFactor = simpleTonemap(exp(-viewDir.y * 4.0)); ~= 0.75
	sky = mix(sky, SKY_ACCENT_COLOR, 0.75);

	// sky luminance affected by sun visibility
	float skyLightnessFactor = smoothstep(-0.3, 0.2, lightDir.y);
	sky                      *= skyLightnessFactor;

	// desaturation of the sky+accent color
	float desaturationFactor = simpleTonemap(exp(-lightDir.y * 10.0) * 0.25);
	sky = mix(sky, vec3(luminance(sky)), desaturationFactor);

	// sunlight tint
	float lightTimeFactor = 1.0 - smoothstep(0.2, 0.5, lightDir.y);
	// float lightViewFactor = simpleTonemap(exp(-viewDir.y * 10.0)); ~= 0.3
	sky = mix(sky, SKY_SUNLIGHT_COLOR, 0.3 * lightTimeFactor);

	// second sky luminance pass to dim the sunset light
	float sunlightLightnessFactor = smoothstep(-0.3, 0.0, lightDir.y);
	sky                           *= sunlightLightnessFactor;

	// planet shadow
	float shadowNormalTrackFactor = smoothstep(-0.1, -0.3, lightDir.y);
	sky                           *= 1.0 - shadowNormalTrackFactor;

	return sky / SKY_SUN_LUMINANCE;
}

vec3 fakeDirect(vec3 lightDir) {
	// base sun color
	vec3 direct = vec3(1.0);

	// sunlight tint
	float sunlightFactor = simpleTonemap(exp(-lightDir.y * 2.0) * 4.0);
	direct               = mix(direct, SKY_SUNLIGHT_COLOR, sunlightFactor);

	// horizon tint
	float horizonFactor = simpleTonemap(exp(-lightDir.y * 10.0) * 4.0);
	direct              = mix(direct, SKY_HORIZON_COLOR, horizonFactor);

	// luminance
	float luminanceFactor = smoothstep(-0.3, 0.2, lightDir.y);
	direct                *= luminanceFactor;

	return direct;
}

vec3 rot3D(vec3 vec, vec3 axis, float angle) {
	// build a quaternion
	vec3  xyz = axis * sin(angle / 2.0);
	float w   = cos(angle / 2.0);

	// quaternion * vector
	vec3 t = 2.0 * cross(xyz, vec);
	return vec + t * w + cross(xyz, t);
}

vec3 stars(in vec3 viewDir, float quantity) {
	vec3 origin = floor(viewDir * quantity);
	vec3 offset = hash(origin);
	vec3 dir    = normalize(origin + offset);
	vec3 color  = mix(offset, vec3(1.0), 0.8);

	// Modulate size of stars. Here we treat offset.x as a random number.
	float edge = mix(0.999995, 0.999998, offset.x);

	// offset.y > 0.5 removes every second star from the dome.
	return offset.y > 0.5
	         ? vec3(0.0)
	         : smoothstep(edge, edge + 0.000003, dot(viewDir, dir)) * color;
}

#define SKY_NIGHT_TINT vec3(0.0, 0.7, 1.0)
vec3 sky(in vec3 viewDir, in vec3 sunDir, in vec3 moonDir) {
	// viewDir points into the camera, so let's reverse it.
	viewDir = -viewDir;

	vec3 sky      = vec3(0.0);
	sky           += fakeAtmosphere(viewDir, sunDir) * SKY_SUN_LUMINANCE;
	vec3 nightSky = fakeAtmosphere(viewDir, moonDir);
	nightSky      = mix(nightSky, SKY_NIGHT_TINT, 0.5);
	sky           += nightSky * SKY_MOON_LUMINANCE;

	// One daylight cycle in Minecraft takes 20 minutes, so we need to do one
	// revolution per 20 minutes.
	sky += stars(
	           rot3D(
	               viewDir,
	               normalize(vec3(0.0, 0.2, -1.0)),
	               float(worldTime) / 24000.0 * -(2.0 * PI)
	           ),
	           11.0
	       ) *
	       SKY_STARS_LUMINANCE;

	return sky;
}

vec3 skyIndirect(in vec3 worldSunDir, in vec3 worldMoonDir) {
	vec3 sky      = vec3(0.0);
	sky           += fakeIndirect(worldSunDir) * SKY_SUN_LUMINANCE;
	vec3 nightSky = fakeIndirect(worldMoonDir);
	nightSky      = mix(nightSky, SKY_NIGHT_TINT, 0.5);
	sky           += nightSky * SKY_MOON_LUMINANCE;
	return sky;
}

vec3 skyDirectSun(in vec3 worldSunDir) {
	return fakeDirect(worldSunDir) * SKY_SUN_LUMINANCE;
}

#define SKY_FOG_
vec3 fog(
    in vec3 color,
    in vec3 localFragPos,
    in vec3 worldSunDir,
    in vec3 worldMoonDir
) {
	vec3  bg             = skyIndirect(worldSunDir, worldMoonDir);
	float height         = localFragPos.y + cameraPosition.y - 50.0;
	float heightFactor   = min(exp(-height * 0.05), 1.0);
	float distanceFactor = 1.0 - exp(-length(localFragPos) * 0.002);
	return mix(color, bg, heightFactor * distanceFactor);
}

#endif // SKY_GLSL
