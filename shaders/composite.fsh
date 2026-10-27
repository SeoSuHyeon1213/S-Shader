#version 120

varying vec2 texCoord;

uniform sampler2D colortex0; // scene color
uniform sampler2D colortex2; // terrain material masks
uniform sampler2D colortex3; // encoded world normals
uniform float viewWidth;
uniform float viewHeight;

#include "/lib/bloom.glsl"

/* DRAWBUFFERS:01234 */

// Buffer formats are loader directives; keep each one alone on its line inside the block comment.
// colortex0 = scene color, colortex1 = bloom (16F reduces blur banding),
// colortex2 = floor/wall/lava/water masks, colortex3 = encoded world normal + valid mask,
// colortex4 = horizontal lava halo between composite and composite1.
/*
const int colortex0Format = RGBA8;
const int colortex1Format = RGBA16F;
const int colortex2Format = RGBA8;
const int colortex3Format = RGBA16F;
const int colortex4Format = RGBA16F;
*/

#define BLOOM_THRESHOLD 0.8 // Bloom threshold [0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.4 1.6]
#define LAVA_EMISSION_INTENSITY 1.0 // Lava emission strength [0.0 0.5 0.75 1.0 1.25 1.5 2.0]
const float BLOOM_KNEE      = 0.2;

vec3 brightPass(vec2 uv) {
    vec3 color = texture2D(colortex0, uv).rgb;
    float lavaMask = texture2D(colortex2, uv).b;
    float brightness = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float contribution = smoothstep(BLOOM_THRESHOLD, BLOOM_THRESHOLD + BLOOM_KNEE, brightness);
    vec3 sceneBloom = color * contribution;
    vec3 lavaBloom = mix(color, LAVA_BLOOM_COLOR, 0.58) * lavaMask * LAVA_BLOOM_STRENGTH * LAVA_EMISSION_INTENSITY;
    return max(sceneBloom, lavaBloom);
}

// Horizontal half of the separable 5x5 bloom; composite1 applies the vertical half.
vec3 blurBloomHorizontal(vec2 uv) {
    float texelX = 1.0 / viewWidth;
    vec3 result = vec3(0.0);

    for (int x = -2; x <= 2; x++) {
        result += brightPass(uv + vec2(float(x) * texelX * BLOOM_SPREAD, 0.0)) * gaussianWeight(x);
    }
    return result;
}

// Horizontal half of the wide lava-only halo, kept apart because its spread differs.
vec3 blurLavaGlowHorizontal(vec2 uv) {
    vec3 result = vec3(0.0);
    if (LAVA_EMISSION_INTENSITY <= 0.0) return result;

    float texelX = 1.0 / viewWidth;
    for (int x = -1; x <= 1; x++) {
        vec2 sampleUv = uv + vec2(float(x) * texelX * LAVA_GLOW_SPREAD, 0.0);
        float lavaMask = texture2D(colortex2, sampleUv).b;
        vec3 lavaColor = texture2D(colortex0, sampleUv).rgb;
        result += mix(lavaColor, LAVA_BLOOM_COLOR, 0.58) * lavaMask * lavaGlowWeight(x) * isBloomUvInside(sampleUv);
    }
    return result * LAVA_BLOOM_STRENGTH * LAVA_EMISSION_INTENSITY * LAVA_GLOW_SCALE;
}

void main() {
    gl_FragData[0] = texture2D(colortex0, texCoord); // pass scene color through
    gl_FragData[1] = vec4(blurBloomHorizontal(texCoord), 1.0); // horizontal bloom
    gl_FragData[2] = texture2D(colortex2, texCoord); // pass terrain masks through
    gl_FragData[3] = texture2D(colortex3, texCoord); // pass encoded world normals through
    gl_FragData[4] = vec4(blurLavaGlowHorizontal(texCoord), 1.0); // horizontal lava halo
}
