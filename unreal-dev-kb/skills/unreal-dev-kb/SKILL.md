---
name: unreal-dev-kb
description: UnrealEngine 셰이더/렌더링/머티리얼/이펙트/디버깅 작업 시 사용하는 지식 베이스. 약 2,000+ cvar/매크로/명령 카탈로그를 9개 영역(RDG, Shader Compiler, Material, Niagara, GPU 디버깅, Lumen/Nanite/RT/VSM, Profiling, Visualization, HLSL Custom Node)으로 정리. 사용자가 "셰이더", "머티리얼", "RDG", "Lumen", "Nanite", "Niagara", "RenderDoc", "PIX", "GPU 디버깅", "stat gpu", "ProfileGPU", "ShowFlag", "ViewMode", "Custom Node", "MaterialTemplate", "TangentToWorld", "RotateAboutAxis", "ConsoleVariables", "r.RDG", "r.Lumen", "r.Nanite", "fx.Niagara" 등 키워드로 질문하거나, UE 셰이더/렌더링 관련 cvar 추천을 요청할 때 자동으로 활성화. 시나리오별 cvar 셋 추천 + 정확한 cvar 이름/기본값/플래그 제공 가능.
license: MIT
---

# UnrealEngine 개발자 지식 베이스

## 목적

UnrealEngine으로 **셰이더, 렌더링, 머티리얼, 이펙트, GPU 디버깅** 작업 시 정확한 cvar/매크로/명령을 즉시 제공한다. 추정이 아닌 **소스 빌드 엔진에서 직접 추출**한 코드 기반 정보.

## 사용 흐름

사용자 질문이 UE 개발 관련일 때:

1. **`notes/INDEX.md`를 먼저 읽어 시나리오별 라우팅** 확인
2. 해당 영역 노트 (예: `notes/rdg-developer-reference.md`)의 **Part 1 (시나리오별 추천)** 참조
3. 정확한 cvar 정보가 필요하면 **Part 2 (전체 카탈로그)** 인용
4. 사용자에게 답할 때 cvar 이름은 **노트의 정보를 그대로** 사용 (추측 금지)

## 9개 영역 노트 위치

```text
notes/
├── INDEX.md                              ← 항상 먼저 읽기
├── rdg-developer-reference.md            (RDG cvar 31, 매크로 21)
├── shader-compiler-reference.md          (cvar 165)
├── material-reference.md                 (cvar 28)
├── niagara-reference.md                  (cvar 327)
├── gpu-debugging-reference.md            (cvar 48 + 명령 3)
├── rendering-pipeline-reference.md       (Lumen/Nanite/RT/VSM 핵심 180, 전체 705+)
├── profiling-reference.md                (stat 110 + cvar/명령 105)
├── visualization-reference.md            (ShowFlag 180 + ViewMode 36 + 기타 70)
└── hlsl-custom-node-reference.md         (멤버/함수/매크로 180)
```

## 시나리오 라우팅 (자주 발생하는 질문)

| 사용자 질문 패턴 | 참조 노트 |
|---|---|
| "RDG 패스 만드는데 죽음/aliasing/병렬" | `rdg-developer-reference.md` |
| "셰이더 컴파일 에러/DDC/PSO 캐싱" | `shader-compiler-reference.md` |
| "머티리얼 컴파일/번역기/품질레벨" | `material-reference.md` |
| "Niagara 이펙트 디버깅/Solo/GPU sim" | `niagara-reference.md` |
| "RenderDoc/PIX/RGP/DumpGPU/GPU 크래시" | `gpu-debugging-reference.md` |
| "Lumen GI/Nanite 메시/Ray Tracing/VSM" | `rendering-pipeline-reference.md` |
| "stat gpu/ProfileGPU/CSV/Insights/메모리" | `profiling-reference.md` |
| "GBuffer 시각화/ShowFlag/ViewMode/vis" | `visualization-reference.md` |
| "Custom Node/Parameters/RotateAboutAxis/MaterialTemplate" | `hlsl-custom-node-reference.md` |

## 검색 우선순위 (cvar 접두어로 빠르게)

| 접두어 | 노트 |
|---|---|
| `r.RDG.*` | rdg-developer |
| `r.Shaders.*`, `r.ShaderCompiler.*`, `r.Shader.*` | shader-compiler |
| `r.Material*`, `r.Materials.*` | material |
| `fx.Niagara.*`, `fx.NiagaraAllow*` | niagara |
| `r.Lumen.*`, `r.Nanite.*`, `r.RayTracing.*`, `r.Shadow.Virtual.*` | rendering-pipeline |
| `r.ProfileGPU.*`, `csv.*`, `Trace.*` | profiling |
| `renderdoc.*`, `r.DumpGPU.*`, `r.GPUCrashDebugging.*` | gpu-debugging |
| `r.Visualize*`, `r.BufferVisualization*`, `viewmode`, `vis` | visualization |

## 시스템 간 의존 관계 (자주 충돌)

답변 시 다음 의존성 명시:

1. **Lumen Hardware RT** ↔ `r.RayTracing=1` 필요 (꺼지면 SW RT 폴백)
2. **`r.RDG.ImmediateMode=1`** ↔ Insights 트레이스 자동 비활성
3. **`r.ShaderDevelopmentMode=1`** ↔ `r.ShowShaderCompilerWarnings` 무시
4. **RDG 디버그 cvar 다수** ↔ `RDG_ENABLE_DEBUG` 매크로 의존 (Shipping 무력화)
5. **Nanite ↔ VSM** 강하게 결합 (한쪽만 끄면 충돌)

## Custom Node 흔한 함정

```cpp
// ❌ struct/function 안에서 Parameters 직접 접근 불가
struct _Helper { float3 N() { return Parameters.TangentToWorld[2]; } };

// ✅ 인자로 전달
struct _Helper { float3 N(float3x3 TBN) { return TBN[2]; } };
```

## 응답 원칙

1. **추측 금지** — cvar 이름이 확실치 않으면 노트 검색 후 답변
2. **출처 명시** — 노트의 어느 Part를 참조했는지 짧게 언급
3. **시나리오 우선** — 단순 cvar 나열보다 "이 상황에는 이 셋"으로 묶어서 추천
4. **빌드 차이 주의** — Shipping/Test에서 무력화되는 cvar는 명시
5. **즉시 적용 가능** — 콘솔 명령(`~`) 또는 명령줄(`-ExecCmds=`) 형식으로 제공

## 적용 범위

이 지식은 **소스 빌드된 UnrealEngine 5.x**(`admin/source/repos/UnrealEngine/`)에서 추출. UE 5.7 기준이지만 5.x 전반에 대부분 적용. 일부 UE5 신규 기능(Lumen, Nanite, 신규 Material Translator)은 명시적으로 표기.

런처 설치판(`Program Files/Epic Games/UE_5.X/`)도 동일 cvar 사용 (엔진 같음). 다만 Shipping 빌드에서는 디버그 cvar 무력화.

## 갱신

엔진 업그레이드 시 (5.7 → 5.8 등) cvar 추가/제거 가능. 새 cvar 발견 시 해당 노트 업데이트 필요. INDEX.md의 통계도 갱신.
