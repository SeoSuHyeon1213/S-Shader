// Loader directives shared by shadow rendering and final sampling.
const int shadowMapResolution = 2048;
const float shadowDistance = 96.0;
const float shadowIntervalSize = 8.0;
const bool shadowtex0Nearest = true;
const bool shadowHardwareFiltering = false;

const float SHADOW_TEXEL_SIZE = 1.0 / float(shadowMapResolution);
