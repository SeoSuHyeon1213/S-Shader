# Changelog

All notable changes to this shader pack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## Goals / 목표사항

- Iris 기반 마인크래프트 분위기형 쉐이더팩 제작
- 색보정, 비네트, 블룸, 안개를 중심으로 부드러운 파스텔 톤 구현
- 태양, 달, 횃불, 용암, 비 색상 팔레트를 중심으로 장면 분위기 통일
- 하늘, 구름, 지형 fog를 같은 sky color 체계로 묶어 수평선 층 분리 완화
- 비 오는 날 wet floor/wall mask 기반 젖은 표면 하이라이트 구현
- 용암과 물은 block/material mask로 분리해 전용 발광/하이라이트 적용
- 인게임 Iris 컴파일 검증 및 낮, 밤, 동굴, 비, 네더, 엔드 환경별 튜닝

## In-Game Tuning Checklist

- 낮 평원에서 기본 노출, 채도, 대비 확인
- 일몰에서 수평선 glow와 구름 tint 확인
- 밤 평원에서 달빛 가독성 확인
- 동굴에서 횃불 조명 거리와 색 번짐 확인
- 비 오는 날 wet reflection과 fog 강도 확인
- 물가에서 water SSR, sky reflection, rough reflection 확인
- 네더에서 용암 발광 과포화 확인
- 엔드에서 sky/fog 색상 왜곡 확인

## [Unreleased]

### Added

- `README.md`
  - 프로젝트 설명, 기능 목록, 색상 팔레트, 옵션 목록 추가
  - 영어 원문 아래에 한국어 번역 추가
- `LICENSE`
  - MIT License 초안 추가
- `shaders/final.vsh`, `shaders/final.fsh`
  - 최종 출력 패스 추가
  - 블룸 합성, 그림자, 분위기 조명, wet highlight, 물 SSR, 안개, 색보정, 비네트, dithering 적용
- `shaders/composite.vsh`, `shaders/composite.fsh`
  - 블룸 추출/블러 패스 추가
  - scene color, bloom buffer, material mask pass-through 구성
- `shaders/gbuffers_terrain.vsh`, `shaders/gbuffers_terrain.fsh`
  - terrain 렌더링 패스 추가
  - texture, vertex color, lightmap 기반 기본 terrain 셰이딩
  - world normal 기반 wet floor/wall mask 기록
  - lava material mask 기록
- `shaders/gbuffers_water.vsh`, `shaders/gbuffers_water.fsh`
  - 물 전용 gbuffers 패스 추가
  - water mask 기록 및 물 전용 푸른 틴트, Fresnel, ripple 하이라이트 적용
- `shaders/gbuffers_skybasic.vsh`, `shaders/gbuffers_skybasic.fsh`
  - 기본 하늘 전용 gbuffers 패스 추가
  - sky geometry의 view direction을 world direction으로 변환해 공통 sky color 적용
- `shaders/gbuffers_clouds.vsh`, `shaders/gbuffers_clouds.fsh`
  - 구름 전용 gbuffers 패스 추가
  - 바닐라 구름 텍스처/알파는 유지하고 RGB 색상을 공통 sky color 체계로 보정
  - alpha 주변 샘플 기반 fake thickness, self-shadow, edge light를 추가해 구름 두께감 보정
- `shaders/gbuffers_skytextured.vsh`, `shaders/gbuffers_skytextured.fsh`
  - 태양/달/별 등 sky textured 요소 전용 gbuffers 패스 추가
  - 텍스처 알파와 밝기는 유지하되 RGB를 `lib/sky.glsl`의 공통 sky color 체계로 tint
- `shaders/shadow.vsh`, `shaders/shadow.fsh`
  - shadow map 생성을 위한 기본 그림자 패스 추가
- `shaders/block.properties`
  - `minecraft:lava`에 커스텀 block ID `block.11000` 할당
  - `minecraft:water`에 커스텀 block ID `block.11001` 할당
- `shaders/lib/color.glsl`
  - 노출, 대비, 채도, 색온도, ACES 톤매핑, 파스텔 톤, dithering 유틸리티 추가
- `shaders/lib/fog.glsl`
  - 깊이 선형화, 렌더 거리 기반 안개, 주변 밝기 기반 안개색 보정 추가
- `shaders/lib/sky.glsl`
  - `getSkyColor(worldDir, worldTime, rainStrength)` 중심의 공통 하늘색 유틸리티 추가
  - 낮/밤/일출·일몰/비 상태별 zenith/horizon 색 보간 추가
  - 화면 y좌표 대신 world direction 기반 horizon mask 사용
- `shaders/lib/lighting.glsl`
  - 태양, 달, 횃불, 용암, 비 색상 팔레트 기반 분위기 조명 추가
  - 손에 든 횃불 조명 거리 감쇠, flicker, surface protection 추가
  - 용암 material mask 기반 발광 보정 추가
  - 달빛 색상을 `#BFD8FF` 기준으로 통일
  - 용암 `#FF3A20`과 비 `#3423A6`는 core/accent 색상으로만 사용하고, 주변광은 완화된 edge/ambient 색상으로 분리
- `shaders/lib/wet.glsl`
  - 비 오는 날 global wet highlight 추가
  - terrain wet/wall mask 기반 fake wet reflection 추가
  - water mask 기반 물 표면 하이라이트 추가
- `shaders/lib/ssr.glsl`
  - 물 마스크(`colortex2.a`)에만 제한된 저비용 screen-space raymarching SSR 기본 경로 추가
  - 16 step 이하의 짧은 raymarch, edge fade, distance fade, Fresnel 기반 합성 적용
- `shaders/lib/shadows.glsl`
  - shadow map 샘플링, PCF, 거리 fade, 파스텔 그림자 tint 추가

### Changed

- 하늘/안개/구름 색 체계를 `lib/sky.glsl` 중심으로 통합
  - `gbuffers_skybasic`이 `getSkyBaseColor(worldDir, ...)`로 기본 하늘색 출력
  - `gbuffers_clouds`가 `getSkyColor(worldDir, ...)` 기반으로 구름 RGB 보정
  - `gbuffers_skytextured`가 태양/달/별 텍스처 RGB를 `getSkyColor(worldDir, ...)` 기반으로 보정
  - 구름 고유 팔레트 비중을 낮추고, 수평선/밤/비 상황에서 `skyColor` 블렌딩 비중을 높여 하늘과 구름 경계 분리 완화
  - 구름 alpha 밀도를 주변 샘플로 추정해 두꺼운 영역은 살짝 어둡게, 가장자리는 sky color로 밝게 보정
  - 비/밤 수평선에서 `getSkyColor()`의 horizon contrast를 낮추고 desaturation을 적용해 sky/fog/cloud 색 평균화 강화
  - final 톤매핑/파스텔 처리 이후에도 sky/cloud/fog 색이 튀지 않도록 `getSkyColor()`에 공통 pre-grade desaturation/soften 보정 추가
  - `final.fsh`의 지형 fog 색을 `fogColor` uniform 대신 `getSkyFogColor(worldDir, ...)` 기반으로 변경
  - 지형 fog factor에 `skyHorizonMask(worldDir)` 기반 horizon fog bias를 약하게 섞어 먼 지형이 하늘 수평선 색으로 더 자연스럽게 들어가도록 조정
  - `final.fsh`에서 `depth >= 1.0` 하늘 픽셀에 적용하던 sky fog 덧칠 제거
- `colortex2` material mask 구조를 `R = wet floor`, `G = wall`, `B = lava`, `A = water`로 확장
- lava mask를 `colortex0.a`에서 `colortex2.b`로 이동
- water mask를 `colortex2.a`에 기록하도록 추가
- `colortex0Format = RGBA8`, `colortex1Format = RGBA16F`, `colortex2Format = RGBA8` 설정
- `composite.fsh`를 `DRAWBUFFERS:012`로 변경해 scene color, bloom buffer, material mask를 함께 전달
- 안개를 렌더 거리(`far`) 비율 기반으로 조정하고, 비 오는 날 안개 시작 지점을 앞당기도록 변경
- 최종 출력 직전 dithering 적용으로 하늘 그라데이션 banding 완화
- 기본 대비, 채도, 블룸 강도를 낮추고 파스텔 톤 보정 추가
- 태양광은 낮/일출/일몰에 따라 색과 강도가 변하도록 조정
- 달빛은 밤 가독성을 위해 차가운 청색광 중심으로 조정
- 횃불 색상은 `#F5853F` 기준으로 재정렬하고 손전등/횃불 느낌을 개선
- 시간대별 기본 옵션 `DAY_LIGHT_STRENGTH`, `NIGHT_LIGHT_STRENGTH`, `SUNSET_GLOW_STRENGTH` 추가
- 용암과 비 색상이 전체 화면을 과하게 물들이지 않도록 core/accent와 ambient tint를 분리
- 비 오는 날 wet reflection은 바닥/상면에 강하게, 벽면에는 약하게 적용되도록 변경
- 물 표면에 Fresnel/specular 하이라이트와 화면색 기반 rough reflection blur 적용
- 물 반사색을 `lib/sky.glsl`의 `getSkyColor()`와 연동해 하늘/fog/구름/물 반사 색상 분리 완화
- 물 반사 전용 `getSkyWaterReflectionColor()`를 추가해 sky color를 수평선 방향으로 가중 보정
- final 패스에서 water mask 픽셀에만 `applyWaterSSR`을 적용하고, hit 실패 시 기존 fake water reflection이 유지되도록 변경

### Fixed

- 일부 지형/오브젝트가 투명하게 빠져 보일 수 있던 문제 수정
- opaque terrain의 scene alpha가 material mask로 오염되던 구조 제거
- lava/emissive block mask를 별도 material mask 버퍼(`colortex2.b`)에서 관리하도록 수정
- 밤하늘 및 낮 수평선에서 final sky fog가 하늘을 다시 덧칠하며 층처럼 갈라지던 구조 완화
- 그림자 acne/깜빡임 완화를 위해 slope bias, distance bias, edge fade, distance fade, weather/night fade 적용

## Shader Options

Options are grouped under the `MOOD` screen in Iris.

- `EXPOSURE`
- `CONTRAST`
- `SATURATION`
- `LIGHTING_STRENGTH`
- `DAY_LIGHT_STRENGTH`
- `NIGHT_LIGHT_STRENGTH`
- `SUNSET_GLOW_STRENGTH`
- `TORCH_LIGHT_INTENSITY`
- `RAIN_REFLECTION_INTENSITY`
- `BLOOM_INTENSITY`
- `BLOOM_THRESHOLD`
- `FOG_DENSITY`
- `FOG_START`
- `VIGNETTE_OUTER`

## Current Buffer Layout

- `colortex0`: scene color
- `colortex1`: bloom buffer
- `colortex2.r`: wet floor mask
- `colortex2.g`: wall mask
- `colortex2.b`: lava mask
- `colortex2.a`: water mask

## Current Sky/Fog Layout

- `gbuffers_skybasic`: 기본 하늘색을 `lib/sky.glsl`의 `getSkyBaseColor()`로 출력
- `gbuffers_clouds`: 구름 색을 `lib/sky.glsl`의 `getSkyColor()` 기반으로 보정
- `gbuffers_skytextured`: 태양/달/별 텍스처를 `lib/sky.glsl`의 `getSkyColor()` 기반으로 tint
- `final.fsh`: 지형/오브젝트(`depth < 1.0`)에만 fog 적용
- `final.fsh`: 하늘 픽셀(`depth >= 1.0`)에는 별도 sky fog 덧칠 없음

## Water SSR Roadmap

- 물 마스크(`colortex2.a`)가 있는 픽셀에만 SSR 적용 완료
- final 패스에서 depth 기반 view-space position 복원값 재사용
- 화면 공간 water wave normal을 재계산해 반사 방향 생성
- `depthtex0`를 16 step 이하로 짧게 raymarch
- hit 지점의 `colortex0` 색을 반사색으로 샘플링
- 화면 가장자리, 거리, water mask 기반 fade 적용
- hit 실패 시 기존 fake water reflection 유지
- 추후 binary search, roughness blur, sky fallback 품질 개선

## Planned / Not Implemented

- 인게임 Iris 컴파일 로그 확인
- 낮, 밤, 동굴, 비, 네더, 엔드 환경별 색감 튜닝
- normal 기반 wet specular BRDF 추가
- 물 전용 SSR에 binary search, roughness blur, sky fallback 품질 개선
- 안개 색을 바이옴/차원/날씨에 따라 다르게 적용
- 동굴 내부 가독성을 위한 어두운 영역 보정 추가
- 옵션 설명과 추천 프리셋 정리
- 쉐이더팩 압축 구조 검증
