// Four-neighbour unsharp mask with bounded overshoot; zero strength preserves the original sample.
vec3 sharpenScene(sampler2D scene, vec2 uv, vec3 center, vec2 resolution, float strength) {
    if (strength <= 0.0) return center;
    vec2 pixel = 1.0 / max(resolution, vec2(1.0));
    vec2 lowUv = pixel * 0.5;
    vec2 highUv = vec2(1.0) - lowUv;
    vec3 left = texture2D(scene, clamp(uv - vec2(pixel.x, 0.0), lowUv, highUv)).rgb;
    vec3 right = texture2D(scene, clamp(uv + vec2(pixel.x, 0.0), lowUv, highUv)).rgb;
    vec3 up = texture2D(scene, clamp(uv + vec2(0.0, pixel.y), lowUv, highUv)).rgb;
    vec3 down = texture2D(scene, clamp(uv - vec2(0.0, pixel.y), lowUv, highUv)).rgb;
    vec3 detail = center - (left + right + up + down) * 0.25;
    vec3 lower = max(vec3(0.0), min(center, min(min(left, right), min(up, down))) - 0.04);
    vec3 upper = min(vec3(1.0), max(center, max(max(left, right), max(up, down))) + 0.04);
    return clamp(center + detail * strength, lower, upper);
}
