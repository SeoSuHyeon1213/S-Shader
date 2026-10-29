// Wind sway for leaves and plants, shared by terrain and shadow passes so shadows follow the motion.
#define WAVING_PLANTS 1 // Leaf and plant wind sway [0 1]
#define WAVING_STRENGTH 1.0 // Wind sway amount [0.25 0.5 0.75 1.0 1.25 1.5 2.0]

// Keep these IDs in sync with block.properties.
const float WAVING_CROP_ID = 11105.0;
const float WAVING_LEAVES_ID = 11106.0;
const float WAVING_PLANT_ID = 11107.0;        // single plants and lower halves of tall plants
const float WAVING_TALL_UPPER_ID = 11108.0;   // upper halves of tall plants

const float WAVING_LEAF_AMPLITUDE = 0.030;    // blocks, before gust and rain
const float WAVING_PLANT_AMPLITUDE = 0.060;   // blocks at the top of a one-block plant

float isWavingMaterial(float blockId, float materialId) {
    return float(abs(blockId - materialId) < 0.5);
}

// Offset depends only on world position, so vertices shared by neighbouring blocks move together.
vec3 getWindSway(vec3 worldPos, float time, float rain) {
    float phase = dot(worldPos.xz, vec2(0.61, 0.37));
    float gust = sin(time * 0.55 + worldPos.x * 0.07 + worldPos.z * 0.05) * 0.5 + 0.5;
    float swayX = sin(time * 1.9 + phase * 1.7) + sin(time * 3.1 + worldPos.z * 2.3) * 0.35;
    float swayZ = cos(time * 1.6 + phase * 1.3) + sin(time * 2.7 + worldPos.x * 2.1) * 0.35;
    float strength = (0.55 + gust * 0.45) * (1.0 + clamp(rain, 0.0, 1.0) * 0.6);
    return vec3(swayX, 0.0, swayZ) * strength;
}

// World-space offset for a plant vertex; zero for every other block.
vec3 getPlantWaveOffset(float blockId, vec3 worldPos, float topVertex, float time, float rain) {
#if WAVING_PLANTS == 1
    float leaves = isWavingMaterial(blockId, WAVING_LEAVES_ID);
    float anchored = max(isWavingMaterial(blockId, WAVING_PLANT_ID), isWavingMaterial(blockId, WAVING_CROP_ID));
    float tallUpper = isWavingMaterial(blockId, WAVING_TALL_UPPER_ID);
    // Anchored plants keep their base still; a tall plant's upper half continues from the lower half's top.
    float amount = leaves * WAVING_LEAF_AMPLITUDE
                 + anchored * topVertex * WAVING_PLANT_AMPLITUDE
                 + tallUpper * (1.0 + topVertex) * WAVING_PLANT_AMPLITUDE;
    if (amount <= 0.0) return vec3(0.0);

    vec3 sway = getWindSway(worldPos, time, rain);
    // Leaves also flutter a little vertically; plants only bend sideways.
    sway.y = leaves * sin(time * 2.3 + dot(worldPos, vec3(1.3, 0.9, 1.7))) * 0.4;
    return sway * amount * WAVING_STRENGTH;
#else
    return vec3(0.0);
#endif
}
