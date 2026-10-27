# 작업 체크리스트

범용 예시다. 작업 시작 시 목표와 완료 조건을 작성하고, 실행 항목을 실제 작업에 맞게 바꾼다.

## 관리 규칙
- 실제 수행과 필요한 검증이 끝난 항목만 체크한다.
- 실패·차단·미실행을 완료로 표시하지 않는다.
- 불필요한 항목은 삭제하거나 체크하지 않은 채 `해당 없음 — 이유`로 표시한다.
- 주요 단계가 끝나거나 작업 상태가 달라질 때 갱신한다.
- 검증 기록에는 실행 명령 또는 확인 방법과 실제 결과를 남긴다.
- 여러 작업을 병행하면 작업별 섹션이나 별도 파일로 기록을 구분한다.
- 지속적으로 적용할 규칙은 AGENTS.md에 기록한다.

## 목표와 범위
- 목표:
- 작업 대상:
- 완료 조건:

## 현재 상태
- 진행 단계: 준비 / 구현 / 검증 / 완료 / 차단 중 선택
- 다음 할 일:
- 차단 원인: 해당하는 경우 기록

## 1. 사전 확인
- [ ] 적용되는 AGENTS.md와 관련 문서를 확인했다.
- [ ] 관련 코드와 설정, 기존 변경 상태를 확인했다.
- [ ] 요청한 결과와 수정 범위를 파악했다.
- [ ] 필요한 실행·검증 방법을 확인했다.

## 2. 실행
<!-- 아래 항목을 실제 작업에 맞는 구체적인 항목으로 교체한다. 필요에 따라 추가하거나 삭제한다. -->
- [ ] 작업 항목 1:
- [ ] 작업 항목 2:
- [ ] 작업 항목 3:

## 3. 검증
- [ ] 변경한 동작이 완료 조건을 만족하는지 확인했다.
- [ ] 영향받는 기존 동작을 필요한 범위에서 확인했다.
- [ ] 발견된 문제를 해결하고 필요한 검증을 다시 수행했다. 문제가 없었다면 해당 없음으로 기록한다.

### 검증 기록
| 확인 항목 | 명령 또는 방법 | 결과 | 미실행·실패 이유 |
|---|---|---|---|
| | | | |

결과는 통과 / 실패 / 미실행 / 해당 없음으로 구분하고 필요한 근거를 적는다.

## 4. 완료
- [ ] 필요한 문서를 갱신했다.
- [ ] 변경 내용을 최종 검토했다.
- [ ] 미완료 항목과 남은 한계를 기록했다.
- [ ] 사용자에게 변경 내용과 검증 결과를 설명했다.

## 주요 결정
- 결정:
- 이유:

## 남은 작업
<!-- 후속 작업이 없으면 '없음'으로 기록한다. -->
- [ ] 후속 작업:

## 2026-10-05 — 셰이더용 스킬 수정과 AGENTS 통합

### 목표와 범위

- SKILL.md를 현재 GLSL 셰이더팩 구조에 맞춘 뒤 AGENTS.md와 AGENTS.en.md의 규칙을 AGENTS.md로 통합한다.
- 대상은 SKILL.md, AGENTS.md, AGENTS.en.md와 이 작업 기록이다. 셰이더 소스와 설정은 변경하지 않는다.
- 완료 조건은 스킬 형식 검사, 실제 경로·버퍼 계약 확인, 중복·충돌 정리 및 변경 형식 검사다.

### 진행

- [x] 원문과 실제 패스·버퍼·옵션, Git 상태를 확인했다.
- [x] 스킬을 수정하고 다시 읽은 뒤 통합 절차에 적용했다.
- [x] 통합 AGENTS를 작성하고 영문 파일을 단일 원본 참조로 바꿨다.
- [x] 스킬 형식과 문서 정확성, 변경 범위를 직접 검사로 최종 검증했다. 공식 검증기의 환경 제한은 아래에 기록했다.

### 결정과 근거

- 통합 원본은 한국어 AGENTS.md다. AGENTS.en.md는 참조 안내만 남겨 규칙 중복을 방지한다.
- 새 파일 주석은 GLSL 필수 지시문과 기존 스타일을 고려하며, 단순 수정에는 체크리스트를 강제하지 않는다.
- 현재 패스와 버퍼 계약은 소스를 근거로 기록하고, 과거 반사 튜닝값은 영구 규칙으로 넣지 않는다.
- 기존 범용 체크리스트 예시는 보존하고 이번 기록을 별도 섹션으로 추가했다.

### 검증 기록

- 공식 검사 명령은 `python C:\Users\btsds\.codex\skills\.system\skill-creator\scripts\quick_validate.py G:\Game\S-Shader`다. 기본 Python과 번들 Python 모두 `ModuleNotFoundError: No module named 'yaml'`로 실패했다. 환경 의존성 누락이며 문서 형식 오류로 판단하지 않는다.
- 번들 실행 파일은 `C:\Users\btsds\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`다. 의존성 설치는 하지 않았다.
- 대체 검사로 PowerShell에서 frontmatter 구분자·name/description 필드·이름 규칙·설명 길이, TODO 자리표시자와 코드 펜스 닫힘을 확인했다. 결과는 통과다. 전체 YAML 파서 검증을 수행한 것으로 보고하지 않는다.
- 네 문서의 줄 끝 공백과 참조 파일 존재 여부를 확인했다. 결과는 통과다. 두 AGENTS 원문의 고유 규칙과 통합 문서, 패스·버퍼·옵션 근거를 대조했다.
- 루트에서 `git diff --check`를 실행했다. 결과는 통과이며 Git의 LF/CRLF 변환 안내가 있었다.
- `git diff --exit-code -- shaders README.md CHANGELOG.md LICENSE`는 exit code 0이다. 셰이더 소스·설정과 관련 사용자 문서에 변경이 없다.
- 게임 실행과 셰이더 컴파일은 미실행이다. 이번 작업은 문서만 변경한다.

### 현재 상태와 남은 작업

- 진행 단계는 완료다. 요청한 문서 수정과 통합, 대체 검증은 완료했다.
- 공식 quick_validate.py 검증만 PyYAML 누락으로 미완료다. 사용 가능한 YAML 환경에서 위 명령으로 재확인할 수 있다.

## 2026-10-05 — 용암 자체 발광과 bloom 개선

### 목표와 구현

- [x] 기존 용암 마스크, lightmap 적용과 bloom/조명 경로를 확인했다.
- [x] terrain 패스에서 용암의 lightmap 감쇠를 제외해 기본 텍스처 밝기를 유지했다.
- [x] 최종 패스에 용암 전용 발광을 추가했다. 밝은 텍스처 부분을 강화하며, 날씨·그림자 보정 이후와 안개·톤 매핑 이전에 적용한다.
- [x] composite에 용암 마스크 전용 9-tap halo를 추가했다. 기존 장면 bloom의 반경은 유지한다.
- [x] LAVA_EMISSION_INTENSITY 옵션을 기본값 1.0, 허용 범위 0.0–2.0으로 노출하고 README에 사용법을 기록했다.
- [x] 정적 연결 검사와 diff 검토를 완료했다.

### 검증과 제한

- PowerShell 정적 검사는 GLSL 1.20 지시문, include 경로, 두 패스의 옵션 정의 일치, 변경된 함수의 정의·호출 인수 수, screen/sliders 등록을 확인했다. 결과는 통과다.
- HEAD와 비교해 terrain/composite의 DRAWBUFFERS와 gl_FragData 출력이 바뀌지 않았음을 확인했다.
- 루트의 `git diff --check`는 통과했다. 기존 AGENTS 변경에 대한 LF/CRLF 안내만 있었다.
- `Get-Command glslangValidator,glslc -ErrorAction SilentlyContinue`에서 컴파일러를 찾지 못했다. 컴파일과 게임 화면 비교는 미실행이며 정적 검사로 대체 검증되었다고 주장하지 않는다.
- 주변 블록을 추적해 비추는 광원·간접 조명은 구현하지 않았다. 화면상 번짐이며 추가 샘플 비용은 픽셀당 최대 18 texture reads다.

### 남은 확인

- [ ] Iris/NeOculus에서 셰이더를 재로드하고 컴파일 로그와 옵션 반영을 확인한다.
- [ ] 동굴·네더의 용암을 비교해 텍스처 무늬, 화면 가장자리 halo, 과노출과 FPS를 확인한다.
- [ ] LAVA_EMISSION_INTENSITY 0.0/1.0/2.0, BLOOM_INTENSITY 0.0, LIGHTING_STRENGTH 0.0 조합을 게임에서 확인한다.

## 2026-10-05 - 이동에 따른 그림자 변화 완화와 명도 감소

### 목표와 구현

- [x] 기존 사용자 변경이 없는 상태와 shadow map, PCSS, form lighting 경로를 확인했다.
- [x] 플레이어 거리별 PCSS 필터 반경과 near/mid/far 농도 보정을 제거했다. 반경은 광원 공간의 blocker/receiver 간격을 따른다.
- [x] 실제 shadowModelView의 Z 행에서 광원 방향을 구해 표면 음영과 shadow sky tint에 사용했다.
- [x] 시선 각도에 따라 form shadow를 약하게 만드는 항을 제거했다. 반사 하이라이트의 시선 의존성은 유지한다.
- [x] SHADOW_DARKNESS를 0.86에서 0.94로 올리고 shadow tint 목표에 0.62를 곱했다. 어두운 재질과 물/용암 보호는 유지한다.
- [x] README와 CHANGELOG를 갱신하고 정적 검사를 완료했다.

### 검증과 제한

- `git diff --check`는 통과했다. LF/CRLF 변환 안내만 있었다.
- PowerShell 정적 검사에서 거리 split 제거, form shadow의 시선 감쇠 제거, 변경 함수의 정의/호출과 include 순서·경로를 확인했다. 결과는 통과다.
- PCSS 반경 0.65/1.0/2.8의 보간 범위와 tint 0.46/0.70/1.08에서 새로운 그림자 목표가 이전보다 어둡고 양수임을 확인했다. 결과는 통과다. 최종 톤 매핑 이후의 명도 측정은 아니다.
- `git diff --exit-code -- shaders/final.fsh shaders/shadow.vsh shaders/shadow.fsh shaders/gbuffers_terrain.vsh shaders/gbuffers_terrain.fsh shaders/shaders.properties`는 exit code 0이다. 관련 패스 인터페이스·버퍼 계약·설정은 변경하지 않았다.
- `Get-Command glslangValidator,glslc -ErrorAction SilentlyContinue`에서 컴파일러를 찾지 못했다. 셰이더 컴파일과 게임 내 시각 검증은 미실행이다.
- 단일 shadow map의 재투영·텍셀 해상도, derivative bias, 맵 가장자리 fade와 안개의 영향은 남아 있다. 이동에 따른 모든 경계 변화를 제거했다고 판단하지 않는다.

### 남은 확인

- [ ] Iris/NeOculus에서 셰이더를 재로드하고 컴파일 로그를 확인한다.
- [ ] 게임 시간을 고정한 채 같은 블록의 그림자 경계를 전후/좌우 이동과 시선 회전으로 비교한다. PCF와 PCSS를 각각 확인한다.
- [ ] 같은 위치에서 아침/정오/해질녘의 그림자 방향·길이와 표면 음영이 일치하는지 비교한다.
- [ ] 낮/밤/비, 먼 지형과 foliage/glass/crop 경계에서 너무 어두운 부분이나 반짝임이 없는지 확인한다.

## 2026-10-05 - 화면 전체 그림자 분리와 이동 중 변화 후속 수정

### 근거와 구현

- 사용자는 특정 재질과 관계없이 화면 전체에서 그림자가 덩어리로 갈라진다고 보고했다. 게임 화면·컴파일 로그는 직접 확인하지 않았다.
- [x] 현재 diff를 읽고 앞선 그림자 명도·태양 방향 수정은 보존했다.
- [x] 공식 Iris 문서에서 해상도·거리·스냅 간격이 GLSL 상수임을 확인했다. 기존 bare shaders.properties 키를 제거하고 lib/shadow_settings.glsl에서 2048/96.0/8.0을 선언해 shadow/final에 공유했다.
- [x] 기존 receiver가 wet response를 그대로 사용해 getShadowVisibility의 0.5 임계값에서 흙 벽·나무 등의 그림자를 누락시키는 코드를 확인했다. receiver는 재질 채널의 존재 여부로 변환하며 hand/entity의 0 마스크는 유지한다.
- [x] dFdx/dFdy 기반 bias를 제거하고 world normal·광원 방향·투영 크기에 기반한 제한된 texel slope bias로 바꿨다.
- [x] nearest raw depth를 읽어 각각 비교한 결과를 bilinear 보간한다. 기본값은 고정 반경 PCF 0이며 PCSS 1은 선택 가능하다. blocker 미발견 시 PCF로 fallback한다.
- [x] 건조한 날에는 rain exposure의 추가 깊이 샘플링을 생략했다.
- [x] README와 CHANGELOG에 옵션 기본값·설정 위치·성능 및 검증 한계를 기록했다.

### 검증 기록

- PowerShell에서 shadow/final include를 재귀 확장해 경로 존재, GLSL 120, 괄호 수와 로더 상수의 단일 선언, 변경 함수의 정의/호출 인수 수를 확인했다. 결과는 통과다. 문법 컴파일 검사는 아니다.
- 0.08~1.0의 기존 재질 response가 receiver 1로 처리되고, 0 마스크는 receiver 0으로 남는 수치 검사는 통과했다.
- 깊이 0.2/0.8과 receiver 0.5의 경계에서 보간 비율 0/0.25/0.5/0.75/1에 따라 visibility가 연속적으로 변하는 수치 검사는 통과했다.
- noL 0/0.2/0.5/0.9/1에서 slope 제한과 양수 bias를 확인했다. 96블록·2048텍셀·예시 깊이 범위 512블록에서 bias는 이전 0.0012보다 작다. 결과는 통과다. 실제 게임의 shadowProjection은 런타임에서 확인해야 한다.
- `git diff --exit-code -- shaders/gbuffers_terrain.vsh shaders/gbuffers_terrain.fsh shaders/gbuffers_hand.fsh shaders/gbuffers_entities.fsh shaders/shadow.vsh`는 exit code 0이다. G-buffer 작성 및 caster 위치/재질 인터페이스는 보존했다.
- GLSL 컴파일러가 없는 현재 환경에서 컴파일·게임 시각·FPS 검증은 미실행이다.
- 공식 근거는 https://shaders.properties/current/reference/constants/shadowmapresolution/, https://shaders.properties/current/reference/constants/shadowdistance/, https://shaders.properties/current/reference/constants/shadowintervalsize/, https://shaders.properties/current/guides/your-first-shaderpack/4_shadows/ 이다.

### 남은 확인

- [ ] 셰이더 재로드와 컴파일 로그 확인, 저장된 SHADOW_MODE 옵션을 0으로 선택한다.
- [ ] 시간 고정 상태에서 가까운/먼 지형과 흙 벽·나무·돌의 경계를 이동·회전으로 비교한다.
- [ ] 8블록 스냅 경계에서의 재투영 변화, 낮은 태양에서 acne·그림자 접점 분리, 비·밤의 명도와 FPS를 확인한다.
- 단일 맵의 가시 범위와 가장자리 fade는 카메라 중심이므로 모든 이동 의존성이 제거되지는 않는다. 이번 수정으로 게임 증상이 해결되었다고 아직 확정하지 않는다.

## 2026-10-05 - 수심별 물 alpha와 반사 구분

### 목표와 구현

- [x] 현재 water/final/depth 버퍼와 SSR 경로를 읽고 기존 그림자 변경을 보존했다.
- [x] lib/water_depth.glsl에 수심 복원·보간과 alpha/반사 기준을 모았다. 표면과 depthtex1 불투명 바닥의 view position을 world-space 차이로 변환해 수직 높이 차이를 사용한다.
- [x] 수심 2블록 이하의 alpha 0.35/반사 입력 0.25부터 12블록 이상의 alpha 0.70/반사 입력 0.60까지 smoothstep으로 연결했다. 반사 값은 기존 master 0.60일 때의 값이며 Fresnel 감쇠 전이다.
- [x] 물 색 흡수에 카메라 거리 대신 같은 수심 factor를 사용하고 stable/SSR 양쪽에 수심별 반사 강도를 전달했다.
- [x] 물속 시점과 폭포는 수심 보간에서 제외하고 alpha 0.45를 사용한다. 바닥 미노출은 깊은 물로 처리한다.
- [x] 물 색 alpha blending을 유지하면서 colortex2/3의 blending을 꺼 mask/normal이 불투명 바닥 데이터와 섞이지 않도록 했다.
- [x] README와 CHANGELOG를 갱신했다.

### 검증과 제한

- 수치 검사 30건은 카메라 높이 5/30블록, 하향 각도 15/45/90도, 수심 1/2/7/12/20블록의 평평한 바닥에서 perspective depth 복원과 수직 수심 계산을 확인했다. 오차 1e-8 이내이며 alpha/반사 보간 범위 검사도 통과했다.
- PowerShell 재귀 include 확장과 정적 검사에서 GLSL 120, helper 중복, 깊이 uniform, 함수 정의/호출 인수 수, 수중 예외와 SSR 연결, 물 데이터 buffer blending, DRAWBUFFERS 보존을 확인했다. 결과는 통과다. shader 문법 컴파일은 아니다.
- depthtex1과 per-buffer blending의 공식 근거는 https://shaders.properties/current/reference/buffers/depthtex/ 및 https://shaders.properties/current/reference/shadersproperties/rendering/ 이다.
- 수심은 보이는 시선 아래 불투명 표면과의 수직 차이다. 바이옴 판별과 정확한 수직 지형 추적은 아니며 해안 절벽·가림·다중 투명면에서 근사 오차가 있다.
- water/final에 필요한 물 픽셀당 각각 depth 읽기 1회가 추가된다. 기존 G-buffer 채널 매핑과 hand/entity 작성은 변경하지 않는다.
- 현재 환경에 GLSL 컴파일러가 없어 게임 컴파일·시각·FPS 검증은 미실행이다.

### 남은 확인

- [ ] 셰이더 재로드와 Iris/NeOculus 로그 확인, 기존 WATER_REFLECTION_INTENSITY 0.6에서 비교한다.
- [ ] 1~2블록 강과 12블록 이상 바다, 중간 수심에서 alpha·반사·색 연결을 확인한다.
- [ ] 같은 수면을 카메라 높이·시선 각도 변경으로 비교하고 해안 절벽·바닥 미노출·수중·폭포·유리 겹침을 확인한다.
- [ ] 반사 모드 0/1과 ENABLE_WATER_SURFACE 0/1, 반사 강도 0/0.6/1.0을 비교하고 FPS를 확인한다.

## 2026-10-05 - README 검토에 따른 우선 수정·구현 목록

### 범위와 상태

- 목표는 README의 구현 설명을 정확하게 정리하고, 현재 셰이더 구조에서 진행 가능한 개선을 우선순위대로 추적하는 것이다.
- 현재 상태는 차단이다. 2026-10-17에 P0 코드·문서 수정을 마쳤으나 P0-1의 게임 확인과 P1 전체는 Iris/NeOculus가 있는 PC가 필요하다. 아래 "2026-10-17 진행 기록"을 참고한다.
- 순서는 P0의 설정·문서 정리, P1의 현재 효과 검증·개선, P2의 기능 확장이다. 코드가 존재하는 상태와 게임 검증을 통과한 상태를 구분한다.
- 다음 작업은 Iris/NeOculus가 설치된 PC에서 P0-1 게임 컴파일·버퍼 형식 확인과 P1-1 기준 환경 기록이다.

### P0 - 설정과 문서 정확성

- [ ] P0-1. `shaders.properties`에만 있는 colortex0/1/2/3Format을 로더가 인식하는 GLSL 상수 선언으로 옮긴다. bloom과 normal의 RGBA16F 의도, 채널 매핑과 선언 중복 여부를 확인한다. 완료 기준은 include·패스 연결 검사와 게임 컴파일·실제 버퍼 형식 확인이다.
  - 2026-10-17: 코드 수정은 완료했으나 게임 확인을 하지 않아 미체크 상태다. `composite.fsh` 블록 주석에 선언했고, 로더가 읽지 않는 `shaders.properties` 키는 제거했다.
- [x] P0-2. README의 그림자 설명을 "이동해도 변하지 않음"에서 "이동에 따른 필터·농도 변화를 완화함"으로 정정한다. 단일 맵의 재투영·스냅 경계·가시 범위 제한을 함께 기록한다.
- [x] P0-3. README의 반사 모드 1을 "약한 SSR 추가" 대신 현재의 SSR 반사·하늘색 fallback 경로로 설명한다. stable reflection을 끄는 실제 분기와 설명을 대조한다.
- [x] P0-4. PCF는 주변 8개와 중심 1개의 필터 위치, 최대 36회 깊이 읽기이며 PCSS는 blocker 탐색 최대 8회가 추가됨을 명시한다. README에 WATER_REFLECTION_INTENSITY 옵션도 추가한다.
- [x] P0-5. 횃불의 기획 색 #F5853F와 현재 상수의 근사 색 #FF853B를 구분해 적는다. 기획 색을 실제 조명에 적용할지는 게임 비교 후 결정한다.
- [x] P0-6. README를 구현·근사/제한·검증 상태·향후 기획으로 구분한다. 안정성·색 층 분리 완화는 품질 목표/미검증 상태로 표시하고, 크래시 원인은 로그로 확인되기 전까지 확정하지 않는다.

### P1 - 현재 그림자와 물의 검증·개선

- [ ] P1-1. Minecraft·Iris/NeOculus·렌더링 모드·GPU/드라이버 버전을 기록하고 컴파일 로그와 기준 FPS를 확보한다. 호환성은 실제 확인한 조합에 대해서만 기록한다.
- [ ] P1-2. 기존 "화면 전체 그림자 분리와 이동 중 변화 후속 수정"의 남은 확인을 수행한다. 시간 고정 이동/회전, 8블록 스냅 경계와 낮은 태양에서의 자기 그림자 얼룩·접점 분리를 비교하고, 확인된 원인에 맞춰 bias/필터/스냅을 조정한다.
- [ ] P1-3. 기존 "수심별 물 alpha와 반사 구분"의 남은 확인을 수행한다. 얕은 강·깊은 바다·중간 수심에서 보간을 확인하고 카메라 높이/각도, 비·밤·수중·폭포, 반사 모드 0/1을 비교한다.
- [ ] P1-4. 해안 절벽·물 밖 지형·바닥 미노출·겹친 투명면에서 수심 오차를 재현한다. 현재 depthtex1로 확인 가능한 오류부터 보정하고, 정보가 부족한 경우의 fallback을 명시한다. 정확한 수직 지형 추적으로 설명하지 않는다.
- [ ] P1-5. 수중 색 흡수와 시인성을 개선한다. 물 밖 수면의 수심 factor와 물속 시야 경로를 구분하고 얕은 물/깊은 물·수면 상하 전환에서 과도한 착색이나 밝기 튐을 확인한다.
- [ ] P1-6. SSR의 반사 방향·표면 normal 사용과 hit 판정을 먼저 검증한 뒤 화면 가장자리와 가림 해제 fallback을 개선한다. 프레임 기록 도입은 필요한 경우 별도 설계하며, 화면 밖 물체의 정확한 복원을 완료 기준으로 삼지 않는다.
- [ ] P1-7. 각 개선 전후에 같은 장면·해상도·옵션으로 스크린샷과 FPS를 비교한다. 기존 기록에 검증 결과를 남겨 중복 상태 관리를 피한다.

### P2 - 현재 구조에서 확장 가능한 기능

- [ ] P2-1. 재질 분류를 정리해 그림자 tint와 roughness/반사율을 wet response만으로 추정하는 의존성을 줄인다. block.properties와 버퍼 저장 공간을 먼저 검토하고 writer·composite·consumer 계약을 함께 설계한다.
- [ ] P2-2. 지형과 젖은 표면의 방향성 BRDF를 개선한다. 실제 광원 방향, 표면 normal, 재질 반응을 일관되게 연결하고 낮/밤/비에서 비교한다.
- [ ] P2-3. 발광 블록의 caster 규칙을 세분화한다. 발광부 음영 처리와 블록 자체의 차폐를 구분하며, 주변 광원에 대한 동적 그림자는 별도 기능으로 취급한다.
- [ ] P2-4. 색유리 colored shadow의 소규모 시제품을 구현한다. shadowcolor 출력·읽기와 투과 정보 계약을 추가하고 일반 불투명 블록·단일 색유리·겹친 색유리의 결과와 샘플 비용을 확인한다.

### 별도 연구 과제

- 실제 cascade shadow map은 여러 투영/맵 영역·선택·전환 구조를 설계해야 하므로 위 우선 구현 목록과 분리한다.
- 진짜 planar reflection은 반사 시점 장면을 별도로 확보하는 렌더링 구조와 로더 지원을 조사한 뒤 진행 여부를 결정한다.
- 화면 밖 물체의 정확한 SSR과 이동 중 모든 그림자의 완전 불변은 현재 화면/단일 맵 정보만으로 보장할 수 없으므로 완료 목표로 사용하지 않는다.

### 기록 갱신 기준

- 실제 구현과 필요한 검증이 끝난 항목만 체크한다. 게임 실행이 불가능하면 정적 확인과 미실행 검증을 분리해 기록한다.
- README 검토 근거는 현재 소스와 Iris 공식 Buffer Format, ShadowColor 및 프로그램 파이프라인 문서다. 작성 시점(2026-10-05)에는 셰이더 구현과 README 정정을 수행하지 않았다.

### 2026-10-17 진행 기록

- P0-1: Iris 공식 Buffer Format 문서(https://shaders.properties/current/reference/constants/buffer_format/)에 따라 `const int colortexNFormat = <format>;`을 `composite.fsh`의 블록 주석에 한 줄씩 선언했다. 형식 값과 채널 매핑은 기존과 같다. 다른 파일에 중복 선언이 없음을 grep으로 확인했다.
- P0-2~P0-6: README의 그림자 이동 설명, 반사 모드 1 분기, PCF 9개 위치×4회 읽기, `WATER_REFLECTION_INTENSITY` 옵션, 횃불 기획 색과 상수 색, 문서 상태 구분·검증 상태 절을 소스와 대조해 수정했다.
- P1-1 환경 조사(이 PC): `.minecraft` 최근 로그에서 Minecraft 26.3 바닐라, Vulkan 백엔드, NVIDIA GeForce GTX 1650 with Max-Q Design, 드라이버 617.42를 확인했다. mods 폴더가 없고 shaderpacks에는 다른 팩만 있어 Iris/NeOculus와 S-Shader 실행 환경이 없다. 호환성 기록이 아니라 환경 조사 결과다.
- `glslangValidator`·`glslc`는 이 PC에서 찾지 못했다. 셰이더 컴파일과 게임 시각·FPS 검증은 미실행이다.
- P1-2~P1-7은 게임 화면 재현을 전제로 하므로 차단 상태다. 재현 없이 bias·수심·SSR 값을 바꾸는 것은 추측성 변경이라 진행하지 않았다.
- P2는 P1 검증 이후로 미뤘다. P2-1·P2-4는 버퍼 계약 변경을 포함하므로 컴파일 가능한 환경에서 시작한다.
- 루트의 `git diff --check`는 통과했고, LF/CRLF 변환 안내만 있었다. 커밋은 하지 않았다.

### 2026-10-19 진행 기록 - P1-6 SSR 반사 방향

- 정적 근거: `lib/ssr.glsl`이 카메라 방향 벡터(`-viewPos`)를 화면 정면 normal(view Z)로 반사해, 수면 normal을 쓰지 않고 좌우가 뒤집힌 ray를 만들었다. Fresnel도 화면 위치에 따라 달라졌다.
- [x] 평평한 수면 normal(world ±Y)에 world XZ ripple을 더하고 `gbufferModelView`로 view 공간에 옮겼다. `faceforward`로 수중 시점도 카메라 반대쪽으로 반사한다.
- [x] 입사 ray(`normalize(viewPos)`)를 반사하고 Fresnel은 실제 수면 normal과의 각도를 쓴다. roughness의 ripple 입력 크기는 기존과 같다.
- [x] `final.fsh`에 `gbufferModelView`를 선언하고 호출 인수를 연결했다. 다른 include에 같은 uniform 선언이 없음을 grep으로 확인했다.
- 검증: 평평한 수면 수치 검사 560건(수면 위/아래, pitch −80~60°, yaw 4종, 화면 위치 20곳)에서 새 경로의 방향 오차는 1e-6° 이하, Fresnel cos 오차는 2.2e-16이다. 기존 경로는 최대 약 164° 벗어났다. `git diff --check`는 통과했다.
- 미실행: 이 PC(Windows 11 Pro)에는 `.minecraft`·Iris와 `glslangValidator`·`glslc`가 없어 컴파일·게임 화면·FPS를 확인하지 않았다. P1-6은 게임 검증 전이라 미체크로 둔다.
- 남은 일: hit 판정이 `depthtex0`의 수면 자체와 맞을 수 있는지, 화면 가장자리·가림 해제 fallback은 게임에서 확인한 뒤 다룬다. `gbuffers_water.fsh`의 wave normal 편향은 아래 기록에서 수정했다.

### 2026-10-19 진행 기록 - 물 wave normal 카메라 편향

- 정적 근거: `getWaterWaveNormal`이 접선 공간 벡터 `(waveX, waveY, 1/0.11)`을 view 공간 normal에 더해, ripple과 무관하게 모든 물 normal이 카메라 쪽(view +Z)으로 약 6° 기울었다. 이 normal은 `colortex3`, Fresnel·alpha, 폭포 판정, final의 stable 반사 방향에 쓰인다.
- [x] world 공간 수면 normal의 접선·종접선 평면 안에서만 ripple을 더하고, view 공간 normal은 결과를 `gbufferModelView`로 변환해 얻는다. ripple 크기와 `WATER_WAVE_NORMAL_STRENGTH`는 유지했다.
- 검증: 수치 검사에서 ripple 0일 때 편향은 기존 최대 6.315°에서 0°가 되었고, ripple 기울기 차이는 최대 0.821°다. 10° 하향 시선의 Fresnel은 약 0.52에서 0.68로 올라 alpha 증가는 약 +0.01이다. `git diff --check`는 통과했다.
- 미실행: 이 PC에는 게임·로더와 GLSL 컴파일러가 없어 컴파일·화면·FPS를 확인하지 않았다. 낮은 시선에서 반사·투명도가 조금 강해지는지는 게임에서 비교해야 한다.
- 남은 일: `getWaterSpecular`의 view 공간 고정 광원 방향과 atlas `texCoord` 기반 ripple의 블록 반복 여부는 별도 항목(P2-2 등)으로 다룬다.

### 2026-10-19 진행 기록 - P1-5 수중 시점의 수면 하늘 반사

- 정적 근거: `isEyeInWater == 1`이면 수심 보간만 건너뛰고, `waterReflectionIntensity`는 기본값 그대로 `applyWaterSurface`·`applyWaterSSR`에 전달됐다. 그래서 수면 아랫면에도 하늘색 반사가 섞였다.
- [x] `final.fsh`에서 물속 시점의 물 반사 강도를 0으로 설정했다. 안정 반사와 SSR 경로 모두에 적용된다.
- [x] `gbuffers_water.fsh`의 하늘 반사 하이라이트 항을 물 밖 시점에서만 더한다. 물 색 tint는 유지했다.
- [x] `applyWaterSSR`는 강도 0이면 ray march를 생략한다. 물 밖에서 강도 0일 때의 결과는 기존과 같다.
- 검증: `applyWaterSurface`의 하늘색 반사(`skyMatchedReflection`, `softReflection`)와 SSR의 fallback·hit 혼합이 모두 강도에 비례함을 코드로 확인했다. 정적 검사뿐이다.
- 미실행: 게임에서 수중의 수면 아랫면, 수면 상하 전환과 밝기 변화를 확인하지 않았다. 반사를 끈 뒤 아랫면이 너무 밋밋하거나 밝으면 굴절 창·전반사 근사를 별도로 검토한다.
- P1-5의 나머지(수중 색 흡수와 시인성, 얕은 물/깊은 물의 착색)는 게임 확인이 필요해 미체크로 둔다.

### 2026-10-19 진행 기록 - CHANGELOG 하단 Current 섹션 정리

- 정적 근거: CHANGELOG 하단의 옵션 목록에 `shadowDistance`·`LAVA_EMISSION_INTENSITY`·`WATER_REFLECTION_INTENSITY`가 빠져 있었다. 그림자 상태에는 제거된 거리 split·`SHADOW_DARKNESS = 0.74`·glass caster 제외가 남아 있었고, 물 로드맵은 SSR을 "약한 SSR"로 설명했다.
- [x] Options·Buffer Layout·Shadow·Water 상태 절을 README 참조 안내 한 절로 바꿨다. README의 해당 내용이 현재 소스와 맞으므로 같은 상태를 두 문서에서 관리하지 않는다.
- [x] Goals와 Material IDs는 README에 없는 내용이라 유지했다. Material IDs는 `block.properties`의 11000–11105와 일치한다.
- [x] Planned는 체크리스트 P1·P2·별도 연구 과제와 겹치는 항목을 빼고, 이 체크리스트를 가리키는 안내와 남은 장기 계획 3개만 남겼다.
- 검증: README의 옵션 26개(`#define` 25개와 `shadowDistance`)가 소스와 일치하고, 참조한 README 절 제목과 체크리스트 섹션 제목이 존재함을 확인했다. `git diff --check`를 실행했다.

## 2026-10-27 - bloom 2패스 분리와 광원 고도 기반 그림자 페이드

### 목표와 구현

- 목표는 bloom의 텍스처 읽기를 같은 결과로 줄이고, 그림자 강도를 시각 구간 대신 실제 광원 고도에 맞추는 것이다.
- [x] `composite`는 가로 5탭 bloom을 `colortex1`에, 가로 3탭 용암 halo를 새 `colortex4`(RGBA16F)에 쓴다. 새 `composite1`이 세로 blur와 `BLOOM_CLAMP`를 적용해 `colortex1`에 쓴다. 공통 커널은 `lib/bloom.glsl`로 옮겼다.
- [x] 용암 halo의 화면 밖 샘플 제외 조건을 가로·세로 패스에서 각각 검사해, 기존 2D 조건과 같은 결과가 되게 했다.
- [x] `getShadowDayFactor(worldTime)`를 `getShadowLightFade()`로 바꿨다. 광원 world Y 0.02–0.20에서 smoothstep으로 페이드하고, `sunAngle >= 0.5`(달)이면 0.42배다. 페이드가 0이면 그림자 샘플링을 건너뛴다. 사용하지 않게 된 `worldTime` 인수는 `getShadowVisibility`에서 뺐다.
- [x] `wet.glsl`의 지역 변수 `sunAngle`이 새 uniform을 가리지 않도록 `sunOrbitAngle`로 바꿨다.
- [x] README의 버퍼·용암 샘플 수·그림자 상태, AGENTS의 경로·버퍼 표, CHANGELOG를 갱신했다.

### 검증 기록

| 확인 항목 | 명령 또는 방법 | 결과 | 미실행·실패 이유 |
|---|---|---|---|
| bloom 결과 동일성 | 97×61 무작위 장면·용암 마스크에서 기존 단일 패스와 H/V 분리를 Python으로 비교 | 통과, 최대 차이 2.2e-16 | 게임의 RGBA16F 중간값 반올림은 포함하지 않음 |
| 읽기 수 | 코드 기준 집계 | bloom 관련 68회 → 24회(전달 3회 별도) | GPU 시간은 미측정 |
| 그림자 페이드 | 단순화한 해 경로(Minecraft의 천체 easing 무시)에서 기존·새 계수 비교 | 해·달 전환 시 0, 낮 1.0, 밤 0.42 확인. 이른 아침은 강해지고 일몰 전 1시간은 약해짐 | 실제 `sunAngle`·광원 방향은 런타임 확인 필요 |
| 정적 연결 | grep으로 include·DRAWBUFFERS·옵션 정의 일치·호출 인수·이전 함수 잔존 여부, 괄호 수 확인 | 통과 | 셰이더 컴파일 아님 |
| 형식 | `git diff --check` | 통과(LF/CRLF 안내만) | — |
| 게임 컴파일·화면·FPS | — | 미실행 | 이 PC에 Minecraft·Iris와 `glslangValidator`·`glslc`가 없음 |

### 남은 확인

- [ ] Iris/NeOculus에서 `composite1`과 `colortex4`가 정상 할당·컴파일되는지 로그로 확인한다.
- [ ] 용암·햇빛 bloom을 변경 전 커밋과 같은 장면에서 비교하고 FPS를 측정한다.
- [ ] 일출·일몰·달 전환 시점의 그림자 강도 변화와 낮은 광원의 줄무늬 그림자가 줄었는지 확인한다. 페이드 구간(0.02–0.20)은 이 비교 뒤 조정한다.
- composite의 colortex0/2/3 그대로 전달(읽기 3회·쓰기 3회)은 이번 범위에서 유지했다. 쓰지 않아도 값이 남는 로더 동작을 게임에서 확인한 뒤 제거를 검토한다.
