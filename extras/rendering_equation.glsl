vec3 normal = ...;
vec3 viewDir = ...;
vec3 refractDir = refract(viewDir, normal, ior);
 
vec3 albedo;
float opacity;
float metallic;
float roughnes;
float ior;

// Convert metallic properties to specular workflow
vec3 diffuse = albedo * (1.0 - metallic) * opacity;
vec3 specular = albedo * metallic;
vec3 transmission = albedo * (1.0 - opacity);

// Fresnel and Beer's laws
float cosNv = max(dot(normal, viewDir), 0.0);
float f0 = pow(ior - 1.0, 2.0) / pow(ior + 1.0, 2.0);
float fresnel = f0 + (max(f0, 1.0 - roughness) - f0) * pow(1.0 - cosNv, 5.0);
vec3 beer = exp((vec3(1.0) - albedo) * 0.15 * -thickness);

// Apply the laws
diffuse *= (1.0 - fresnel);
specular = mix(specular, vec3(1.0), fresnel);
transmission *= (1.0 - fresnel) * beer;

vec3 energy = kD + kS * reflectionColor + kT * transmissionColor;
