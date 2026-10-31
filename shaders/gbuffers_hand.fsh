#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 glColor;
varying vec3 worldNormalOut;
varying vec3 viewPositionOut;

#include "/lib/local_light.glsl"

/* DRAWBUFFERS:0235 */

void main() {
    vec4 albedo = texture2D(texture, texCoord) * glColor;
    if (albedo.a < 0.10) discard;

    vec2 effectiveLmCoord = getLocalLightmapCoord(lmCoord, viewPositionOut);
    vec3 localLight = albedo.rgb * getLocalBlockLight(effectiveLmCoord);
    albedo.rgb *= texture2D(lightmap, effectiveLmCoord).rgb;
    localLight = min(localLight, albedo.rgb);

    // Held items and hands must stay opaque in the scene color buffer.
    gl_FragData[0] = vec4(albedo.rgb, 1.0);

    // No terrain material, lava, or water masks for held items/entities.
    gl_FragData[1] = vec4(0.0);

    vec3 encodedNormal = normalize(worldNormalOut) * 0.5 + 0.5;
    gl_FragData[2] = vec4(encodedNormal, 1.0);
    // Negative alpha excludes the hand from bloom, not from texture-based local lighting.
    gl_FragData[3] = vec4(localLight, -1.0);
}
