// Water depth response shared by transparency and final reflections.
const float WATER_SHALLOW_DEPTH = 2.0;
const float WATER_DEEP_DEPTH = 12.0;
const float WATER_SHALLOW_ALPHA = 0.35;
const float WATER_DEEP_ALPHA = 0.70;
const float WATER_SHALLOW_REFLECTION = 0.25;
const float WATER_DEEP_REFLECTION = 0.60;
const float WATER_FALLBACK_ALPHA = 0.45;
const float WATER_REFLECTION_REFERENCE = 0.60;

float getWaterColumnDepth(
    sampler2D opaqueDepthTexture,
    vec2 uv,
    vec3 surfaceViewPos,
    mat4 projectionInverse,
    mat4 modelViewInverse
) {
    float bottomDepth = texture2D(opaqueDepthTexture, uv).r;
    // A missing bottom is optically deep, not a nearby shallow surface.
    if (bottomDepth >= 1.0) return WATER_DEEP_DEPTH;

    vec4 bottomClip = vec4(uv * 2.0 - 1.0, bottomDepth * 2.0 - 1.0, 1.0);
    vec4 bottomView = projectionInverse * bottomClip;
    vec3 bottomViewPos = bottomView.xyz / bottomView.w;
    vec3 columnDelta = (modelViewInverse * vec4(surfaceViewPos - bottomViewPos, 0.0)).xyz;
    // Vertical separation avoids treating a long grazing view ray as deep water.
    return max(columnDelta.y, 0.0);
}

float getWaterDepthFactor(float columnDepth) {
    return smoothstep(WATER_SHALLOW_DEPTH, WATER_DEEP_DEPTH, columnDepth);
}

float getWaterReflectionScale(float depthFactor) {
    return mix(WATER_SHALLOW_REFLECTION, WATER_DEEP_REFLECTION, depthFactor) / WATER_REFLECTION_REFERENCE;
}
