// Separable bloom kernels shared by the horizontal (composite) and vertical (composite1) passes.
const float BLOOM_SPREAD    = 4.0; // texel multiplier
const float BLOOM_CLAMP     = 8.0;
const vec3 LAVA_BLOOM_COLOR = vec3(1.000, 0.227, 0.125);
const float LAVA_BLOOM_STRENGTH = 1.35;
const float LAVA_GLOW_SPREAD = 18.0;
const float LAVA_GLOW_SCALE = 0.65;

float gaussianWeight(int offset) {
    if (offset == 0) return 0.4026;
    if (offset == -1 || offset == 1) return 0.2442;
    return 0.0545;
}

float lavaGlowWeight(int offset) {
    return offset == 0 ? 0.5 : 0.25;
}

float isBloomUvInside(vec2 uv) {
    return float(uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0);
}
