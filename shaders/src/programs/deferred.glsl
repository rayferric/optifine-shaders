varying vec2 v_TexCoord;

///////////////////
// Vertex Shader //
///////////////////

#ifdef VSH

void main() {
	v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}

#endif // VSH

/////////////////////
// Fragment Shader //
/////////////////////

#ifdef FSH

#include "/src/modules/clouds.glsl"
#include "/src/modules/gamma.glsl"
#include "/src/modules/pack.glsl"
#include "/src/modules/pbr.glsl"
#include "/src/modules/screen_to_view.glsl"
#include "/src/modules/shadow.glsl"
#include "/src/modules/sky.glsl"
#include "/src/modules/ssao.glsl"

#include "/src/modules/tonemap.glsl"

void main() {
	float depth = texture(depthtex0, v_TexCoord).x;

	vec3 viewFragPos  = screenToView(v_TexCoord, depth);
	vec3 localFragPos = (gbufferModelViewInverse * vec4(viewFragPos, 1.0)).xyz;

	vec3 viewEyeDir  = -normalize(viewFragPos);
	vec3 worldEyeDir = normalize(mat3(gbufferModelViewInverse) * viewEyeDir);

	vec3 worldSunDir =
	    normalize(mat3(gbufferModelViewInverse) * normalize(sunPosition));
	vec3 worldMoonDir =
	    normalize(mat3(gbufferModelViewInverse) * normalize(moonPosition));
	vec3 viewLightDir = normalize(shadowLightPosition);

	vec3 hdr = vec3(0.0);

	// Sky
	if (depth == 1.0) {
		hdr += sky(worldEyeDir, worldSunDir, worldMoonDir);
	} else {
		vec3  albedo = gammaToLinear(texture(colortex2, v_TexCoord).xyz);
		vec3  roughnessMetallic = texture(colortex3, v_TexCoord).xyz;
		float roughness         = roughnessMetallic.x;
		float metallic          = roughnessMetallic.y;
		vec3  viewNormal   = unpackNormal(texture2D(colortex4, v_TexCoord).xy);
		vec2  ambientLight = gammaToLinear(texture(colortex5, v_TexCoord).xy);

		vec3 skyLight = ambientLight.x * skyIndirect(worldSunDir, worldMoonDir);
		vec3 blockLight = ambientLight.y * BLOCK_LIGHT_ENERGY;
		vec3 sunLight   = skyDirectSun(worldSunDir);

		vec3 shadowColor =
		    softShadow(localFragPos, viewNormal, viewLightDir, false);
		// if (!mask.isFoliage) {
		// 	shadowColor *= contactShadow(viewPos, sunDir);
		// }
		vec3 directContrib = directContribution(
		    albedo,
		    roughness,
		    metallic,
		    viewNormal,
		    viewEyeDir,
		    viewLightDir,
		    false
		);
		hdr += directContrib * shadowColor * sunLight;

		IndirectContribution indirectContrib = indirectContribution(
		    albedo, roughness, metallic, viewNormal, viewEyeDir
		);
		vec3 indirect = (indirectContrib.diffuse + indirectContrib.specular) *
		                (skyLight + blockLight);
		indirect *= computeSsao(viewFragPos, viewNormal, depthtex0);
		hdr      += indirect;

		// hdr += (skyLight + blockLight) * albedo +
		//        albedo * shadowColor * sunLight *
		//            max(dot(viewNormal, viewLightDir), 0.0) / 3.141;
		hdr = fog(hdr, localFragPos, worldSunDir, worldMoonDir);
	}

	// vec4 clouds = clouds(
	//     localViewDir,
	//     worldSunDir,
	//     cameraPosition,
	//     0.7,
	//     depth == 1.0 ? INFINITY : length(pos)
	// );

	// hdr = mix(hdr, clouds.xyz, clouds.w);

	gl_FragData[0].xyz = hdr;
	gl_FragData[0].w   = 1.0;
}

/* DRAWBUFFERS:1 */

#endif // FSH
