#ifndef BLOOM_GLSL
#define BLOOM_GLSL

#define BLOOM_LEVELS    4
#define BLOOM_THRESHOLD 2.0
#define BLOOM_QUALITY   21 // 5 - Low; 7 - Normal; 9 - High
#define BLOOM_STRENGTH  0.1
#define BLOOM_FALLOFF   1.0

vec3 writeBloomTile(in sampler2D tex, in vec2 coord, in float lod) {
	// Transform the tile to "atlas space"
	coord -= 1.0 - exp2(1.0 - lod);
	coord *= exp2(lod);
	
	// Saturate the coord
	if(any(greaterThanEqual(vec2(0.0), coord)))return vec3(0.0);
	if(any(greaterThanEqual(coord, vec2(1.0))))return vec3(0.0);
	
	// Apply threshold
	vec3 color = texture2DLod(tex, coord, lod).xyz;
	//return luma(color) < BLOOM_THRESHOLD ? vec3(0.0) : color;
	return color * smoothstep(BLOOM_THRESHOLD - 0.1, BLOOM_THRESHOLD + 0.1, luma(color));
}

vec3 blurBloom(in sampler2D tex, in vec2 coord, in ivec2 dir) {
	vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
	
	// Could be just coord.x or coord.y, but max(...) looks prettier in debug
	float lod = ceil(-log2(1.0 - max(coord.x, coord.y)));
	float offset = 1.0 - exp2(1.0 - lod);
	float width = exp2(-lod);
	vec2 bounds = vec2(offset, offset + width);
	float margin = max(texelSize.x, texelSize.y);
	bounds.x += margin;
	bounds.y -= margin;
	
	float maxLength = length(vec2(BLOOM_QUALITY));
	
	vec4 color = vec4(0.0);
	for(int i = -BLOOM_QUALITY; i <= BLOOM_QUALITY; i++) {
		vec2 offset = vec2(i * dir);
		float weight = 1.0 - smoothstep(0.0, 1.0, sqrt(length(offset) / maxLength));

		vec2 sampleCoord = coord + texelSize * offset;
		sampleCoord = clamp(sampleCoord, bounds.x, bounds.y);

		color.xyz += texture2D(tex, sampleCoord).xyz * weight;
		color.w   += weight;
	}
	return color.xyz / color.w;
}

vec3 readBloomTile(in sampler2D tex, in vec2 coord, in float lod) {
	// Calculate those values to compute both tile transform and sampling margin
	float offset = 1.0 - exp2(1.0 - lod);
	float width = exp2(-lod);
	
	// Inverse atlas transform
	coord *= width; // /= exp2(lod)
	coord += offset;
	
	// The single-texel margin is needed to account for linear atlas filtering issues
	// Can be removed if set to nearest, but the bloom will look blocky and awful
	// The bounding without margin is not needed at all, so both shall be removed together
	vec2 bounds = vec2(offset, offset + width);
	vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
	float margin = max(texelSize.x, texelSize.y);
	bounds.x += margin;
	bounds.y -= margin;
	coord = clamp(coord, bounds.x, bounds.y);
	
	return texture2D(tex, coord).xyz;
}

vec3 getBloom(in sampler2D tex, in vec2 coord) {
	float weight = 1.0;
	
	vec4 color = vec4(0.0);
	for(int i = 1; i <= BLOOM_LEVELS; i++) {
		color.xyz += readBloomTile(tex, coord, float(i)) * weight;
		color.w   += weight;

		weight *= BLOOM_FALLOFF;
	}
	return (color.xyz / color.w) * BLOOM_STRENGTH;
}

#endif // BLOOM_GLSL