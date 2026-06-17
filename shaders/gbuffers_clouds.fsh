#version 120

uniform sampler2D texture;
uniform float rainStrength;
uniform int worldTime;
uniform mat4 gbufferModelViewInverse;

varying vec2 texCoord;
varying vec4 vertexColor;
varying vec3 viewDir;

#include "/lib/sky.glsl"

/* DRAWBUFFERS:0 */

const vec3 CLOUD_DAY_COLOR     = vec3(0.86, 0.87, 0.88);
const vec3 CLOUD_NIGHT_COLOR   = vec3(0.26, 0.28, 0.36);
const vec3 CLOUD_RAIN_COLOR    = vec3(0.48, 0.50, 0.55);
const vec3 CLOUD_SUNSET_COLOR  = vec3(0.94, 0.68, 0.52);
const float CLOUD_VOLUME_STRENGTH = 0.42;
const float CLOUD_SHADOW_STRENGTH = 0.26;
const float CLOUD_EDGE_LIGHT_STRENGTH = 0.18;

float sampleCloudAlpha(vec2 uv) {
    return texture2D(texture, uv).a;
}

float getCloudThickness(vec2 uv) {
    vec2 offset = vec2(0.0035, 0.0025);
    float center = sampleCloudAlpha(uv);
    float neighbors =
        sampleCloudAlpha(uv + offset) +
        sampleCloudAlpha(uv - offset) +
        sampleCloudAlpha(uv + offset.yx) +
        sampleCloudAlpha(uv - offset.yx);
    return clamp(center * 0.55 + neighbors * 0.1125, 0.0, 1.0);
}

float getCloudSelfShadow(vec2 uv, float rain) {
    vec2 lightOffset = vec2(-0.006, 0.004);
    float litAlpha = sampleCloudAlpha(uv + lightOffset);
    float shadeAlpha = sampleCloudAlpha(uv - lightOffset * 0.75);
    float densityDiff = clamp(shadeAlpha - litAlpha, 0.0, 1.0);
    return densityDiff * mix(1.0, 1.35, rain);
}

void main() {
    vec4 cloudSample = texture2D(texture, texCoord) * vertexColor;
    if (cloudSample.a < 0.03) discard;

    vec3 worldDir = normalize((gbufferModelViewInverse * vec4(normalize(viewDir), 0.0)).xyz);
    vec3 skyColor = getSkyColor(worldDir, worldTime, rainStrength);

    float dayMask = skyDayMask(worldTime);
    float nightMask = 1.0 - dayMask;
    float transition = skyTransitionMask(dayMask);
    float horizon = skyHorizonMask(worldDir);
    float rain = clamp(rainStrength, 0.0, 1.0);
    float thickness = getCloudThickness(texCoord);
    float selfShadow = getCloudSelfShadow(texCoord, rain);
    float edgeLight = 1.0 - smoothstep(0.35, 0.92, thickness);

    vec3 cloudTint = mix(CLOUD_NIGHT_COLOR, CLOUD_DAY_COLOR, dayMask);
    cloudTint = mix(cloudTint, CLOUD_SUNSET_COLOR, transition * horizon * 0.28);
    cloudTint = mix(cloudTint, CLOUD_RAIN_COLOR, rain * 0.45);

    float cloudLuma = dot(cloudSample.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 shapedCloud = mix(skyColor, cloudTint, 0.28) * mix(0.82, 1.12, cloudLuma);
    shapedCloud *= mix(1.0 - CLOUD_SHADOW_STRENGTH * selfShadow, 1.0, nightMask * 0.35);
    shapedCloud = mix(shapedCloud, shapedCloud * 0.84, thickness * CLOUD_VOLUME_STRENGTH * (0.35 + rain * 0.45));
    shapedCloud += skyColor * edgeLight * CLOUD_EDGE_LIGHT_STRENGTH * (0.45 + dayMask * 0.55);
    float skyBlend = clamp(0.42 + horizon * 0.36 + nightMask * 0.12 + rain * 0.18 + horizon * (rain * 0.12 + nightMask * 0.08), 0.0, 0.90);
    vec3 skyMatchedCloud = mix(shapedCloud, skyColor, skyBlend);

    gl_FragData[0] = vec4(skyMatchedCloud, cloudSample.a);
}
