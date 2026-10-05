// Shadow mapping utilities

#include "/lib/shadow_settings.glsl"

#define SHADOW_MODE 0 // Shadow filter mode: 0 = stable Poisson PCF, 1 = experimental PCSS [0 1]

const float SHADOW_DARKNESS = 0.94;
const float SHADOW_FADE_START = 0.58;
const float SHADOW_BIAS_TEXELS = 0.6;
const float SHADOW_SLOPE_BIAS_TEXELS = 2.4;
const float SHADOW_MAX_SLOPE = 1.5;
const float SHADOW_DISTANCE_BIAS = 0.0015;
const float SHADOW_EDGE_FADE = 0.045;
const float SHADOW_STABLE_PCF_RADIUS = 0.95;
const float SHADOW_STABLE_PCSS_SEARCH_RADIUS = 1.45;

const float SHADOW_POISSON_RADIUS = 1.65;
const float SHADOW_POISSON_NEAR_RADIUS = 1.15;
const int SHADOW_PCF_SAMPLES = 8;
const int PCSS_BLOCKER_SAMPLES = 8;
const int PCSS_FILTER_SAMPLES = 8;
const float PCSS_SEARCH_NEAR_RADIUS = 1.0;
const float PCSS_SEARCH_FAR_RADIUS = 2.6;
const float PCSS_LIGHT_SIZE = 16.0;
const float PCSS_MIN_RADIUS = 0.65;
const float PCSS_MAX_RADIUS = 2.8;
const float RAIN_EXPOSURE_MIN = 0.08;

float getShadowDayFactor(int worldTime) {
    float time = mod(float(worldTime), 24000.0);
    float sunrise = smoothstep(0.0, 3000.0, time);
    float sunset = 1.0 - smoothstep(12000.0, 13500.0, time);
    float dayMask = sunrise * sunset;

    // Moon shadows stay subtle so night scenes keep readability.
    return max(dayMask, (1.0 - dayMask) * 0.42);
}

vec3 getShadowLightDirection() {
    // The light-view Z row points toward the sun/moon in world space.
    return normalize(vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z));
}

float getShadowBias(vec3 worldNormal, float normalMask) {
    float noL = clamp(abs(dot(worldNormal, getShadowLightDirection())), 0.0, 1.0);
    float slope = sqrt(max(1.0 - noL * noL, 0.0)) / max(noL, 0.2);
    slope = mix(1.0, min(slope, SHADOW_MAX_SLOPE), clamp(normalMask, 0.0, 1.0));
    float worldTexelSize = 2.0 * SHADOW_TEXEL_SIZE / max(abs(shadowProjection[0].x), 0.00001);
    float depthPerTexel = worldTexelSize * abs(shadowProjection[2].z) * 0.5;
    // Bound the light-space slope bias; screen derivatives jump across geometry edges.
    return depthPerTexel * (SHADOW_BIAS_TEXELS + slope * SHADOW_SLOPE_BIAS_TEXELS);
}

float sampleShadowMap(vec3 shadowPos, vec2 offset, float bias) {
    vec2 sampleUv = shadowPos.xy + offset * SHADOW_TEXEL_SIZE;
    vec2 texelPos = sampleUv / SHADOW_TEXEL_SIZE - 0.5;
    vec2 fraction = fract(texelPos);
    vec2 baseUv = (floor(texelPos) + 0.5) * SHADOW_TEXEL_SIZE;
    vec2 minUv = vec2(SHADOW_TEXEL_SIZE * 0.5);
    vec2 maxUv = vec2(1.0) - minUv;
    float receiverDepth = shadowPos.z - bias;
    // Compare nearest depths first, then interpolate visibility, never raw depth.
    float s00 = step(receiverDepth, texture2D(shadowtex0, clamp(baseUv, minUv, maxUv)).r);
    float s10 = step(receiverDepth, texture2D(shadowtex0, clamp(baseUv + vec2(SHADOW_TEXEL_SIZE, 0.0), minUv, maxUv)).r);
    float s01 = step(receiverDepth, texture2D(shadowtex0, clamp(baseUv + vec2(0.0, SHADOW_TEXEL_SIZE), minUv, maxUv)).r);
    float s11 = step(receiverDepth, texture2D(shadowtex0, clamp(baseUv + vec2(SHADOW_TEXEL_SIZE), minUv, maxUv)).r);
    return mix(mix(s00, s10, fraction.x), mix(s01, s11, fraction.x), fraction.y);
}


float shadowHash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 rotateShadowOffset(vec2 offset, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(offset.x * c - offset.y * s, offset.x * s + offset.y * c);
}

vec2 getPoissonShadowOffset(int index) {
    if (index == 0) return vec2(-0.326, -0.406);
    if (index == 1) return vec2(-0.840, -0.074);
    if (index == 2) return vec2(-0.696,  0.457);
    if (index == 3) return vec2(-0.203,  0.621);
    if (index == 4) return vec2( 0.962, -0.195);
    if (index == 5) return vec2( 0.473, -0.480);
    if (index == 6) return vec2( 0.519,  0.767);
    return vec2( 0.185, -0.893);
}

float samplePoissonShadow(vec3 shadowPos, float bias, float radius, int sampleCount) {
    float angle = 0.0; // Fixed kernel keeps PCF stable while the camera moves.
    float visibility = sampleShadowMap(shadowPos, vec2(0.0), bias) * 1.35;
    float weightSum = 1.35;

    for (int i = 0; i < 8; i++) {
        if (i < sampleCount) {
            vec2 offset = rotateShadowOffset(getPoissonShadowOffset(i), angle) * radius;
            float weight = mix(1.08, 0.78, float(i) / 7.0);
            visibility += sampleShadowMap(shadowPos, offset, bias) * weight;
            weightSum += weight;
        }
    }

    return visibility / weightSum;
}


float findAverageBlockerDepth(vec3 shadowPos, float bias, float searchRadius) {
    float angle = 0.0; // Fixed blocker kernel avoids PCSS crawling during movement.
    float blockerSum = 0.0;
    float blockerCount = 0.0;

    for (int i = 0; i < PCSS_BLOCKER_SAMPLES; i++) {
        vec2 offset = rotateShadowOffset(getPoissonShadowOffset(i), angle) * searchRadius;
        vec2 sampleUv = shadowPos.xy + offset * SHADOW_TEXEL_SIZE;
        if (sampleUv.x > 0.001 && sampleUv.x < 0.999 && sampleUv.y > 0.001 && sampleUv.y < 0.999) {
            float blockerDepth = texture2D(shadowtex0, sampleUv).r;
            if (blockerDepth < shadowPos.z - bias) {
                blockerSum += blockerDepth;
                blockerCount += 1.0;
            }
        }
    }

    if (blockerCount < 0.5) return -1.0;
    return blockerSum / blockerCount;
}

float getPCSSPenumbraRadius(float receiverDepth, float blockerDepth) {
    float depthDelta = max(receiverDepth - blockerDepth, 0.0);
    return clamp(depthDelta * PCSS_LIGHT_SIZE, PCSS_MIN_RADIUS, PCSS_MAX_RADIUS);
}

float getShadowStableFilterRadius(float dynamicRadius) {
    // Penumbra follows light-space blocker separation, not player distance.
    return mix(SHADOW_STABLE_PCF_RADIUS, dynamicRadius, 0.82);
}

float samplePCSSShadow(vec3 shadowPos, float bias) {
    float searchRadius = SHADOW_STABLE_PCSS_SEARCH_RADIUS;
    float blockerDepth = findAverageBlockerDepth(shadowPos, bias, searchRadius);

    if (blockerDepth < 0.0) {
        return samplePoissonShadow(shadowPos, bias, SHADOW_STABLE_PCF_RADIUS, SHADOW_PCF_SAMPLES);
    }

    float penumbraRadius = getPCSSPenumbraRadius(shadowPos.z, blockerDepth);
    float filterRadius = getShadowStableFilterRadius(penumbraRadius);

    return samplePoissonShadow(shadowPos, bias, filterRadius, PCSS_FILTER_SAMPLES);
}

float getShadowEdgeFade(vec3 shadowPos) {
    float edgeDist = min(min(shadowPos.x, 1.0 - shadowPos.x), min(shadowPos.y, 1.0 - shadowPos.y));
    return smoothstep(0.0, SHADOW_EDGE_FADE, edgeDist);
}

float getShadowVisibility(
    vec3 worldPos,
    float viewDistance,
    float farPlane,
    float sceneMask,
    vec3 worldNormal,
    float normalMask,
    int worldTime,
    float rainStrength
) {
    if (sceneMask < 0.5) return 1.0;

    vec4 shadowClip = shadowProjection * shadowModelView * vec4(worldPos, 1.0);
    vec3 shadowPos = shadowClip.xyz / shadowClip.w;
    shadowPos = shadowPos * 0.5 + 0.5;

    if (shadowPos.x <= 0.0 || shadowPos.x >= 1.0 ||
        shadowPos.y <= 0.0 || shadowPos.y >= 1.0 ||
        shadowPos.z <= 0.0 || shadowPos.z >= 1.0) {
        return 1.0;
    }

    float bias = getShadowBias(worldNormal, normalMask);
    float visibility = 1.0;
#if SHADOW_MODE == 1
    visibility = samplePCSSShadow(shadowPos, bias);
#else
    visibility = samplePoissonShadow(shadowPos, bias, SHADOW_STABLE_PCF_RADIUS, SHADOW_PCF_SAMPLES);
#endif

    float edgeFade = getShadowEdgeFade(shadowPos);
    float weatherFade = 1.0 - clamp(rainStrength, 0.0, 1.0) * 0.55;
    float timeFade = getShadowDayFactor(worldTime);
    float shadowStrength = edgeFade * weatherFade * timeFade;

    return mix(1.0, visibility, shadowStrength);
}

float getRainExposure(
    vec3 worldPos,
    float viewDistance,
    float farPlane,
    float sceneMask,
    vec3 worldNormal,
    float normalMask
) {
    if (sceneMask < 0.5) return 1.0;

    vec4 shadowClip = shadowProjection * shadowModelView * vec4(worldPos, 1.0);
    vec3 shadowPos = shadowClip.xyz / shadowClip.w;
    shadowPos = shadowPos * 0.5 + 0.5;

    if (shadowPos.x <= 0.0 || shadowPos.x >= 1.0 ||
        shadowPos.y <= 0.0 || shadowPos.y >= 1.0 ||
        shadowPos.z <= 0.0 || shadowPos.z >= 1.0) {
        return 1.0;
    }

    float bias = getShadowBias(worldNormal, normalMask) * 1.35;
    float visibility = samplePoissonShadow(shadowPos, bias, SHADOW_POISSON_NEAR_RADIUS, 5);

    float distanceFade = 1.0 - smoothstep(farPlane * 0.62, farPlane, viewDistance);
    float edgeFade = getShadowEdgeFade(shadowPos);
    float exposure = smoothstep(0.18, 0.82, visibility);

    return mix(1.0, clamp(exposure, RAIN_EXPOSURE_MIN, 1.0), distanceFade * edgeFade);
}

vec3 getStableShadowSkyDirection() {
    return normalize(mix(vec3(0.0, 1.0, 0.0), getShadowLightDirection(), 0.85));
}

vec3 getSkyShadowTint(vec3 worldDir, int worldTime, float rainStrength) {
    vec3 skyColor = getSkyColor(worldDir, worldTime, rainStrength);
    float skyLuma = max(dot(skyColor, vec3(0.2126, 0.7152, 0.0722)), 1e-4);
    vec3 normalizedSky = skyColor / skyLuma;

    float dayMask = skyDayMask(worldTime);
    float nightMask = 1.0 - dayMask;
    float twilight = skyTwilightMask(worldTime);
    float rain = clamp(rainStrength, 0.0, 1.0);

    vec3 dayTint = vec3(0.56, 0.64, 0.78);
    vec3 nightTint = vec3(0.46, 0.52, 0.70);
    vec3 twilightTint = vec3(0.78, 0.65, 0.58);
    vec3 weatherTint = vec3(0.56, 0.61, 0.70);

    vec3 timeTint = mix(nightTint, dayTint, dayMask);
    timeTint = mix(timeTint, twilightTint, twilight * 0.42);
    timeTint = mix(timeTint, weatherTint, rain * 0.45);

    vec3 skyTint = clamp(normalizedSky * 0.52, vec3(0.44), vec3(0.98));
    vec3 tint = mix(timeTint, skyTint, 0.24 + rain * 0.08 + nightMask * 0.06);

    return clamp(tint, vec3(0.40), vec3(0.98));
}

vec3 getMaterialShadowTint(
    vec3 baseTint,
    float terrainWetMask,
    float terrainWallMask,
    float lavaMask,
    float waterMask,
    vec3 worldNormal,
    float normalMask,
    int worldTime,
    float rainStrength
) {
    float wetSurface = clamp(max(terrainWetMask, terrainWallMask * 0.55), 0.0, 1.0);
    float water = clamp(waterMask, 0.0, 1.0);
    float lava = clamp(lavaMask, 0.0, 1.0);
    float dayMask = skyDayMask(worldTime);
    float rain = clamp(rainStrength, 0.0, 1.0);

    vec3 wetTint = mix(baseTint, vec3(0.58, 0.68, 0.90), 0.24 + rain * 0.18);
    vec3 waterTint = mix(baseTint, vec3(0.50, 0.66, 0.86), 0.34);
    vec3 lavaTint = mix(baseTint, vec3(0.92, 0.62, 0.42), 0.42);

    float upward = smoothstep(0.25, 0.92, normalize(worldNormal).y) * normalMask;
    vec3 tint = mix(baseTint, wetTint, wetSurface * (0.65 + upward * 0.25));
    tint = mix(tint, waterTint, water * 0.70);
    tint = mix(tint, lavaTint, lava * (0.26 + dayMask * 0.10));
    return clamp(tint, vec3(0.46), vec3(1.08));
}

float getMaterialShadowStrength(
    float sceneMask,
    float terrainWetMask,
    float terrainWallMask,
    float lavaMask,
    float waterMask,
    vec3 worldNormal,
    float normalMask
) {
    float wetSurface = clamp(max(terrainWetMask, terrainWallMask * 0.48), 0.0, 1.0);
    float water = clamp(waterMask, 0.0, 1.0);
    float lava = clamp(lavaMask, 0.0, 1.0);
    float upward = smoothstep(0.15, 0.88, normalize(worldNormal).y) * normalMask;

    float strength = sceneMask;
    strength *= mix(1.0, 0.88, wetSurface * upward);
    strength *= mix(1.0, 0.64, water);
    strength *= mix(1.0, 0.52, lava);
    return clamp(strength, 0.0, 1.0);
}

vec3 applyShadow(
    vec3 color,
    float visibility,
    float sceneMask,
    int worldTime,
    float rainStrength,
    float terrainWetMask,
    float terrainWallMask,
    float lavaMask,
    float waterMask,
    vec3 worldNormal,
    float normalMask
) {
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float darkSurfaceProtection = mix(0.48, 1.0, smoothstep(0.035, 0.34, luma));
    float materialStrength = getMaterialShadowStrength(sceneMask, terrainWetMask, terrainWallMask, lavaMask, waterMask, worldNormal, normalMask);
    float shadowAmount = (1.0 - visibility) * SHADOW_DARKNESS * darkSurfaceProtection * materialStrength;
    vec3 stableSkyDir = getStableShadowSkyDirection();
    vec3 shadowTint = getMaterialShadowTint(getSkyShadowTint(stableSkyDir, worldTime, rainStrength), terrainWetMask, terrainWallMask, lavaMask, waterMask, worldNormal, normalMask, worldTime, rainStrength);
    return mix(color, color * shadowTint * 0.62, shadowAmount);
}
