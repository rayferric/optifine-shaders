#ifndef BLOOM_GLSL
#define BLOOM_GLSL

#include "/include/modules/luminance.glsl"

#define BLOOM_LEVELS    5
#define BLOOM_MIN_THRESHOLD 1.0
#define BLOOM_MAX_THRESHOLD 2.0
#define BLOOM_QUALITY   21 // 5 - Low; 7 - Normal; 9 - High
#define BLOOM_STRENGTH  5.0

vec3 writeBloomAtlas(in sampler2D sRgbTex, in vec2 screenPos) {
	// Discard unused pixels
	float lod1 = ceil(-log2(1.0 - screenPos.x));
	float lod2 = ceil(-log2(1.0 - screenPos.y));
    if (lod1 != lod2)
		return vec3(0.0);

	// Map screen position to tile position
    screenPos -= 1.0 - exp2(1.0 - lod1);
    screenPos *= exp2(lod1);
    
    // Apply threshold
    vec3 color = texture2D(sRgbTex, screenPos).xyz;
    return smoothstep(BLOOM_MIN_THRESHOLD, BLOOM_MAX_THRESHOLD, luma(color)) * color;
}

vec3 blurBloomAtlas(in sampler2D atlas, in vec2 screenPos, in bool vertical) {
    // Discard unused pixels
	float lod1 = ceil(-log2(1.0 - screenPos.x));
	float lod2 = ceil(-log2(1.0 - screenPos.y));
    if (lod1 != lod2)
		return vec3(0.0);
    
	vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
    float maxLength = length(vec2(BLOOM_QUALITY));
    
    vec4 color = vec4(0.0);
    for(int i = -BLOOM_QUALITY; i <= BLOOM_QUALITY; i++) {
        vec2 offset = vertical ? vec2(0.0, i) : vec2(i, 0.0);
        float weight = 1.0 - smoothstep(0.0, 1.0, pow(length(offset) / maxLength, 0.75));

        vec2 sampleCoord = screenPos + texelSize * offset;

        color.xyz += texture2D(atlas, sampleCoord).xyz * weight;
        color.w   += weight;
    }
    return color.xyz / color.w;
}

vec4 cubic(float v){
    vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) * (1.0/6.0);
}

vec4 textureBicubic(sampler2D sampler, vec2 texCoords){

	vec2 texSize = vec2(viewWidth, viewHeight);
	vec2 invTexSize = 1.0 / texSize;
	
	texCoords = texCoords * texSize - 0.5;

	
    vec2 fxy = fract(texCoords);
    texCoords -= fxy;

    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);

    vec4 c = texCoords.xxyy + vec2(-0.5, +1.5).xyxy;
    
    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;
    
    offset *= invTexSize.xxyy;
    
    vec4 sample0 = texture2D(sampler, offset.xz);
    vec4 sample1 = texture2D(sampler, offset.yz);
    vec4 sample2 = texture2D(sampler, offset.xw);
    vec4 sample3 = texture2D(sampler, offset.yw);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix(
    	mix(sample3, sample2, sx), mix(sample1, sample0, sx)
    , sy);
}

vec3 readBloomAtlas(in sampler2D atlas, in vec2 screenPos) {
	vec4 color = vec4(0.0);
	for(int lod = 1; lod <= BLOOM_LEVELS; lod++) {
		vec2 tilePos = screenPos;
		tilePos *= exp2(-float(lod)); // /= exp2(lod)
		tilePos += 1.0 - exp2(1.0 - float(lod));

		color.xyz += texture2D(atlas, tilePos).xyz;
		color.w   += 1.0;
	}
	return (color.xyz / color.w) * BLOOM_STRENGTH;
}

#endif // BLOOM_GLSL
