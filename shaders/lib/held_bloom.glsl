// Rendered-item identity prevents an emissive item in one hand from lighting up the other hand's skin/item.
uniform int currentRenderedItemId;

float getHeldBloomMask(vec3 texel) {
    if (currentRenderedItemId == 11002) {
        return smoothstep(0.60, 0.85, texel.r) * smoothstep(0.45, 0.70, texel.g);
    }
    if (currentRenderedItemId == 11003) {
        float hotColor = smoothstep(0.45, 0.80, texel.r);
        float orange = smoothstep(0.08, 0.30, texel.r - texel.g);
        return hotColor * orange * (1.0 - smoothstep(0.35, 0.60, texel.b));
    }
    return 0.0;
}
