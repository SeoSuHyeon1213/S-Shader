#version 120

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;

varying vec2 texCoord;
varying vec4 vertexColor;
varying float shadowCasterMask;
varying float shadowCasterOpacity;

const float LAVA_BLOCK_ID = 11000.0;
const float WATER_BLOCK_ID = 11001.0;
const float WET_FOLIAGE_ID = 11103.0;
const float WET_GLASS_ID = 11104.0;
const float WET_CROP_ID = 11105.0;

#include "/lib/waving.glsl"

float isBlockMaterial(float blockId, float materialId) {
    return float(abs(blockId - materialId) < 0.5);
}

float getShadowCasterOpacity(float blockId) {
    float opacity = 1.0;
    opacity = mix(opacity, 0.58, isBlockMaterial(blockId, WET_FOLIAGE_ID));
    opacity = mix(opacity, 0.58, isBlockMaterial(blockId, WAVING_LEAVES_ID));
    opacity = mix(opacity, 0.58, isBlockMaterial(blockId, WAVING_PLANT_ID));
    opacity = mix(opacity, 0.58, isBlockMaterial(blockId, WAVING_TALL_UPPER_ID));
    opacity = mix(opacity, 0.30, isBlockMaterial(blockId, WET_GLASS_ID));
    opacity = mix(opacity, 0.44, isBlockMaterial(blockId, WET_CROP_ID));
    return opacity;
}

void main() {
    gl_Position = ftransform();
    // Match the terrain sway so cast shadows move with the plants.
    vec3 playerPos = (shadowModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;
    float topVertex = float(gl_MultiTexCoord0.t < mc_midTexCoord.t);
    vec3 waveOffset = getPlantWaveOffset(mc_Entity.x, playerPos + cameraPosition, topVertex, frameTimeCounter, rainStrength);
    if (dot(waveOffset, waveOffset) > 0.0) {
        gl_Position = gl_ProjectionMatrix * (shadowModelView * vec4(playerPos + waveOffset, 1.0));
    }
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vertexColor = gl_Color;

    float blockId = mc_Entity.x;
    float skipWater = isBlockMaterial(blockId, WATER_BLOCK_ID);
    float skipLava = isBlockMaterial(blockId, LAVA_BLOCK_ID);
    shadowCasterOpacity = getShadowCasterOpacity(blockId);
    shadowCasterMask = 1.0 - clamp(max(skipWater, skipLava), 0.0, 1.0);
}
