#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D depthtex1; // opaque scene copied before translucent water
uniform float viewWidth;
uniform float viewHeight;
uniform int isEyeInWater;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform int worldTime;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 glColor;
varying vec3 viewNormal;
varying vec3 viewDir;
varying float isWater;

#include "/lib/sky.glsl"
#include "/lib/water_depth.glsl"

/* DRAWBUFFERS:023 */

const float WATER_FRESNEL_ALPHA_BOOST = 0.06;
const float WATER_WAVE_NORMAL_STRENGTH = 0.11;

float waterRipple(vec2 uv, float time) {
    float waveA = sin((uv.x + time * 0.018) * 72.0 + uv.y * 19.0);
    float waveB = sin((uv.y - time * 0.014) * 53.0 - uv.x * 23.0);
    return waveA * 0.5 + waveB * 0.5;
}

vec3 getWaterWaveNormal(vec2 uv, float time, vec3 baseNormal) {
    float waveX = sin((uv.x + time * 0.020) * 54.0 + uv.y * 17.0);
    float waveY = cos((uv.y - time * 0.016) * 49.0 - uv.x * 21.0);
    vec3 waveNormal = normalize(vec3(waveX, waveY, 1.0 / WATER_WAVE_NORMAL_STRENGTH));
    return normalize(baseNormal + waveNormal * WATER_WAVE_NORMAL_STRENGTH);
}

float getWaterSpecular(vec3 normal, float ripple) {
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 lightDir = normalize(vec3(-0.25, 0.35, 0.90));
    vec3 halfDir = normalize(viewDir + lightDir);
    float spec = pow(max(dot(normal, halfDir), 0.0), 48.0);
    return spec * (0.55 + ripple * 0.25);
}

void main() {
    vec4 albedo = texture2D(texture, texCoord) * glColor;
    if (albedo.a < 0.05) discard;

    vec3 lightColor = texture2D(lightmap, lmCoord).rgb;
    float ripple = waterRipple(texCoord, frameTimeCounter) * isWater;
    vec3 waterNormal = getWaterWaveNormal(texCoord, frameTimeCounter, normalize(viewNormal));
    vec3 worldWaterNormal = normalize((gbufferModelViewInverse * vec4(waterNormal, 0.0)).xyz);
    float facing = clamp(abs(dot(waterNormal, normalize(-viewDir))), 0.0, 1.0);
    float fresnel = pow(1.0 - facing, 2.0) * isWater;
    float specular = getWaterSpecular(waterNormal, ripple) * isWater;
    vec3 worldDir = normalize((gbufferModelViewInverse * vec4(normalize(viewDir), 0.0)).xyz);
    vec3 reflectionDir = normalize(reflect(worldDir, worldWaterNormal));
    vec3 skyReflection = getSkyWaterReflectionColor(reflectionDir, worldTime, rainStrength);
    vec3 waterTint = getSkyWaterTint(reflectionDir, worldTime, rainStrength);

    vec3 baseColor = albedo.rgb * lightColor;
    vec3 waterColor = mix(baseColor, baseColor * waterTint, 0.34);
    float verticalWater = smoothstep(0.30, 0.86, 1.0 - abs(worldWaterNormal.y)) * isWater;
    waterColor += waterTint * (0.014 + fresnel * 0.022 + ripple * 0.004) * isWater;
    waterColor = mix(waterColor, waterColor * vec3(0.68, 0.78, 0.92), verticalWater * 0.28);
    waterColor += skyReflection * (fresnel * 0.036 + specular * 0.026) * isWater * (1.0 - verticalWater * 0.72);

    vec3 outColor = mix(baseColor, waterColor, isWater);
    float baseAlpha = WATER_FALLBACK_ALPHA;
    if (isWater > 0.5 && isEyeInWater == 0 && verticalWater < 0.5) {
        vec2 screenUv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
        float columnDepth = getWaterColumnDepth(depthtex1, screenUv, viewDir, gbufferProjectionInverse, gbufferModelViewInverse);
        float depthFactor = getWaterDepthFactor(columnDepth);
        baseAlpha = mix(WATER_SHALLOW_ALPHA, WATER_DEEP_ALPHA, depthFactor);
    }
    float waterAlpha = clamp(baseAlpha + fresnel * WATER_FRESNEL_ALPHA_BOOST, 0.0, 1.0);
    float outAlpha = mix(albedo.a, waterAlpha, isWater);

    gl_FragData[0] = vec4(outColor, outAlpha);

    // colortex2 material masks: R = wet floor, G = wall, B = lava, A = water.
    gl_FragData[1] = vec4(0.0, 0.0, 0.0, isWater);

    vec3 encodedNormal = normalize(worldWaterNormal) * 0.5 + 0.5;
    gl_FragData[2] = vec4(encodedNormal, isWater);
}
