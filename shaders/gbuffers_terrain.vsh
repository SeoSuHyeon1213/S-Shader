#version 120

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;

varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 glColor;
varying float isLava;
varying float isTorch;
varying float wetMaskBase;
varying float wallMaskBase;
varying vec3 worldNormalOut;
varying vec3 viewPositionOut;

const float LAVA_BLOCK_ID = 11000.0;
const float WET_STONE_ID = 11100.0;
const float WET_SOIL_ID = 11101.0;
const float WET_WOOD_ID = 11102.0;
const float WET_FOLIAGE_ID = 11103.0;
const float WET_GLASS_ID = 11104.0;
const float WET_CROP_ID = 11105.0;

#include "/lib/waving.glsl"

float isBlockMaterial(float blockId, float materialId) {
    return float(abs(blockId - materialId) < 0.5);
}

// Waving leaves and plants keep the foliage wet response they had before the split.
float isFoliageMaterial(float blockId) {
    return max(isBlockMaterial(blockId, WET_FOLIAGE_ID),
               max(isBlockMaterial(blockId, WAVING_LEAVES_ID),
                   max(isBlockMaterial(blockId, WAVING_PLANT_ID), isBlockMaterial(blockId, WAVING_TALL_UPPER_ID))));
}

float getWetFloorResponse(float blockId) {
    float response = 0.62; // fallback for uncategorized terrain
    response = mix(response, 1.00, isBlockMaterial(blockId, WET_STONE_ID));
    response = mix(response, 0.78, isBlockMaterial(blockId, WET_SOIL_ID));
    response = mix(response, 0.42, isBlockMaterial(blockId, WET_WOOD_ID));
    response = mix(response, 0.30, isFoliageMaterial(blockId));
    response = mix(response, 0.72, isBlockMaterial(blockId, WET_GLASS_ID));
    response = mix(response, 0.16, isBlockMaterial(blockId, WET_CROP_ID));
    return response;
}

float getWetWallResponse(float blockId) {
    float response = 0.44; // fallback for uncategorized terrain
    response = mix(response, 0.72, isBlockMaterial(blockId, WET_STONE_ID));
    response = mix(response, 0.34, isBlockMaterial(blockId, WET_SOIL_ID));
    response = mix(response, 0.38, isBlockMaterial(blockId, WET_WOOD_ID));
    response = mix(response, 0.16, isFoliageMaterial(blockId));
    response = mix(response, 0.66, isBlockMaterial(blockId, WET_GLASS_ID));
    response = mix(response, 0.08, isBlockMaterial(blockId, WET_CROP_ID));
    return response;
}

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    vec3 playerPos = (gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;
    // Atlas V grows downward, so a smaller V than the sprite centre is the top of the plant.
    float topVertex = float(gl_MultiTexCoord0.t < mc_midTexCoord.t);
    vec3 waveOffset = getPlantWaveOffset(mc_Entity.x, playerPos + cameraPosition, topVertex, frameTimeCounter, rainStrength);
    // Only moved vertices are re-projected, keeping other terrain identical to the fixed-function path.
    if (dot(waveOffset, waveOffset) > 0.0) {
        gl_Position = gl_ProjectionMatrix * (gbufferModelView * vec4(playerPos + waveOffset, 1.0));
    }
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    viewPositionOut = (gbufferModelView * vec4(playerPos + waveOffset, 1.0)).xyz;
    lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glColor = gl_Color;
    isLava = float(abs(mc_Entity.x - LAVA_BLOCK_ID) < 0.5);
    isTorch = float(abs(mc_Entity.x - 11002.0) < 0.5);

    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vec3 worldNormal = normalize((gbufferModelViewInverse * vec4(viewNormal, 0.0)).xyz);
    worldNormalOut = worldNormal;
    float nonLava = 1.0 - isLava;
    float blockId = mc_Entity.x;
    float floorWetResponse = getWetFloorResponse(blockId);
    float wallWetResponse = getWetWallResponse(blockId);

    wetMaskBase = smoothstep(0.50, 0.92, worldNormal.y) * floorWetResponse * nonLava;
    wallMaskBase = smoothstep(0.35, 0.85, 1.0 - abs(worldNormal.y)) * wallWetResponse * nonLava;
}
