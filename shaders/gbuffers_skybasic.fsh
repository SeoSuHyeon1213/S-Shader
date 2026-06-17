#version 120

uniform float rainStrength;
uniform int worldTime;
uniform mat4 gbufferModelViewInverse;

varying vec3 viewDir;

#include "/lib/sky.glsl"

/* DRAWBUFFERS:0 */

void main() {
    vec3 worldDir = normalize((gbufferModelViewInverse * vec4(normalize(viewDir), 0.0)).xyz);
    vec3 skyColor = getSkyBaseColor(worldDir, worldTime, rainStrength);

    gl_FragData[0] = vec4(skyColor, 1.0);
}