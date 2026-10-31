#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 glColor;
varying float isLava;
varying float isTorch;
varying float wetMaskBase;
varying float wallMaskBase;
varying vec3 worldNormalOut;
varying vec3 viewPositionOut;

#include "/lib/local_light.glsl"

/* DRAWBUFFERS:0235 */

void main() {
    vec4 textureSample = texture2D(texture, texCoord);
    vec4 albedo = textureSample * glColor;
    if (albedo.a < 0.1) discard;

    // Only the bright torch head emits; the wooden handle keeps normal lighting.
    vec3 texel = textureSample.rgb;
    float torchFlame = isTorch * smoothstep(0.55, 0.85, max(texel.r, texel.g));
    vec2 effectiveLmCoord = getLocalLightmapCoord(lmCoord, viewPositionOut);
    vec3 lightColor = texture2D(lightmap, effectiveLmCoord).rgb;
    vec3 blockLight = getLocalBlockLight(effectiveLmCoord);
    vec3 litColor = albedo.rgb * mix(lightColor, vec3(1.0), max(isLava, torchFlame));
    // Separate the vanilla block-light component before sunlight shadows are applied.
    vec3 localLight = min(litColor, albedo.rgb * blockLight);
    localLight = mix(localLight, litColor, torchFlame) * (1.0 - isLava);
    albedo.rgb = litColor;

    // Keep the scene color buffer opaque. Some Iris/composite paths can treat
    // colortex0 alpha as real transparency, so material masks live in colortex2.
    gl_FragData[0] = vec4(albedo.rgb, 1.0);

    // colortex2 carries material masks:
    // R = material-weighted wet floor, G = material-weighted wet wall,
    // B = lava/emissive block, A = water. Terrain never writes water mask.
    gl_FragData[1] = vec4(wetMaskBase, wallMaskBase, isLava, 0.0);

    vec3 encodedNormal = normalize(worldNormalOut) * 0.5 + 0.5;
    gl_FragData[2] = vec4(encodedNormal, 1.0);
    gl_FragData[3] = vec4(localLight, torchFlame);
}
