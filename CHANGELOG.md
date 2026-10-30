# Changelog

All notable changes to this shader pack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## 2026-10-30 - Wider Shadows with Distortion, Distance Fade and Aerial Haze

### Added

- Player-centred shadow distortion (`SHADOW_DISTORTION = 0.85`) in `shadow.vsh` and the final sampling, so the shadow map spends its texels near the player. The depth bias scales with the local texel size.
- `shadowMapResolution` option (1024, 2048, 3072, 4096).
- Circular distance fade from 72% to 94% of `shadowDistance`, replacing the square cut-off at the map edge. Rain exposure uses the same fade.
- `AERIAL_FOG_STRENGTH` (default 0.45): block-distance haze that starts at 40% of `shadowDistance` and builds over twice that distance, using the existing sky fog colour. It is not applied while the camera is underwater.

### Changed

- Default `shadowDistance` 96 -> 160, and `shadowDistanceRenderMul = 1.0` so shadow casters render only within that radius.

### Test Notes

- Checked in game by the user with the test pack. Detailed acne/peter-panning, movement, fade ring, haze tuning and FPS comparisons are not recorded yet.

## 2026-10-30 - Opaque First-Person Arm and Entities

### Fixed

- On Minecraft 26.x the first-person arm uses a translucent render type, so Iris draws it in `gbuffers_hand` with blending on. The pass's zero-alpha masks then left the terrain masks behind the arm in place, and `final.fsh` shaded the arm as that terrain: ground shadows, lava glow and wet effects showed through, so the arm looked see-through. Blending is now off for `colortex2`/`colortex3` in `gbuffers_hand`, `gbuffers_hand_water` and `gbuffers_entities`, so these passes replace the terrain data with empty masks and their own normal.

### Test Notes

- Diagnostic packs on NeoForge 26.x (Windows 11, RTX 3060 Ti, driver 616.56): the arm is drawn by `gbuffers_hand`, its UVs are valid, and it is opaque in `colortex0` when `final.fsh` is skipped. The fixed pack was confirmed in game by the user (opaque arm).

## 2026-10-29 - Keep Terrain Data Behind Stained Glass and Ice

### Fixed

- `gbuffers_water` also draws non-water translucents such as stained glass and ice. With blending off for `colortex2`/`colortex3`, those fragments overwrote the terrain behind them with empty masks and an invalid normal. That terrain then lost shadows and wet-surface effects. The buffers now blend by alpha as an ownership flag: water writes 1 and replaces the opaque data, other translucents write 0 and keep it.
- Shadow and rain-exposure lookups for terrain seen through a non-water translucent use the opaque `depthtex1` position instead of the glass surface.

### Test Notes

- A blend simulation of water/glass over terrain and both draw orders gave the expected owner. In-game compilation and visuals are unverified. `gbuffers_hand_water` still writes zero-alpha masks under default blending and may not clear terrain data behind held translucent items.

## 2026-10-29 - Waving Leaves and Plants

### Added

- Wind sway for leaves, grass, flowers, ferns, tall plants and crops, with `WAVING_PLANTS` (on/off) and `WAVING_STRENGTH` options. The offset is a function of world position and time, so shared vertices between neighbouring blocks move together. Plants bend from a still base, and the upper half of a tall plant continues the lower half's top offset. Rain strengthens the sway by up to 60%.
- `shadow.vsh` applies the same offset so cast shadows follow the motion.

### Changed

- Moved leaves to 11106, and grass/ferns/flowers/lower tall-plant halves to 11107, upper halves to 11108, keeping the foliage wet response and shadow caster opacity. Flowers were previously uncategorized and now use the foliage wet response.

### Test Notes

- Numeric checks: the anchored base offset is 0, and the seam between tall-plant halves is 0. Peak offsets in full rain at strength 1.0 are about 0.09 (leaves), 0.18 (one-block plants) and 0.36 blocks (tall plant tops). Block-state syntax (`half=upper`), version-specific names, compilation, visuals and FPS remain unverified in game.

## 2026-10-29 - Tone Curve Contrast and Shadow Strength Option

### Changed

- ACES now normalizes by a graded white level (scene value `1.25`), because the scene is 0-1 display color rather than HDR. Previously input 1.0 stopped near 0.81, and contrast 0.88 lifted black to about 0.06, so a test on another PC looked bright and washed out.
- Changed the defaults to `EXPOSURE` -0.25 (from 0.05), `CONTRAST` 1.05 (from 0.88) and `SATURATION` 1.0 (from 0.936). The pastel tone now keeps 96% chroma and blends 4% cream into highlights (previously 92% and 8%).
- Added a `SHADOW_STRENGTH` option (default 1.0, range 0.0-1.3). It raises the cast-shadow factor to a power, so values above 1.0 keep darkening smoothly without saturating the blend.

### Test Notes

- Gray-ramp calculation (old to new): 0.00 to 0.06/0.00, 0.08 to 0.18/0.05, 0.25 to 0.43/0.36, 0.55 to 0.67/0.73, 1.00 to 0.81/0.94. Near-black inputs up to about 0.03 now map to 0, so cave and night readability needs an in-game check. Saved option values override the new defaults.

## 2026-10-27 - Separable Bloom and Light-Elevation Shadow Fade

### Changed

- Split the 5x5 scene bloom and the 3x3 lava halo into a horizontal `composite` pass and a vertical `composite1` pass, with shared kernels in `lib/bloom.glsl`. The lava halo's horizontal result goes through a new `colortex4` (RGBA16F). Bloom texture reads drop from 68 to 24 per pixel, and the output matches the single-pass kernel.
- Replaced the `worldTime`-window shadow day factor with a fade driven by the shadow light's world-space elevation. Shadows reach 0 as the sun or moon nears the horizon, including at the sun/moon switch, and the moon keeps 0.42x strength via `sunAngle`. Shadow sampling is skipped when the fade is 0.
- Renamed a local `sunAngle` in `getWetLightDirection()` so it no longer hides the new uniform.

### Test Notes

- A numeric comparison on a 97x61 random image matched the old bloom within 2.2e-16 (excluding RGBA16F intermediate rounding in game). On a simplified sun path, the new fade is stronger in the early morning and weaker in the last hour before sunset than the old time window. In-game compilation, visuals and FPS remain unverified.

## 2026-10-19 - No Sky Mirror on the Underwater Surface

### Fixed

- With the eye underwater, the final pass applied the full stable sky reflection (and the SSR sky fallback in mode 1) to the underside of the water surface. `isEyeInWater == 1` now sets the water reflection intensity to 0, and `gbuffers_water` skips its small sky highlight term.
- `applyWaterSSR()` returns early when the intensity is 0, skipping the ray march.

### Test Notes

- Static check only: every sky-colored term in `applyWaterSurface()` and `applyWaterSSR()` scales with the intensity. Snell's window and total internal reflection are not implemented. In-game visuals remain unverified.

## 2026-10-19 - Water Wave Normal Camera Bias

### Fixed

- `gbuffers_water.fsh` added a tangent-space wave vector to the view-space normal, so its constant Z part tilted every water normal about 6 degrees toward the camera. Ripples now tilt only within the world-space surface plane, and the view-space normal is derived from that result with `gbufferModelView`.
- The bias affected the written `colortex3` normal, Fresnel, alpha boost, vertical-water detection and the final stable reflection direction. Ripple amplitude is kept within about 1 degree of the previous value.

### Test Notes

- A numeric check over top and waterfall faces and 12 camera directions showed 0 degrees of zero-ripple bias (previously up to 6.3). Fresnel at a 10-degree downward view rises from about 0.52 to 0.68. In-game compilation and visuals remain unverified.

## 2026-10-19 - Water SSR Reflection Direction

### Fixed

- Water SSR (`WATER_REFLECTION_MODE = 1`) reflected the camera-facing vector about a screen-facing view Z normal, mirroring rays horizontally and ignoring camera pitch. It now reflects the eye-to-surface ray about the flat water plane normal transformed by `gbufferModelView`, faced toward the camera for views from below.
- Fresnel now uses the angle to that surface normal instead of the screen position. Ripples tilt the plane in world XZ with the same magnitude, so the roughness input is unchanged.

### Test Notes

- A flat-plane numeric check (560 camera/pixel cases, above and below water) matched the ground-truth mirror direction within 1e-6 degrees; the old path was off by up to about 164 degrees. In-game compilation, visuals and FPS remain unverified.

## 2026-10-17 - Buffer Format Directives and README Accuracy

### Fixed

- Moved colortex0-3 formats from ignored `shaders.properties` keys into block-comment loader directives in `composite.fsh` (RGBA8, RGBA16F, RGBA8, RGBA16F).

### Documentation

- Corrected README shadow movement wording, water reflection mode 1 path (SSR replaces stable reflection with sky fallback), PCF sample/read counts and the torch design vs. constant color.
- Added `WATER_REFLECTION_INTENSITY` to the option list and separated implemented, approximate/limited, verification and planned items.

### Test Notes

- Static checks only. In-game compilation and buffer format confirmation remain pending; no Iris/NeOculus environment was available.

## 2026-10-05 - Depth-Based Water Transparency and Reflections

### Changed

- Added a shared water depth helper using vertical separation between the water surface and opaque depthtex1 geometry, with a deep-water fallback when no bottom is visible.
- Blend base alpha from 0.35 at up to 2 blocks to 0.70 at 12 blocks and deeper; retain a 0.06 Fresnel alpha boost.
- Scale stable and SSR reflection strength from 0.25 to 0.60 at the existing 0.60 master setting, and use the same depth response for water absorption instead of camera distance.
- Use alpha 0.45 for vertical water and underwater views; calculate Fresnel from the actual surface-to-camera direction.
- Disable blending for the water pass material and normal buffers while retaining color alpha blending.

### Test Notes

- Numerical flat-bottom reconstruction and static shader interface checks passed. In-game compilation, sloping/occluded-bottom scenes, underwater/vertical water and performance remain unverified.

## 2026-10-05 - Shadow Fragmentation and Sampling Corrections

### Fixed

- Moved shadow resolution/distance/snapping from unsupported bare properties into shared GLSL loader constants, matching the 2048 map resolution to the texel size used by filters.
- Separated terrain receiver presence from wet-material response so low-response soil/wood/wall surfaces no longer bypass shadow visibility at a 0.5 threshold.
- Replaced screen-derivative depth bias with bounded world-normal/light-direction bias scaled by the shadow projection and texel size.
- Enabled nearest raw depth sampling and bilinearly interpolated per-texel comparison results instead of comparing interpolated depths across discontinuities.
- Made fixed-radius PCF the default; optional PCSS falls back to PCF when its sparse blocker search misses an occluder.
- Skip rain-exposure sampling in dry weather to offset the cost of manual comparison filtering.

### Test Notes

- Persisted `SHADOW_MODE = 1` overrides the new default; select `0` for the stable comparison. In-game compilation, screenshots and performance checks remain pending.

## 2026-10-05 - Sun-Driven Shadow Stability and Darker Shading

### Changed

- Removed player-distance split attenuation and distance-dependent PCSS filter radius. Penumbra still follows light-space blocker/receiver separation.
- Matched terrain form lighting and shadow sky tint to the actual shadowModelView light direction instead of an approximate time-based orbit.
- Removed view-angle attenuation from terrain form shadows; specular highlights retain their view dependence.
- Increased shadow darkness from 0.86 to 0.94 and multiplied the shadow tint target by 0.62, retaining dark-surface protection.

### Test Notes

- Shader compilation and in-game movement/time comparisons remain pending. Single-map reprojection, edge fade and fog can still change distant shadow appearance.

## 2026-06-21 - Shadow Distance Split Stabilization

### Changed

- Kept `shadowMapResolution = 2048`, `shadowDistance = 96.0`, and `shadowIntervalSize = 8.0` as the stable default shadow-map setup.
- Added near/mid/far distance split fade inside `getShadowVisibility()` so close shadows stay clearer while far shadows fade into the sky/fog tint instead of shimmering sharply.
- Added `getShadowStableFilterRadius()` to clamp PCSS penumbra growth by distance and reduce mid/far shadow deformation while moving.
- Kept fixed PCF/PCSS sample rotation (`angle = 0.0`) to avoid filter crawling.
- Tightened contact shadow range, radius, thickness, and final strength while keeping `ENABLE_CONTACT_SHADOWS = 0` as the stable default.

### Test Notes

- Compare `shadowIntervalSize = 4.0`, `8.0`, and `16.0` only after checking the default movement stability.
- If distant reprojection is still visible, test `shadowDistance = 64.0`; if far terrain shadow loss is too obvious, keep `96.0`.
## 2026-06-21 - Near Mid Far Shadow Stabilization

### Changed

- single shadow map 한계 안에서 cascade처럼 보이도록 near/mid/far 거리별 shadow strength fade를 실제 `getShadowVisibility()` 경로에 적용.
- far 구간에서는 선명한 그림자를 유지하려 하지 않고 shadow strength를 부드럽게 낮춰 플레이어 이동 중 재투영 티가 덜 나도록 조정.
- PCSS filter radius를 거리 구간별로 안정화해 mid/far 구간의 penumbra 변화가 과하게 출렁이지 않도록 변경.
- contact shadow는 기본 off 상태를 유지하되, 켰을 때도 짧은 거리에서만 은은하게 작동하도록 거리, 두께, 반경, 최종 강도를 낮춤.

### Notes

- 기본 안정화 값은 `shadowIntervalSize = 8.0`, `shadowDistance = 96.0` 유지.
- 추가 안정성이 필요하면 다음 실험은 `shadowDistance = 64.0` 또는 `shadowIntervalSize = 16.0`.

## 2026-06-20 - Hand Pass Shadow Isolation

### Fixed

- Prevented held hands/items from receiving terrain shadow map visibility, contact shadow, normal form lighting, and global wet highlights.
- Added a final-pass terrain receiver mask based on `colortex2` material channels, so only terrain/water/lava-marked pixels enter terrain shadow and wet-surface paths.
- Stopped `applyTerrainFormLighting()` from treating any valid normal buffer pixel as terrain by itself.

### Notes

- Hand/entity passes still write normals for compatibility, but final terrain shading now requires material masks as well.
- This is likely related to player-movement shadow instability because held hands/items move with the camera while terrain shadow code expected world-stable receivers.

## 2026-06-20 - Terrain-Only PCSS Expression Restore

### Changed

- Reduced `shadowIntervalSize` from `16.0` to `8.0` for a better stability/detail balance.
- Kept `ENABLE_CONTACT_SHADOWS = 0` and hand/entity receiver isolation intact.
- Restored terrain-only PCSS expression by letting blocker-depth penumbra drive the filter radius again.
- Tuned PCSS values to `PCSS_LIGHT_SIZE = 16.0`, `PCSS_MIN_RADIUS = 0.65`, and `PCSS_MAX_RADIUS = 2.8`.
- Increased `SHADOW_DARKNESS` to `0.74` and cooled/darkened shadow tint to reduce the vanilla-like flat look.

### Notes

- If walking remains stable, `shadowIntervalSize = 4.0` is the next detail-oriented test value.

## 2026-06-20 - Player-Movement Shadow Stability

### Changed

- Increased `shadowIntervalSize` from `1.0` to `16.0` so the shadow projection no longer follows every small player movement.
- Changed `ENABLE_CONTACT_SHADOWS` default from `1` to `0` because screen-space contact shadows move with the camera by design.
- Removed view-distance-dependent shadow bias, PCF radius, PCSS search radius, and shadow strength fade from the main shadow map path.
- Added stable PCF/PCSS radius constants so a surface keeps the same shadow filtering while the player moves.
- Changed partial shadow caster dithering from `gl_FragCoord` to texture-coordinate cells to reduce reprojection crawling.
- Fixed contact shadow sampling radius so it no longer scales while the player walks toward or away from geometry.

### Notes

- Shadow map edge fade and weather/time fade still apply, but ordinary player movement should no longer continuously change shadow softness or strength.
- `shadowIntervalSize = 16.0` was used as a maximum-stability diagnostic value; current balanced default is `8.0`.

## 2026-06-20 - Wet Specular BRDF Material Refinement

### Changed

- Reworked wet specular highlights from a simple Phong-style lobe to a GGX-style microfacet BRDF.
- `applyWetSpecularBRDF()` now uses the `colortex3` world normal buffer when available, falling back to the older floor/wall normal estimate only when needed.
- Wet material response values are now interpreted as roughness/F0 hints, so stone/glass-like surfaces stay glossier while foliage/crop-like surfaces remain broad and muted.
- Wall and floor wet masks now influence roughness separately, reducing harsh vertical streak highlights.

### Notes

- Material-specific behavior is inferred from the existing wet response masks because the current buffer layout does not store a dedicated material ID in the final pass.

## 2026-06-20 - Water Reflection and Absorption Refinement

### Changed

- Increased water SSR ray steps and binary refinement steps for more stable hit placement.
- Tightened SSR thickness and added hit confidence based on edge fade, ray distance, and refined depth delta.
- Reworked SSR roughness blur from a 5-tap cross into a softer 9-tap kernel.
- Added a low-cost planar-style fallback reflection for horizontal water using mirrored screen sampling.
- Added view-distance-based water absorption and stronger flow/foam separation for vertical water.

### Notes

- This is still not a true planar reflection pass. A real planar pass would need an additional reflected scene render target or loader-specific reflection buffer.

## 2026-06-20 - Material-Aware Shadow Refinement

### Changed

- Refined shadow caster rules for foliage, crop, and glass material groups instead of treating every non-water/non-lava caster as fully opaque.
- Added stable dithered partial shadow casting for translucent or thin materials in the shadow pass.
- Added distance-split-style far shadow softening to reduce harsh distant shadow bands without adding a full cascade pipeline.
- Made final shadow tint and strength react to wet floor/wall, water, and lava masks.
- Improved normal-based directional lighting with a small BRDF lobe on wet/material-marked terrain.

### Notes

- This is still a single shadow map path, not a true cascaded shadow map implementation.
- Colored/translucent shadows are approximated through partial caster opacity and material-aware final tint because the current buffer layout only stores a single depth shadow map.

## 2026-06-20 - Shadow Movement Stabilization

### Changed

- 플레이어 이동 중 그림자가 계속 변형되어 보이는 현상을 줄이기 위해 `shadowIntervalSize`를 `0.25`에서 안정 우선값 `1.0`으로 되돌림.
- PCF/PCSS 샘플 커널의 per-pixel hash 회전을 제거하고 고정 Poisson kernel을 사용하도록 변경.
- shadow map 재투영 변화와 필터 패턴 crawling이 동시에 보이는 상황을 줄이는 방향으로 조정.

### Notes

- `0.25`는 갱신 단위는 촘촘하지만 카메라 이동 중 shadow shimmer와 변형이 커질 수 있음.
- 현재 안정 우선값은 `1.0`이며, 더 타이트한 움직임이 필요하면 `0.5`를 다시 실험하는 것을 권장.

## 2026-06-20 - Tighter Experimental Shadow Interval

### Changed

- `shadowIntervalSize`를 `0.5`에서 `0.25`로 낮춰 shadow map 갱신 단위를 더 촘촘하게 조정.
- 그림자가 시간 변화나 카메라 이동을 더 빠르게 따라오도록 실험값을 적용.

### Notes

- `0.25`는 더 타이트한 값이지만 환경에 따라 shimmer가 늘 수 있음.
- 그림자가 미세하게 떨리면 `0.5` 또는 안정 우선값 `1.0`으로 되돌리는 것을 권장.

## 2026-06-20 - Documentation Cleanup and Current State Sync

### Changed

- `CHANGELOG.md` 구조를 최근 변경 이력, 현재 구현 상태, 목표, 미구현 항목으로 다시 정리.
- 파일에는 없거나 흩어져 있던 최신 구현 내용을 현재 코드 기준으로 반영.
- 오래된 `MOOD` 옵션 화면 설명을 제거하고, Iris/NeOculus 옵션 화면에 직접 노출되는 현재 구조로 정리.
- 깨진 한글 텍스트가 다시 섞이지 않도록 문서를 UTF-8 한국어 중심으로 재작성.

### Synced From Code

- `shadowIntervalSize = 1.0` 안정 우선 그림자 갱신 간격 설정.
- `ENABLE_CONTACT_SHADOWS`, `ENABLE_NORMAL_FORM_LIGHTING`, `ENABLE_WET_GROUND_LAYER`, `ENABLE_WET_SCREEN_REFLECTIONS`, `ENABLE_WET_SPECULAR`, `ENABLE_WATER_SURFACE` 안정성/디버그 토글.
- `colortex3Format = RGBA16F` normal buffer와 `DRAWBUFFERS:0123` 전달 구조.
- `gbuffers_hand`, `gbuffers_entities`, `gbuffers_hand_water` 전용 패스.
- `gbuffers_skybasic`, `gbuffers_skytextured`, `gbuffers_clouds`, `gbuffers_water` 전용 패스.
- `block.properties`의 lava, water, stone, soil, wood, foliage, glass, crop material 그룹.

## 2026-06-20 - Tighter Shadow Update Interval

### Changed

- `shaders.properties`에 `shadowIntervalSize`를 추가하고, 이후 실험값을 `0.25`로 조정.
- 카메라 이동이나 시간 변화 중 그림자가 큰 단위로 따라오는 느낌을 줄이도록 shadow map 위치 갱신 단위를 더 촘촘하게 설정.

### Notes

- 값이 작을수록 그림자 갱신은 더 타이트해지지만, 환경에 따라 미세한 shadow shimmer가 늘어날 수 있음.
- 떨림이 보이면 `shadowIntervalSize = 0.5` 또는 안정 우선값 `1.0`으로 완화하는 것을 권장.

## 2026-06-20 - NeOculus Stability Debug Options

### Changed

- NeOculus에서 `Unable to resolve shader pack option menu element "MOOD"` 경고가 발생하던 `screen = MOOD` / `screen.MOOD` 구조를 제거.
- 옵션을 최상위 `screen`에 직접 노출하도록 `shaders.properties`를 정리.
- 최근 추가한 고비용 후처리 경로를 기능별 `#if` 토글로 분리해 크래시 원인 분리가 가능하도록 변경.
- CurseForge용 `minecraftshader.zip` 패키징 구조를 검증.

### Added

- `ENABLE_CONTACT_SHADOWS`: 가까운 거리 screen-space contact shadow on/off.
- `ENABLE_NORMAL_FORM_LIGHTING`: normal buffer 기반 지형 입체 조명 on/off.
- `ENABLE_WET_GROUND_LAYER`: 비 오는 날 젖은 바닥 darkening/sheen layer on/off.
- `ENABLE_WET_SCREEN_REFLECTIONS`: 젖은 바닥 screen-space reflection on/off.
- `ENABLE_WET_SPECULAR`: 젖은 표면 BRDF 하이라이트 on/off.
- `ENABLE_WATER_SURFACE`: 물 Fresnel/flow surface shading on/off.

### Notes

- 다른 셰이더에서는 크래시가 없고 이 셰이더에서만 발생한다면 `ENABLE_WET_SCREEN_REFLECTIONS`, `ENABLE_WATER_SURFACE`, `ENABLE_CONTACT_SHADOWS`, `ENABLE_NORMAL_FORM_LIGHTING` 순서로 기능을 끄며 확인하는 것을 권장.

## 2026-06-20 - Wet Ground Material Layer

### Changed

- `applyWetGroundLayer()`를 추가해 비 오는 날 바닥이 단순히 밝게 반사되는 대신 젖은 표면처럼 어둡고 차분하게 보이도록 조정.
- rain, puddle, floor mask를 기준으로 바닥을 먼저 어둡게 누르고, 차가운 물막 tint와 낮은 각도 sheen을 얹도록 변경.
- puddle reflection보다 앞단에서 젖은 재질감을 먼저 형성하도록 순서를 조정.
- grass, dirt, soil 계열은 강한 거울 반사보다 wet darkening과 은은한 광택 위주로 보정.

## 2026-06-20 - Rain Puddle Ground Reflections

### Changed

- `getRainPuddleMask()`와 `sampleRainPuddleReflection()`을 추가.
- 비 오는 날 평평한 바닥에 웅덩이 기반 screen-space reflection을 적용.
- `WET_TERRAIN_REFLECTION_STRENGTH = 0.34`로 상향.
- `RAIN_REFLECTION_INTENSITY = 0.6`으로 조정.
- 수직 벽면에는 반사가 과하게 적용되지 않도록 floor mask와 screen edge fade를 강화.

## 2026-06-20 - Water Reflection Mode Step 1

### Changed

- `WATER_REFLECTION_MODE` 옵션을 추가.
- 기본값 `0`에서는 화면 샘플 기반 SSR 대신 안정적인 sky/Fresnel/roughness/flow 기반 물 표현을 사용.
- `WATER_REFLECTION_MODE = 1`일 때만 약한 water SSR을 추가 적용.
- `applyWaterSurface()`에서 수평 물은 Fresnel 반사를 유지하고, 폭포/수직 물기둥은 absorption + flow shading 위주로 분리.
- `applyWaterSSR()`는 fallback 경로로 남기되, 가까운 수직 물에서는 반사량을 크게 감쇠.

### Notes

- 진짜 planar reflection은 아직 구현되지 않음.
- 추후 별도 reflected scene texture 또는 전용 reflection pass 구조가 필요함.

## 2026-06-20 - Held Torch Color Match

### Changed

- 손에 든 횃불 조명이 뿌옇고 하얗게 뜨는 현상을 줄임.
- `TORCH_LIGHT_COLOR`, `TORCH_EDGE_COLOR`를 설치된 횃불에 가까운 따뜻한 주황 계열로 조정.
- held torch의 ambient, brightness, indoor boost를 낮춰 과노출과 흰색 haze를 완화.
- `heldBlockLightValue`, `heldBlockLightValue2` 기반 손 조명 강도와 거리 감쇠를 유지.

## 2026-06-19 - Waterfall Reflection Stabilization

### Changed

- 가까운 수직 물/폭포에서 하얀 반점처럼 보이던 reflection artifact를 줄이기 위해 `waterfallMask`를 추가.
- `worldNormal`과 view distance를 사용해 수직/근거리 물의 SSR, sky fallback, specular를 감쇠.
- 폭포는 반사보다 깊은 물색, 흡수감, 흐름 표현 중심으로 조정.
- `gbuffers_water.fsh`의 wave normal 강도와 specular/sky reflection 출력을 낮춰 가까운 물기둥의 반짝임을 완화.

## 2026-06-19 - Held Item Opaque Pass

### Added

- `gbuffers_hand.vsh/fsh`.
- `gbuffers_hand_water.vsh/fsh`.
- `gbuffers_entities.vsh/fsh`.

### Fixed

- 손에 든 아이템이 일부 투과되어 보이던 문제를 줄이기 위해 hand/entity pass에서 `colortex0.a = 1.0`을 출력.
- hand/entity pass에서 `colortex2` material mask를 `vec4(0.0)`으로 초기화해 terrain/water mask가 섞이지 않도록 정리.
- hand/entity pass에서도 normal buffer를 기록해 final 단계의 normal 기반 shading이 안정적으로 동작하도록 정리.

## 2026-06-19 - Normal Shading and Shadow-Aware Fog

### Changed

- `colortex3` normal buffer 기반 `NdotL` diffuse와 form shadow를 추가.
- `gbuffers_terrain`, `gbuffers_water`, `gbuffers_hand`, `gbuffers_entities`, `gbuffers_hand_water`가 normal buffer를 기록하도록 정리.
- `composite.fsh`가 `DRAWBUFFERS:0123`으로 scene color, bloom buffer, material mask, normal buffer를 final pass까지 전달.
- shadow map으로 가려진 영역에서 mood lighting lift와 highlight가 과하게 들어가지 않도록 `shadowVisibility`를 전달.
- fog가 그림자 영역을 다시 밝게 덮는 현상을 줄이기 위해 shadow-aware fog 보정을 추가.

## 2026-06-18 - Shadow Contrast and PCSS Work

### Changed

- `SHADOW_MODE = 1` 기본 경로에 PCSS를 활성화.
- 8-sample blocker search와 8-sample filter를 사용하도록 `PCSS_BLOCKER_SAMPLES`, `PCSS_FILTER_SAMPLES`를 명시.
- `PCSS_LIGHT_SIZE = 20.0`, `PCSS_MIN_RADIUS = 0.85`, `PCSS_MAX_RADIUS = 2.0`으로 radius clamp를 강하게 조정.
- `SHADOW_DARKNESS = 0.66`으로 shadow tint 대비를 강화.
- `CONTACT_SHADOW_INTENSITY = 0.65`로 가까운 거리 접지감을 강화.
- `getSkyShadowTint()`를 통해 `getSkyColor()` 기반 shadow tint를 적용.

### Notes

- 현재 그림자는 바닐라보다 대비가 강해졌지만, 유명 셰이더 수준의 cascade shadow, colored shadow, material-specific caster rule은 아직 미구현.

## 2026-06-17 - Sky, Cloud, Fog, and Horizon Unification

### Added

- `lib/sky.glsl`.
- `gbuffers_skybasic.vsh/fsh`.
- `gbuffers_skytextured.vsh/fsh`.
- `gbuffers_clouds.vsh/fsh`.

### Changed

- 하늘, 구름, 안개, 지형 fog, 물 반사 색을 `lib/sky.glsl`의 공통 sky color 체계로 통합.
- `getSkyColor()`, `getSkyUnifiedColor()`, `getSkyCloudColor()`, `getSkyWaterReflectionColor()`, `getSkyWaterTint()`, `getSkyFogColor()`를 중심으로 색 계산을 정리.
- `final.fsh`에서 `depth >= 1.0` 하늘 픽셀에 적용하던 추가 fog 덧칠을 제거 또는 최소화.
- 지형 fog 색을 `fogColor` uniform 대신 `getSkyFogColor(worldDir, ...)` 기반으로 변경.
- 낮에서 밤으로 바뀔 때 수평선과 하늘이 두 층으로 갈라져 보이는 현상을 완화.
- 구름 RGB를 공통 sky color 체계로 보정하면서 바닐라 구름 alpha는 유지.

## 2026-06-16 - Water Pass and Material Mask Expansion

### Added

- `gbuffers_water.vsh/fsh` 물 전용 pass.
- `colortex2.a` water mask.
- 물 전용 Fresnel, ripple, sky reflection tint, flow shading.

### Changed

- `colortex2` material mask 구조를 `R = wet floor`, `G = wall`, `B = lava`, `A = water`로 확장.
- lava mask를 `colortex0.a`에서 `colortex2.b`로 이동.
- `colortex0Format = RGBA8`, `colortex1Format = RGBA16F`, `colortex2Format = RGBA8`, `colortex3Format = RGBA16F` 설정.

## 2026-06-15 - Shadow Stabilization and Caster Rules

### Changed

- shadow map sampling에 slope bias, distance bias, edge fade, weather/night fade를 추가.
- shadow pass에서 alpha cutout을 처리.
- water, lava, glass 계열은 solid shadow caster에서 제외.
- `shadowMapResolution = 2048`, `shadowDistance = 96.0` 설정.

### Fixed

- 일부 오브젝트가 잘못 투명하거나 누락되어 보이는 문제를 줄이기 위해 material mask와 alpha 출력 구조를 정리.

## 2026-06-14 - Initial Shader Structure

### Added

- `README.md`.
- `LICENSE`.
- `shaders/final.vsh`, `shaders/final.fsh`.
- `shaders/composite.vsh`, `shaders/composite.fsh`.
- `shaders/gbuffers_terrain.vsh`, `shaders/gbuffers_terrain.fsh`.
- `shaders/shadow.vsh`, `shaders/shadow.fsh`.
- `shaders/block.properties`.
- `shaders/lib/color.glsl`.
- `shaders/lib/fog.glsl`.
- `shaders/lib/lighting.glsl`.
- `shaders/lib/wet.glsl`.
- `shaders/lib/ssr.glsl`.
- `shaders/lib/shadows.glsl`.

### Implemented

- 색 보정: exposure, contrast, saturation, warm tint, ACES tonemapping, pastel tone, dithering.
- bloom 추출 및 blur.
- 렌더 거리 기반 fog.
- sun, moon, torch, lava, rain palette 기반 mood lighting.
- held torch 조명 거리 감쇠와 flicker.
- lava mask 기반 발광 보정.
- wet floor/wall mask 기반 비 오는 날 wet highlight.
- water mask 기반 초기 SSR 경로.
- shadow map 기반 초기 PCF 그림자.

## Current Goals / 목표사항

- Iris/NeOculus 기반 Minecraft 분위기형 shaderpack 제작.
- 하늘, 구름, 안개, 지형 fog, 물 반사를 `lib/sky.glsl`의 공통 sky color 체계로 통합해 낮/밤 전환과 수평선 층 분리를 완화.
- 파스텔 톤을 유지하면서 색감, 채도, 노출, 대비를 게임 플레이에 맞게 조정.
- 들고 있는 횃불과 설치된 횃불의 색과 체감 밝기를 비슷하게 맞춤.
- 비 오는 날 젖은 바닥, 벽면 물 흐름, 웅덩이 반사를 강화.
- shadow map, Poisson PCF, PCSS, contact shadow, normal buffer 기반 form lighting을 단계적으로 강화.
- material mask 구조를 유지해 lava, water, wet floor, wall, foliage, glass, crop 등 재질별 효과를 분리.
- NeOculus/Embeddium 환경에서 shaderpack zip 구조와 GLSL 호환성을 계속 검증.

## Current State Reference

현재 옵션 목록, 버퍼 형식·채널, 그림자·물의 구현 범위와 근사·제한, 검증 상태는 [README.md](README.md)의 Shader Options, Buffer Layout, Shadow Status, Water Status, 검증 상태 절을 기준으로 합니다. 같은 상태를 이 파일에 중복해 관리하지 않으며, 위 날짜별 항목은 당시의 기록입니다.

## Current Material IDs

- `block.11000`: lava.
- `block.11001`: water.
- `block.11100`: stone-like wet response group.
- `block.11101`: soil/grass/sand/gravel wet response group.
- `block.11102`: wood wet response group.
- `block.11103`: moss/vine/lichen foliage wet response group (non-waving).
- `block.11104`: glass wet response group.
- `block.11105`: crops/small plants low-reflection group; sways from a still base.
- `block.11106`: waving leaves (foliage wet response).
- `block.11107`: waving grass, flowers and lower halves of tall plants (foliage wet response).
- `block.11108`: waving upper halves of tall plants (foliage wet response).

## Planned / Not Implemented

진행 상태와 우선순위는 [CHECKLIST.kr.md](CHECKLIST.kr.md)의 "README 검토에 따른 우선 수정·구현 목록"에서 관리합니다. 아래는 그 목록에 아직 항목이 없는 장기 계획입니다.

- 낮, 밤, 동굴, 비, 네더, 엔드 환경별 색감 프리셋 정리.
- 인게임 스크린샷 기반 wet specular roughness/F0 추가 튜닝.
- 옵션 설명과 추천 프리셋 정리.
