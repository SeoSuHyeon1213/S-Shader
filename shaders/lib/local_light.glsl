// Installed and held lights use the same lightmap response; only their light levels differ.
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform mat4 gbufferModelViewInverse;

#define TORCH_LIGHT_INTENSITY 1.0 // Held light level multiplier [0.0 0.25 0.5 0.65 0.75 0.85 1.0 1.15 1.3 1.5]

vec2 getLocalLightmapCoord(vec2 originalCoord, vec3 viewPosition) {
    float sourceLevel = max(float(heldBlockLightValue), float(heldBlockLightValue2));
    // World-aligned block distance avoids changing the falloff when the camera turns.
    vec3 lightOffset = (gbufferModelViewInverse * vec4(viewPosition, 0.0)).xyz;
    float blockDistance = dot(abs(lightOffset), vec3(1.0));
    float heldLevel = clamp((sourceLevel - blockDistance) * TORCH_LIGHT_INTENSITY, 0.0, 15.0);
    float heldCoord = (heldLevel + 0.5) / 16.0;
    // Like vanilla block light, overlapping sources take the brighter level instead of adding.
    return vec2(max(originalCoord.x, heldCoord), originalCoord.y);
}

vec3 getLocalBlockLight(vec2 coord) {
    return max(texture2D(lightmap, vec2(coord.x, 0.03125)).rgb
             - texture2D(lightmap, vec2(0.03125, 0.03125)).rgb, vec3(0.0));
}
