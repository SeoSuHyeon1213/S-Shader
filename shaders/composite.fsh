#version 120

varying vec2 texCoord;

uniform sampler2D colortex0; // scene color
uniform sampler2D colortex2; // terrain material masks
uniform sampler2D colortex3; // encoded world normals
uniform float viewWidth;
uniform float viewHeight;

/* DRAWBUFFERS:0123 */

#define BLOOM_THRESHOLD 0.8 // Bloom threshold [0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.4 1.6]
#define LAVA_EMISSION_INTENSITY 1.0 // Lava emission strength [0.0 0.5 0.75 1.0 1.25 1.5 2.0]
const float BLOOM_KNEE      = 0.2;
const float BLOOM_SPREAD    = 4.0; // texel multiplier
const float BLOOM_CLAMP     = 8.0;
const vec3 LAVA_BLOOM_COLOR = vec3(1.000, 0.227, 0.125);
const float LAVA_BLOOM_STRENGTH = 1.35;
const float LAVA_GLOW_SPREAD = 18.0;

float gaussianWeight(int offset) {
    if (offset == 0) return 0.4026;
    if (offset == -1 || offset == 1) return 0.2442;
    return 0.0545;
}

vec3 brightPass(vec2 uv) {
    vec3 color = texture2D(colortex0, uv).rgb;
    float lavaMask = texture2D(colortex2, uv).b;
    float brightness = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float contribution = smoothstep(BLOOM_THRESHOLD, BLOOM_THRESHOLD + BLOOM_KNEE, brightness);
    vec3 sceneBloom = color * contribution;
    vec3 lavaBloom = mix(color, LAVA_BLOOM_COLOR, 0.58) * lavaMask * LAVA_BLOOM_STRENGTH * LAVA_EMISSION_INTENSITY;
    return max(sceneBloom, lavaBloom);
}

vec3 blurBloom(vec2 uv) {
    vec2 texel = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec3 result = vec3(0.0);

    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 offset = vec2(float(x), float(y)) * texel * BLOOM_SPREAD;
            float weight = gaussianWeight(x) * gaussianWeight(y);

            result += brightPass(uv + offset) * weight;
        }
    }

    // A separate nine-tap halo widens only lava glow, keeping scene bloom sharp.
    if (LAVA_EMISSION_INTENSITY > 0.0) {
        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                vec2 sampleUv = uv + vec2(float(x), float(y)) * texel * LAVA_GLOW_SPREAD;
                if (sampleUv.x < 0.0 || sampleUv.x > 1.0 || sampleUv.y < 0.0 || sampleUv.y > 1.0) continue;
                float lavaMask = texture2D(colortex2, sampleUv).b;
                vec3 lavaColor = texture2D(colortex0, sampleUv).rgb;
                float weightX = x == 0 ? 0.5 : 0.25;
                float weightY = y == 0 ? 0.5 : 0.25;
                result += mix(lavaColor, LAVA_BLOOM_COLOR, 0.58) * lavaMask *
                          weightX * weightY * LAVA_BLOOM_STRENGTH * LAVA_EMISSION_INTENSITY * 0.65;
            }
        }
    }
    return min(result, vec3(BLOOM_CLAMP));
}

void main() {
    gl_FragData[0] = texture2D(colortex0, texCoord); // pass scene color through
    gl_FragData[1] = vec4(blurBloom(texCoord), 1.0);  // blurred bloom buffer
    gl_FragData[2] = texture2D(colortex2, texCoord); // pass terrain masks through
    gl_FragData[3] = texture2D(colortex3, texCoord); // pass encoded world normals through
}
