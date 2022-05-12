#ifndef BLOOM_GLSL
#define BLOOM_GLSL

#define BLOOM_LEVELS    4
#define BLOOM_THRESHOLD 0.7 // <0.0, 2.0>
#define BLOOM_QUALITY   21 // 5 - Low; 7 - Normal; 9 - High
#define BLOOM_STRENGTH  4.0
#define BLOOM_FALLOFF   0.5

// Top-right coords
const vec2[] TILE_COORDS = vec2[](
	vec2(0.0, 0.0),
	vec2(0.625, 0.125),
	vec2(0.1875, 0.6875),
	vec2(0.71875, 0.71875)
);

vec3 writeBloomTile(in sampler2D tex, in vec2 coord, in int lod) {
	// Transform the tile to "atlas space"
	coord -= TILE_COORDS[lod - 1];
	coord *= exp2(float(lod));
	
	// Saturate the coord
	if (!isInRect(coord, vec2(0.0), vec2(1.0)))
		return vec3(0.0);
	
	vec3 color = texture2D(tex, coord).xyz;
	// Clamp the brightness to do LDR blur
	color = clamp(color, 0.0, 1.0);
	// Apply threshold
	return color * smoothstep(BLOOM_THRESHOLD - 0.1, BLOOM_THRESHOLD + 0.1, luminance(color));
}

vec3 blurBloom(in sampler2D tex, in vec2 coord, in ivec2 dir) {
	vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
	
	float maxLength = length(vec2(BLOOM_QUALITY));
	
	vec4 color = vec4(0.0);
	for(int i = -BLOOM_QUALITY; i <= BLOOM_QUALITY; i++) {
		vec2 offset = vec2(i * dir);
		float weight = 1.0 - smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, sqrt(length(offset) / maxLength))));

		vec2 sampleCoord = coord + texelSize * offset;

		color.xyz += texture2D(tex, sampleCoord).xyz * weight;
		color.w   += weight;
	}
	return color.xyz / color.w;
}

vec3 readBloomTile(in sampler2D tex, in vec2 coord, in int lod) {
	// Inverse atlas transform
	coord *= exp2(-float(lod)); // /= exp2(lod)
	coord += TILE_COORDS[lod - 1];
	
	return texture2D(tex, coord).xyz;
}

vec3 getBloom(in sampler2D tex, in vec2 coord) {
	float weight = 1.0;
	
	vec4 color = vec4(0.0);
	for(int i = 1; i <= BLOOM_LEVELS; i++) {
		color.xyz += readBloomTile(tex, coord, i) * weight;
		color.w   += weight;
		
		weight *= BLOOM_FALLOFF;
	}
	return max(color.xyz / color.w, 0.0) * BLOOM_STRENGTH;
}

#endif // BLOOM_GLSL