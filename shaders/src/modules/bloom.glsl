#ifndef BLOOM_GLSL
#define BLOOM_GLSL

#include "/src/modules/luminance.glsl"

#define BLOOM_LEVELS        4
#define BLOOM_MIN_THRESHOLD 0.6
#define BLOOM_MAX_THRESHOLD 0.7
#define BLOOM_MIN_SIZE      3
#define BLOOM_MAX_SIZE      7

vec3 writeBloomAtlas(in sampler2D colorTex, in vec2 screenPos) {
	// Discard unused pixels
	float lod1 = ceil(-log2(1.0 - screenPos.x));
	float lod2 = ceil(-log2(1.0 - screenPos.y));
	if (lod1 != lod2) {
		return vec3(0.0);
	}

	// Map screen position to tile position
	screenPos -= 1.0 - exp2(1.0 - lod1);
	screenPos *= exp2(lod1);

	// Apply threshold
	vec3 color = texture2DLod(colorTex, screenPos, lod1).xyz;
	return smoothstep(
	           BLOOM_MIN_THRESHOLD, BLOOM_MAX_THRESHOLD, luminance(color)
	       ) *
	       color;
}

vec3 blurBloomAtlas(in sampler2D atlas, in vec2 screenPos, in bool vertical) {
	// Discard unused pixels
	float lod1 = ceil(-log2(1.0 - screenPos.x));
	float lod2 = ceil(-log2(1.0 - screenPos.y));
	if (lod1 != lod2) {
		return vec3(0.0);
	}

	float sizeMixFactor = min((lod1 - 1.0) / float(BLOOM_LEVELS - 1), 1.0);
	int   size =
	    int(mix(float(BLOOM_MIN_SIZE), float(BLOOM_MAX_SIZE), sizeMixFactor) +
	        0.5);
	float maxLength = length(vec2(size));
	vec2  texelSize = 1.0 / vec2(viewWidth, viewHeight);

	vec4 color = vec4(0.0);
	for (int i = -size; i <= size; i++) {
		vec2  offset = vertical ? vec2(0.0, i) : vec2(i, 0.0);
		float weight =
		    1.0 - smoothstep(0.0, 1.0, pow(length(offset) / maxLength, 0.75));

		vec2 sampleCoord = screenPos + texelSize * offset;

		color.xyz += texture2D(atlas, sampleCoord).xyz * weight;
		color.w   += weight;
	}
	return color.xyz / color.w;
}

vec3 readBloomAtlas(in sampler2D atlas, in vec2 screenPos) {
	vec4  color  = vec4(0.0);
	float weight = 1.0;

	for (int lod = 1; lod <= BLOOM_LEVELS; lod++) {
		vec2 tilePos = screenPos;
		tilePos      *= exp2(-float(lod)); // /= exp2(lod)
		tilePos      += 1.0 - exp2(1.0 - float(lod));

		vec3 level = texture2D(atlas, tilePos).xyz;
		color.xyz  += level * level * weight;
		color.w    += weight;
	}
	return (color.xyz / color.w);
}

#endif // BLOOM_GLSL
