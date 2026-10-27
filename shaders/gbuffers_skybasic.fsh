#version 120

uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;
uniform int worldTime;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#include "/lib/sky.glsl"

/* DRAWBUFFERS:0 */

void main() {
    // Rebuild the direction per pixel: interpolating per-vertex normalized dirs across the large sky plane,
    // void plane and sunrise fan bends them differently and leaves visible seams between those meshes.
    vec2 screenUv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    vec4 viewPos = gbufferProjectionInverse * vec4(screenUv * 2.0 - 1.0, 1.0, 1.0);
    vec3 viewDir = normalize(viewPos.xyz / viewPos.w);
    vec3 worldDir = normalize((gbufferModelViewInverse * vec4(viewDir, 0.0)).xyz);
    vec3 skyColor = getSkyBaseColor(worldDir, worldTime, rainStrength);

    gl_FragData[0] = vec4(skyColor, 1.0);
}
