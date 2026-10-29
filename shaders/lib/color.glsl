// Color grading & vignette utilities

vec3 adjustExposure(vec3 color, float exposure) {
    return color * pow(2.0, exposure);
}

vec3 adjustContrast(vec3 color, float contrast) {
    return (color - 0.5) * contrast + 0.5;
}

vec3 adjustSaturation(vec3 color, float saturation) {
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    return mix(vec3(luma), color, saturation);
}

vec3 colorBalance(vec3 color, vec3 tint) {
    return color * tint;
}

vec3 applyPastelTone(vec3 color) {
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    vec3 pastelBase = mix(vec3(luma), color, 0.96);
    vec3 cream = vec3(1.0, 0.965, 0.91);
    float lift = smoothstep(0.18, 0.95, luma);
    return mix(pastelBase, cream, lift * 0.04);
}

vec3 acesCurve(vec3 color) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    color = max(color, vec3(0.0));
    return (color * (a * color + b)) / (color * (c * color + d) + e);
}

// The scene is 0-1 display color, not HDR; without this scaling white would stop near 0.81.
vec3 tonemapACES(vec3 color, float whitePoint) {
    float whiteScale = acesCurve(vec3(whitePoint)).r;
    return clamp(acesCurve(color) / max(whiteScale, 0.0001), 0.0, 1.0);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 applyDither(vec3 color, vec2 fragCoord) {
    float noise = hash12(fragCoord);
    return clamp(color + (noise - 0.5) / 255.0, 0.0, 1.0);
}

// 1.0 = no darkening, 0.0 = fully dark
float vignette(vec2 uv, float innerRadius, float outerRadius) {
    float dist = length(uv - 0.5);
    return 1.0 - smoothstep(innerRadius, outerRadius, dist);
}
