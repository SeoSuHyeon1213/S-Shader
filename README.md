# S-Shader

> NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.

S-Shader는 비공식 프로젝트이며, Mojang 또는 Microsoft의 승인이나 제휴를 받은 제품이 아닙니다.

S-Shader는 Iris/NeOculus 환경을 목표로 제작 중인 Minecraft 셰이더팩입니다. 사실적인 렌더링을 완전히 재현하기보다는, 부드러운 색감, 안개, 하늘 색 통합, 젖은 표면, 횃불 조명, 그림자 대비를 통해 분위기 있는 화면을 만드는 것을 목표로 합니다.

현재 개발은 Codex와 Claude Code를 함께 사용해 빠르게 실험하고 있으며, 실제 게임 플레이 스크린샷을 기준으로 색감과 효과를 계속 조정하고 있습니다.

## 주요 기능

- 노출, 대비, 채도, 따뜻한 색 보정, ACES 톤 매핑, 파스텔 톤 기반 색 보정
- 별도 bloom buffer를 사용한 bloom 추출 및 blur
- `lib/sky.glsl` 기반의 하늘, 구름, 안개, 지형 fog, 물 반사 색 체계 통합
- 낮/밤 전환과 수평선 부근의 색 층 분리 완화
- 비 오는 날 젖은 바닥, 벽면 물 흐름, 웅덩이 반사, wet specular 표현
- 물 전용 `gbuffers_water`와 물 mask 기반 Fresnel/flow/rough reflection 표현
- 횃불을 들었을 때 설치된 횃불과 비슷한 따뜻한 주황빛 조명
- lava mask 기반 자체 발광과 용암 전용 넓은 bloom
- shadow map 기반 PCF/PCSS 그림자, shadow tint, contact shadow
- `colortex3` normal buffer 기반 지형 diffuse/form shadow 보정
- hand/entity 전용 pass를 통한 들고 있는 아이템 반투명 문제 완화

## 주요 색상 팔레트

- Sun: `#F1FEC6`
- Moon: `#BFD8FF`
- Torch: `#F5853F`
- Lava: `#FF3A20`
- Rain accent: `#3423A6`

## Shader Options

옵션은 Iris/NeOculus 셰이더 옵션 화면에 직접 노출됩니다.

- `SHADOW_MODE`: `0` = 고정 반경 Poisson PCF (기본값), `1` = 실험적 PCSS
- `WATER_REFLECTION_MODE`: `0` = 안정적인 sky/Fresnel 물 반사, `1` = 약한 SSR 추가
- `ENABLE_CONTACT_SHADOWS`: 가까운 거리 screen-space contact shadow on/off
- `ENABLE_NORMAL_FORM_LIGHTING`: normal buffer 기반 지형 입체 조명 on/off
- `ENABLE_WET_GROUND_LAYER`: 비 오는 날 젖은 바닥 darkening/sheen layer on/off
- `ENABLE_WET_SCREEN_REFLECTIONS`: 젖은 바닥 screen-space reflection on/off
- `ENABLE_WET_SPECULAR`: normal buffer와 material response 기반 젖은 표면 BRDF 하이라이트 on/off
- `ENABLE_WATER_SURFACE`: 물 Fresnel/flow surface shading on/off
- `EXPOSURE`
- `CONTRAST`
- `SATURATION`
- `LIGHTING_STRENGTH`
- `DAY_LIGHT_STRENGTH`
- `NIGHT_LIGHT_STRENGTH`
- `SUNSET_GLOW_STRENGTH`
- `TORCH_LIGHT_INTENSITY`
- `LAVA_EMISSION_INTENSITY`: 용암 자체 발광과 전용 bloom 강도, 기본값 `1.0`
- `CONTACT_SHADOW_INTENSITY`
- `RAIN_REFLECTION_INTENSITY`
- `BLOOM_INTENSITY`
- `BLOOM_THRESHOLD`
- `FOG_DENSITY`
- `FOG_START`
- `VIGNETTE_OUTER`

## Buffer Layout

- `colortex0`: scene color
- `colortex1`: bloom buffer
- `colortex2.r`: wet floor mask
- `colortex2.g`: wall mask
- `colortex2.b`: lava mask
- `colortex2.a`: water mask
- `colortex3.rgb`: encoded world normal
- `colortex3.a`: valid normal mask

## Sky / Fog Layout

- `gbuffers_skybasic`: 기본 하늘 색을 `lib/sky.glsl`의 공통 sky color로 출력
- `gbuffers_clouds`: 바닐라 구름 texture alpha를 유지하면서 RGB를 sky color 체계로 보정
- `gbuffers_skytextured`: 해, 달, 별 texture를 sky color 기반으로 tint
- `final.fsh`: 지형 fog를 `fogColor` uniform 대신 `getSkyFogColor()` 기반으로 적용
- `depth >= 1.0` 하늘 영역에는 별도 fog 덧칠을 최소화해 하늘 층 분리를 줄임

## Shadow Status

현재 그림자 구현은 실험 단계입니다.

구현된 부분:

- `shadowtex0`, `shadowModelView`, `shadowProjection` 기반 shadow map sampling
- `SHADOW_MODE = 0`: 8-sample Poisson PCF
- `SHADOW_MODE = 1`: 8-sample blocker search + 8-sample filter PCSS
- `shadowMapResolution = 2048`
- `shadowDistance = 96.0`
- `shadowIntervalSize = 8.0`
- 위 세 설정은 `lib/shadow_settings.glsl`의 GLSL 상수로 선언하고 shadow/final 패스에서 공유
- nearest 깊이 샘플을 비교한 뒤 결과를 bilinear 보간해 깊이 경계의 가짜 표면과 텍셀 단위 튐 완화
- 화면 미분 대신 world normal과 실제 광원 방향·투영 크기로 제한된 slope bias 계산
- 낮은 wet response 재질도 그림자를 받도록 receiver 존재 여부와 wet response 강도 분리
- shadow tint와 rain/weather fade
- screen-space contact shadow
- normal buffer 기반 terrain form lighting
- shadow pass의 기본 alpha cutout 및 water/lava caster 제외
- foliage/crop/glass material의 dithered partial caster rule
- material mask 기반 wet/water/lava shadow tint 및 강도 보정
- 플레이어 이동에 따라 변하지 않는 안정 우선 PCF/PCSS radius와 shadow strength
- `ENABLE_CONTACT_SHADOWS = 0` 기본값으로 screen-space 그림자 이동감 최소화
- texture-coordinate 기반 partial caster dither로 shadow reprojection crawling 완화
- terrain-only PCSS penumbra 기반 soft shadow 표현력 복구
- 플레이어 거리별 필터 반경·농도 보정을 제거하고 광원 공간의 blocker/receiver 간격으로 PCSS 반경 계산
- 실제 shadowModelView 광원 방향으로 표면 음영과 sky tint 계산, 시선 각도에 따른 form shadow 감쇠 제거
- 그림자 강도 0.94와 tint 밝기 배율 0.62로 그림자 명도 감소, 어두운 재질 보호 유지

단일 shadow map의 재투영·해상도 한계와 맵 가장자리 fade는 남아 있습니다. 이동 중 모든 경계 변화가 제거된 것은 아니며, 변경의 시각 품질은 게임에서 확인해야 합니다. 기존 옵션 파일에 `SHADOW_MODE = 1`이 저장되어 있다면 안정성 비교 시 `0`으로 바꿉니다.

깊이 비교 보간은 PCF 필터당 최대 36회, 비 노출 판정당 최대 24회의 깊이 읽기를 사용합니다. 비 노출 판정은 비가 올 때만 실행합니다. PCSS 선택 시 blocker 탐색 8회가 추가됩니다. 실제 GPU 비용과 FPS는 게임에서 확인해야 합니다.

남은 작업:

- torch 등 emissive block에 대한 더 정교한 caster rule
- 실제 cascade shadow map 기반 장거리 안정화
- 별도 colored shadow buffer 기반 translucent/colored shadow
- 재질별 shadow tint 세분화
- 더 정확한 directional BRDF 조명 반응

## Water Status

구현된 부분:

- `colortex2.a` water mask 기반 물 표면 효과
- sky/Fresnel/roughness/flow 기반 안정 물 반사
- 수평 물 전용 low-cost planar 스타일 mirrored screen fallback
- `WATER_REFLECTION_MODE = 1`에서 water SSR 추가
- 20-step SSR ray march와 6-step binary refinement
- 9-tap roughness blur 기반 SSR reflection filtering
- 물 표면과 depthtex1 불투명 바닥의 world-space 높이 차이에 기반한 수심별 alpha/반사/색 흡수
- 폭포/수직 물기둥의 flow/absorption 중심 표현

남은 작업:

- 별도 reflected scene texture 기반 진짜 planar reflection
- loader별 reflection/depth buffer 지원 여부 확인
- 해안 절벽·바닥 미노출 상황의 수심 근사 개선과 underwater absorption
- SSR edge artifact 및 disocclusion 처리 고도화

### Shallow / Deep Water

수평 수면을 물 밖에서 볼 때 얕은 물은 바닥이 잘 보이도록, 깊은 물은 물 색과 반사가 강하게 보이도록 설정합니다. 기본값은 다음과 같습니다.

| 추정 수심 | 기본 alpha (불투명도) | 반사 강도 입력값 |
|---|---|---|
| 2블록 이하 | 0.35 | 0.25 |
| 2~12블록 | smoothstep 보간 | smoothstep 보간 |
| 12블록 이상 | 0.70 | 0.60 |

값은 `shaders/lib/water_depth.glsl`에 모았습니다. `WATER_REFLECTION_INTENSITY = 0.6`일 때 표의 반사 입력값을 사용하며, 기존 옵션을 바꾸면 얕은 물과 깊은 물의 강도가 함께 조절됩니다. 최종 반사율은 Fresnel과 수면 방향 등의 감쇠를 거칩니다. alpha에는 시선 각도에 따라 최대 0.06이 추가됩니다.

수심은 같은 화면 픽셀의 물 표면과 불투명 바닥을 복원한 뒤 수직 높이 차이로 추정합니다. 카메라와 물의 거리를 수심으로 사용하지 않습니다. 강/바다 바이옴을 판별하는 기능은 아니며, 깊은 강도 깊은 물로 표현합니다. 바닥이 렌더 거리 밖이거나 미노출이면 깊은 물로 처리합니다. 시선이 해안 절벽이나 물 밖의 지형을 가리키는 경우 정확한 수직 수심과 다를 수 있습니다.

폭포와 물속 시점은 수평 수면용 수심 보간을 생략하고 alpha 0.45를 사용합니다. 물의 추가 깊이 읽기는 수심 계산이 필요한 픽셀에서 gbuffers_water와 final에 각각 1회입니다. 데이터 버퍼의 blending을 끄므로 물 alpha가 작아져도 water mask와 normal이 바닥 데이터와 섞이지 않습니다. 게임 컴파일·시각 비교·FPS 검증은 아직 필요합니다.

## Lava Emission

용암은 lightmap 감쇠를 받지 않으며, 텍스처의 밝은 부분을 중심으로 자체 발광을 강화합니다. 최종 발광은 날씨·그림자 보정 이후, 안개·톤 매핑 이전에 적용됩니다.
용암 마스크만 추출하는 추가 9-tap bloom으로 주황빛이 주변 화면에 퍼집니다. 실제 주변 블록에 대한 광원 추적이나 간접 조명은 구현하지 않습니다.

- `LAVA_EMISSION_INTENSITY`는 `0.0`부터 `2.0`까지 조절합니다. `0.0`은 추가 자체 발광과 전용 bloom을 끄며, 용암의 기본 자체 조명과 일반 bloom은 유지됩니다.
- `BLOOM_INTENSITY`는 용암을 포함한 전체 bloom의 최종 합성 강도입니다. `0.0`이면 빛 번짐만 꺼지고 용암 자체 발광은 유지됩니다.
- 용암 전용 halo는 화면 픽셀 기준이며, 활성화 시 composite에 최대 18회의 texture sampling이 추가됩니다. 해상도·장면에 따른 시각 품질과 성능은 게임에서 확인해야 합니다.

## Crash / Stability Debug

NeOculus/Embeddium 환경에서 특정 후처리 조합이 GPU/드라이버 쪽 불안정을 만들 수 있어, 최근 기능은 옵션으로 분리했습니다.

크래시가 의심될 때 권장 테스트 순서:

1. `ENABLE_WET_SCREEN_REFLECTIONS = 0`
2. `ENABLE_WATER_SURFACE = 0`
3. `ENABLE_CONTACT_SHADOWS = 0`
4. `ENABLE_NORMAL_FORM_LIGHTING = 0`

## Status

아직 개발 중인 셰이더팩입니다. 핵심 후처리, 하늘/fog 통합, 젖은 표면, 물 표현, PCSS 그림자, contact shadow, normal buffer 기반 지형 조명은 구현되어 있지만 실제 게임 내 낮, 밤, 동굴, 비, 네더, 엔드 환경에서 추가 튜닝이 필요합니다.

## License

S-Shader의 자체 제작 코드에는 MIT License가 적용됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요. 외부 코드나 에셋을 포함하는 경우 해당 저작권자의 라이선스와 고지도 별도로 준수해야 합니다.

## Minecraft 정책 안내

S-Shader의 코드 라이선스와 Minecraft의 이용 정책은 별개입니다. Minecraft와 관련된 이용·배포에는 [Minecraft EULA](https://www.minecraft.net/en-us/eula)와 [Minecraft Usage Guidelines](https://www.minecraft.net/en-us/usage-guidelines)를 확인하고 준수해야 합니다.

- 셰이더팩만 배포하며, Minecraft 게임 파일이나 셰이더팩을 포함한 수정된 게임 클라이언트·서버를 함께 재배포하지 않습니다.
- Minecraft의 이름·브랜드·에셋에 관한 권리는 Mojang 및 Microsoft에 있습니다. MIT License는 이들에 대한 사용 권한을 부여하지 않습니다.
- 배포·소개 페이지에서도 비공식 프로젝트임을 표시하고, 공식 제품이나 승인된 프로젝트로 오인하게 하는 이름·로고·표현을 사용하지 않습니다.
- MIT License의 상업적 이용 허용은 Minecraft 관련 판매·수익화를 승인한다는 뜻이 아닙니다. 판매나 수익화를 검토할 때는 적용되는 공식 정책과 허용 범위를 별도로 확인해야 합니다.

이 안내는 MIT License에 추가 제한을 붙이거나 공식 정책을 대체하는 문서가 아닙니다. 정책은 변경될 수 있으므로 이용·배포 시 위 공식 링크의 최신 내용을 확인해야 하며, 안내 문구만으로 정책 준수가 보장되는 것은 아닙니다.
