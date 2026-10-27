#version 120

varying vec2 texCoord;

uniform sampler2D colortex1; // horizontal bloom from composite
uniform sampler2D colortex4; // horizontal lava halo from composite
uniform float viewHeight;

#include "/lib/bloom.glsl"

/* DRAWBUFFERS:1 */

#define LAVA_EMISSION_INTENSITY 1.0 // Lava emission strength [0.0 0.5 0.75 1.0 1.25 1.5 2.0]

// Vertical half of the separable bloom; offsets land on texel centers, so the result matches the 5x5 kernel.
void main() {
    float texelY = 1.0 / viewHeight;
    vec3 result = vec3(0.0);

    for (int y = -2; y <= 2; y++) {
        result += texture2D(colortex1, texCoord + vec2(0.0, float(y) * texelY * BLOOM_SPREAD)).rgb * gaussianWeight(y);
    }

    if (LAVA_EMISSION_INTENSITY > 0.0) {
        for (int y = -1; y <= 1; y++) {
            vec2 sampleUv = texCoord + vec2(0.0, float(y) * texelY * LAVA_GLOW_SPREAD);
            result += texture2D(colortex4, sampleUv).rgb * lavaGlowWeight(y) * isBloomUvInside(sampleUv);
        }
    }

    gl_FragData[0] = vec4(min(result, vec3(BLOOM_CLAMP)), 1.0);
}
