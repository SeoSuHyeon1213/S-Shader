// Loader directives and shadow-space distortion shared by shadow rendering and final sampling.
const int shadowMapResolution = 2048; // Shadow map resolution [1024 2048 3072 4096]
const float shadowDistance = 160.0; // Shadow projection radius in blocks [32.0 48.0 64.0 96.0 128.0 160.0 192.0 256.0]
const float shadowDistanceRenderMul = 1.0; // Render shadow casters only within shadowDistance
const float shadowIntervalSize = 8.0;
const bool shadowtex0Nearest = true;
const bool shadowHardwareFiltering = false;

const float SHADOW_TEXEL_SIZE = 1.0 / float(shadowMapResolution);

// 0 keeps texels evenly spread; values near 1 pack more of the map near the player.
const float SHADOW_DISTORTION = 0.85;

float getShadowDistortionFactor(vec2 shadowClipXY) {
    return length(shadowClipXY) * SHADOW_DISTORTION + (1.0 - SHADOW_DISTORTION);
}

vec2 distortShadowClip(vec2 shadowClipXY) {
    return shadowClipXY / getShadowDistortionFactor(shadowClipXY);
}

// World size of one shadow texel relative to the undistorted map (derivative of the distortion).
float getShadowDistortionTexelScale(vec2 shadowClipXY) {
    float factor = getShadowDistortionFactor(shadowClipXY);
    return factor * factor / (1.0 - SHADOW_DISTORTION);
}
