// Mood lighting utilities

const vec3 SUN_LIGHT_COLOR    = vec3(0.945, 0.996, 0.776); // #F1FEC6 - midday sunlight
const vec3 SUN_HORIZON_COLOR  = vec3(1.000, 0.557, 0.282); // warm sunrise/sunset glow
const vec3 MOON_LIGHT_COLOR   = vec3(0.749, 0.847, 1.000); // cool blue moonlight, tuned for night readability
// Halfway from unmodified block light to the previous orange held-light tint.
const vec3 TORCH_MID_TINT     = vec3(1.000, 0.760, 0.615);
const vec3 LAVA_LIGHT_COLOR   = vec3(1.000, 0.227, 0.125); // #FF3A20
const vec3 LAVA_EDGE_COLOR    = vec3(1.000, 0.478, 0.239); // softer lava spill
const vec3 UNDERWATER_TINT_COLOR  = vec3(0.58, 0.82, 1.10);
const vec3 UNDERWATER_LIGHT_COLOR = vec3(0.12, 0.40, 0.85);
const vec3 RAIN_ACCENT_COLOR  = vec3(0.204, 0.137, 0.651); // #3423A6
const vec3 RAIN_AMBIENT_COLOR = vec3(0.340, 0.360, 0.530); // desaturated rainy ambient tint

const float SUN_HORIZON_GLOW = 0.35; // base highlight warmth during sunrise/sunset
const float NIGHT_READABILITY_LIFT = 0.035; // subtle blue lift on dark areas at night

float getLuminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec3 matchTorchColor(vec3 localLight) {
    vec3 tinted = localLight * TORCH_MID_TINT;
    // Preserve installed-light luminance while changing only its color balance.
    return tinted * (getLuminance(localLight) / max(getLuminance(tinted), 0.00001));
}

float getDayMask(int worldTime) {
    float time = mod(float(worldTime), 24000.0);
    float sunrise = smoothstep(0.0, 3000.0, time);
    float sunset = 1.0 - smoothstep(12000.0, 13500.0, time);
    return sunrise * sunset;
}

float getNightMask(int worldTime) {
    return 1.0 - getDayMask(worldTime);
}

// 0 at full day/night, peaks at 1.0 mid-transition (sunrise/sunset)
float getSunHorizonFactor(float dayMask) {
    return 4.0 * dayMask * (1.0 - dayMask);
}

// Shifts sunlight from midday warm-white toward a warm orange glow at sunrise/sunset
vec3 getSunColor(float dayMask) {
    return mix(SUN_LIGHT_COLOR, SUN_HORIZON_COLOR, getSunHorizonFactor(dayMask));
}

// Full strength at midday, with an extra glow during the sunrise/sunset transition
float getSunIntensity(float dayMask, float sunsetGlowStrength) {
    return dayMask * (1.0 + getSunHorizonFactor(dayMask) * SUN_HORIZON_GLOW * sunsetGlowStrength);
}

vec3 applyUnderwaterLighting(vec3 color, vec3 worldDir, float viewDistance, float sceneMask) {
    float distanceTint = smoothstep(6.0, 48.0, viewDistance) * sceneMask;
    float overheadGlow = smoothstep(-0.25, 0.75, worldDir.y);
    float tintAmount = mix(0.30, 0.46, distanceTint);
    float lightAmount = (0.025 + overheadGlow * 0.055) * mix(0.65, 1.0, sceneMask);

    color *= mix(vec3(1.0), UNDERWATER_TINT_COLOR, tintAmount);
    color += UNDERWATER_LIGHT_COLOR * lightAmount;

    return color;
}

vec3 applyLavaEmission(vec3 color, vec3 surfaceColor, float lavaMask, float intensity) {
    float mask = clamp(lavaMask, 0.0, 1.0);
    if (mask <= 0.001 || intensity <= 0.0) return color;

    float hotCore = smoothstep(0.20, 0.85, getLuminance(surfaceColor));
    vec3 emission = surfaceColor * (1.0 + intensity * (0.50 + hotCore * 0.60));
    emission += mix(LAVA_LIGHT_COLOR, LAVA_EDGE_COLOR, hotCore) * intensity * 0.08;
    // Restore emission after weather/shadow shading, before fog and tonemapping.
    return mix(color, max(color, emission), mask);
}


vec3 getApproxTerrainNormal(float floorMask, float wallMask) {
    vec3 floorNormal = vec3(0.0, 1.0, 0.0);
    vec3 wallNormal = normalize(vec3(0.0, 0.22, 1.0));
    float wallBlend = clamp(wallMask / max(floorMask + wallMask, 0.001), 0.0, 1.0);
    return normalize(mix(floorNormal, wallNormal, wallBlend));
}

vec3 applyTerrainFormLighting(
    vec3 color,
    vec3 worldDir,
    float sceneMask,
    float floorMask,
    float wallMask,
    float shadowVisibility,
    vec3 worldNormal,
    float normalMask,
    int worldTime,
    float rainStrength
) {
    float materialMask = max(floorMask, wallMask);
    float terrainMask = clamp(materialMask * sceneMask, 0.0, 1.0);
    if (terrainMask <= 0.001) return color;

    vec3 fallbackNormal = getApproxTerrainNormal(floorMask, wallMask);
    vec3 normal = normalize(mix(fallbackNormal, worldNormal, clamp(normalMask, 0.0, 1.0)));
    vec3 lightDir = getShadowLightDirection();
    float dayMask = skyDayMask(worldTime);
    float twilight = skyTwilightMask(worldTime);
    float rain = clamp(rainStrength, 0.0, 1.0);
    float visibility = clamp(shadowVisibility, 0.0, 1.0);

    float noL = clamp(dot(normal, lightDir), 0.0, 1.0);
    vec3 viewDir = normalize(-worldDir);
    vec3 halfDir = normalize(lightDir + viewDir);
    float noH = clamp(dot(normal, halfDir), 0.0, 1.0);
    float diffuse = noL * noL * (3.0 - 2.0 * noL);
    float backFace = pow(1.0 - noL, 1.35);
    float shadowMask = 1.0 - visibility;
    float normalConfidence = clamp(normalMask, 0.0, 1.0);
    float wallAmount = clamp(wallMask / max(floorMask + wallMask, 0.001), 0.0, 1.0);
    float wetAmount = clamp(max(floorMask, wallMask * 0.55), 0.0, 1.0);

    vec3 directLight = mix(MOON_LIGHT_COLOR * 0.34, SUN_LIGHT_COLOR, dayMask);
    directLight = mix(directLight, SUN_HORIZON_COLOR, twilight * 0.24);
    vec3 skyShade = getSkyShadowTint(getStableShadowSkyDirection(), worldTime, rainStrength);
    vec3 normalShade = mix(vec3(0.52, 0.59, 0.74), skyShade, 0.50);

    float diffuseAmount = diffuse * visibility * terrainMask * normalConfidence * mix(0.045, 0.125, dayMask) * (1.0 - rain * 0.35);
    float brdfLobe = pow(noH, mix(26.0, 72.0, 1.0 - wallAmount)) * noL * visibility;
    float brdfAmount = brdfLobe * terrainMask * normalConfidence * wetAmount * mix(0.010, 0.035, dayMask) * (1.0 - rain * 0.18);
    float formShadow = backFace * terrainMask * normalConfidence * mix(0.095, 0.130, dayMask);
    float castShadow = shadowMask * terrainMask * normalConfidence * mix(0.130, 0.160, dayMask);
    float combinedShadow = clamp(formShadow + castShadow + formShadow * castShadow * 0.8, 0.0, 0.52);

    color = mix(color, color * normalShade, combinedShadow);
    color += directLight * diffuseAmount;
    color += directLight * brdfAmount;
    return color;
}
vec3 applyMoodLighting(
    vec3 color,
    vec3 localLight,
    float sceneMask,
    float strength,
    float rainStrength,
    int worldTime,
    float shadowVisibility,
    float dayLightStrength,
    float nightLightStrength,
    float sunsetGlowStrength
) {
    float luma = getLuminance(color);
    float shadowMask = 1.0 - smoothstep(0.12, 0.55, luma);
    float castShadowMask = (1.0 - clamp(shadowVisibility, 0.0, 1.0)) * sceneMask;
    float ambientShadowMask = shadowMask * (1.0 - castShadowMask * 0.62);
    float highlightMask = smoothstep(0.55, 1.25, luma);
    float rain = clamp(rainStrength, 0.0, 1.0);
    float dayMask = getDayMask(worldTime);
    float nightMask = getNightMask(worldTime);
    vec3 sunColor = getSunColor(dayMask) * dayLightStrength;
    vec3 moonColor = MOON_LIGHT_COLOR * nightLightStrength;
    float sunIntensity = getSunIntensity(dayMask, sunsetGlowStrength) * dayLightStrength;
    float sunGlow = getSunHorizonFactor(dayMask);
    float weatherDampen = 1.0 - rain * 0.35;

    vec3 skyTint = mix(moonColor, sunColor, dayMask);
    vec3 shadowTint = mix(vec3(0.86, 0.92, 1.06), skyTint, 0.35 + nightMask * 0.25);
    vec3 highlightTint = mix(moonColor, sunColor, sunIntensity * 0.85 + 0.15);
    vec3 rainReflectTint = mix(vec3(0.85, 0.90, 1.0), RAIN_ACCENT_COLOR, 0.18);

    color = mix(color, color * shadowTint, ambientShadowMask * strength * 0.28);
    color = mix(color, color * highlightTint, highlightMask * strength * (0.25 + sunGlow * 0.15 * sunsetGlowStrength) * weatherDampen * (1.0 - castShadowMask * 0.42));
    // Both installed and held local light are restored after sun/moon shading.
    color += localLight;
    color += highlightMask * rain * strength * rainReflectTint * 0.06;
    color = mix(color, color * RAIN_AMBIENT_COLOR, rain * strength * 0.07);
    color = mix(color, vec3(getLuminance(color)), rain * strength * 0.10);

    // Night readability: lift dark areas with a touch of cool moonlight
    color += moonColor * ambientShadowMask * nightMask * strength * NIGHT_READABILITY_LIFT;

    return color;
}
