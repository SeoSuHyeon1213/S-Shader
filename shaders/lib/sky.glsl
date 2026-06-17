// Shared sky color utilities
// Used by final fog, gbuffers_skybasic, and gbuffers_clouds; ready for future skytextured passes.

const vec3 SKY_DAY_ZENITH      = vec3(0.47, 0.62, 0.78);
const vec3 SKY_DAY_HORIZON     = vec3(0.66, 0.76, 0.86);
const vec3 SKY_NIGHT_ZENITH    = vec3(0.020, 0.026, 0.045);
const vec3 SKY_NIGHT_HORIZON   = vec3(0.075, 0.070, 0.105);
const vec3 SKY_SUNSET_HORIZON  = vec3(0.98, 0.54, 0.31);
const vec3 SKY_RAIN_DESAT      = vec3(0.55, 0.58, 0.64);
const float SKY_PRE_GRADE_DESAT = 0.08;
const float SKY_PRE_GRADE_SOFTEN = 0.06;

vec3 desaturateSkyColor(vec3 color, float amount) {
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    return mix(color, vec3(luma), clamp(amount, 0.0, 1.0));
}

vec3 applySkyPreGrade(vec3 color, float horizon, float rain, float nightMask) {
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float desat = SKY_PRE_GRADE_DESAT + horizon * (rain * 0.08 + nightMask * 0.05);
    vec3 graded = desaturateSkyColor(color, desat);
    vec3 softTarget = vec3(luma) * 0.92 + vec3(0.04, 0.045, 0.05);
    return mix(graded, softTarget, SKY_PRE_GRADE_SOFTEN * (0.5 + horizon * 0.5));
}

float skyDayMask(int worldTime) {
    float time = mod(float(worldTime), 24000.0);
    float sunrise = smoothstep(0.0, 3000.0, time);
    float sunset = 1.0 - smoothstep(12000.0, 13500.0, time);
    return sunrise * sunset;
}

float skyTransitionMask(float dayMask) {
    return clamp(4.0 * dayMask * (1.0 - dayMask), 0.0, 1.0);
}

float skyHorizonMask(vec3 worldDir) {
    float up = clamp(worldDir.y * 0.5 + 0.5, 0.0, 1.0);
    return pow(1.0 - smoothstep(0.48, 0.96, up), 1.35);
}

vec3 getSkyColor(vec3 worldDir, int worldTime, float rainStrength) {
    float dayMask = skyDayMask(worldTime);
    float nightMask = 1.0 - dayMask;
    float transition = skyTransitionMask(dayMask);
    float horizon = skyHorizonMask(worldDir);
    float rain = clamp(rainStrength, 0.0, 1.0);
    float calmHorizon = horizon * clamp(rain * 0.55 + nightMask * 0.35, 0.0, 0.82);

    vec3 daySky = mix(SKY_DAY_ZENITH, SKY_DAY_HORIZON, horizon);
    vec3 nightSky = mix(SKY_NIGHT_ZENITH, SKY_NIGHT_HORIZON, horizon);
    vec3 sky = mix(nightSky, daySky, dayMask);
    vec3 averagedSky = mix(
        mix(SKY_NIGHT_ZENITH, SKY_DAY_ZENITH, dayMask),
        mix(SKY_NIGHT_HORIZON, SKY_DAY_HORIZON, dayMask),
        0.50
    );
    sky = mix(sky, averagedSky, calmHorizon);

    vec3 sunsetSky = mix(sky, SKY_SUNSET_HORIZON, horizon * transition * 0.42);
    sky = mix(sky, sunsetSky, transition);

    vec3 rainySky = mix(sky, SKY_RAIN_DESAT, 0.45 + nightMask * 0.20);
    sky = mix(sky, rainySky, rain * 0.72);
    sky = desaturateSkyColor(sky, horizon * (rain * 0.18 + nightMask * 0.10));
    sky = applySkyPreGrade(sky, horizon, rain, nightMask);
    return sky;
}

vec3 getSkyBaseColor(vec3 worldDir, int worldTime, float rainStrength) {
    return getSkyColor(worldDir, worldTime, rainStrength);
}

vec3 getSkyWaterReflectionColor(vec3 worldDir, int worldTime, float rainStrength) {
    vec3 horizonDir = normalize(vec3(worldDir.x, mix(worldDir.y, 0.0, 0.72), worldDir.z));
    vec3 viewSky = getSkyColor(worldDir, worldTime, rainStrength);
    vec3 horizonSky = getSkyColor(horizonDir, worldTime, rainStrength);
    float horizonWeight = clamp(0.42 + skyHorizonMask(worldDir) * 0.34 + rainStrength * 0.12, 0.0, 0.86);
    return mix(viewSky, horizonSky, horizonWeight);
}

vec3 getSkyFogColor(vec3 worldDir, vec3 sceneColor, int worldTime, float rainStrength) {
    vec3 skyColor = getSkyColor(worldDir, worldTime, rainStrength);
    float sceneLuma = dot(sceneColor, vec3(0.2126, 0.7152, 0.0722));
    float skyLuma = max(dot(skyColor, vec3(0.2126, 0.7152, 0.0722)), 1e-4);
    float ambientMatch = clamp(sceneLuma / skyLuma, 0.35, 1.15);
    return skyColor * mix(1.0, ambientMatch, 0.28);
}

float getSkyFogAmount(vec3 worldDir, int worldTime, float rainStrength) {
    float dayMask = skyDayMask(worldTime);
    float horizon = skyHorizonMask(worldDir);
    float baseStrength = mix(0.035, 0.18, dayMask);
    return horizon * (baseStrength + clamp(rainStrength, 0.0, 1.0) * 0.12);
}
