# UnrealEngine 개발자 레퍼런스 인덱스

> 학습 일자: 2026-04-30
> 출처: `C:\Users\admin\source\repos\UnrealEngine\` (소스 빌드 엔진)
> 적용 범위: 이 엔진으로 여는 **모든 UE 프로젝트**

이 인덱스는 셰이더/렌더링/머티리얼/이펙트/디버깅 작업에 필요한 cvar, 매크로, 헬퍼 함수, 명령어를 영역별로 정리한 노트들의 마스터 인덱스입니다.

---

## 📊 전체 통계

| 영역 | 노트 파일 | 카탈로그 항목 |
|---|---|---|
| RDG (Render Dependency Graph) | [rdg-developer-reference.md](rdg-developer-reference.md) | cvar 31, 매크로 21 |
| Shader Compiler | [shader-compiler-reference.md](shader-compiler-reference.md) | cvar **165** |
| Material 시스템 | [material-reference.md](material-reference.md) | cvar **28** |
| Niagara FX | [niagara-reference.md](niagara-reference.md) | cvar **327** |
| GPU 디버깅 (RenderDoc/PIX/RGP/DumpGPU) | [gpu-debugging-reference.md](gpu-debugging-reference.md) | cvar 48, 명령 3 |
| 렌더링 파이프라인 (Lumen/Nanite/RT/VSM) | [rendering-pipeline-reference.md](rendering-pipeline-reference.md) | 핵심 ~180 (전체 705+) |
| Profiling / Stats | [profiling-reference.md](profiling-reference.md) | stat 110, cvar/명령 105 |
| Visualization / Debug View | [visualization-reference.md](visualization-reference.md) | ShowFlag 180, ViewMode 36, 기타 70 |
| HLSL Custom Node 작성 | [hlsl-custom-node-reference.md](hlsl-custom-node-reference.md) | 멤버/함수/매크로 ~180 |
| **합계** | 9개 노트 | **약 2,000+ 항목** |

---

## 🎯 시나리오별 빠른 라우팅

작업 상황별로 **어느 노트를 봐야 하는지** 안내:

### "셰이더 컴파일 에러 뜸"
→ [shader-compiler-reference.md](shader-compiler-reference.md) Part 1.2 (컴파일 에러 디버깅)
→ 추가: `r.ShaderDevelopmentMode=1`, `r.DumpShaderDebugInfo=3`

### "셰이더 변경했는데 반영 안 됨"
→ [shader-compiler-reference.md](shader-compiler-reference.md) Part 1.4 (DDC 문제)
→ `recompileshaders changed` 명령

### "머티리얼 컴파일 무한 루프"
→ [material-reference.md](material-reference.md) Part 1.1 (머티리얼 컴파일 디버깅)
→ `r.Material.Translator.DebugDump=2`

### "Custom Node 작성 중"
→ [hlsl-custom-node-reference.md](hlsl-custom-node-reference.md) 전체
→ `Parameters.TangentToWorld[2]`, `RotateAboutAxis` 등

### "RDG 패스 만드는데 죽음"
→ [rdg-developer-reference.md](rdg-developer-reference.md) Part 1.1 (패스 크래시 디버깅)
→ `r.RDG.ImmediateMode=1`, `r.RDG.ClobberResources=2`

### "GBuffer 채널 보고 싶음"
→ [visualization-reference.md](visualization-reference.md) Part 5 (BufferVisualization)
→ `viewmode buffervisualization basecolor` 등

### "Lumen GI 디버깅"
→ [rendering-pipeline-reference.md](rendering-pipeline-reference.md) Part 2 (Lumen)
→ + [visualization-reference.md](visualization-reference.md) Part 6 (Lumen Visualize)

### "Nanite 메시 분석"
→ [rendering-pipeline-reference.md](rendering-pipeline-reference.md) Part 3 (Nanite)
→ + [visualization-reference.md](visualization-reference.md) Part 6 (Nanite Visualize)

### "GPU 비용 측정"
→ [profiling-reference.md](profiling-reference.md) Part 1.2 (GPU 패스 비용)
→ `stat gpu`, `profilegpu`

### "프레임 캡처 (RenderDoc)"
→ [gpu-debugging-reference.md](gpu-debugging-reference.md) Part 1.1 (RenderDoc 워크플로우)
→ `renderdoc.CaptureFrame`

### "GPU 크래시 추적"
→ [gpu-debugging-reference.md](gpu-debugging-reference.md) Part 2 (GPU Crash)
→ `r.GPUCrashDebugging=1`, `-aftermath`

### "Niagara 이펙트 디버깅"
→ [niagara-reference.md](niagara-reference.md) Part 1.1 (Solo 모드)
→ `fx.Niagara.Debug.Hud`

### "메모리 누수 추적"
→ [profiling-reference.md](profiling-reference.md) Part 1.3 (메모리)
→ `memreport`, `stat memory`

### "Insights 트레이스"
→ [profiling-reference.md](profiling-reference.md) Part 1.6 (Insights)
→ + [rdg-developer-reference.md](rdg-developer-reference.md) Part 6 (RDG Trace)

---

## 🔍 검색 가이드 (cvar 접두어로 찾기)

| 접두어 | 영역 | 노트 |
|---|---|---|
| `r.RDG.*` | Render Dependency Graph | rdg-developer |
| `r.Shaders.*`, `r.ShaderCompiler.*` | 셰이더 컴파일 | shader-compiler |
| `r.Shader.*`, `r.DumpShaderDebugInfo*` | 셰이더 디버그 | shader-compiler |
| `r.Material*`, `r.Materials.*` | 머티리얼 | material |
| `r.Material.Translator.*` | 신규 IR 번역기 | material |
| `fx.Niagara.*` | Niagara | niagara |
| `fx.NiagaraAllow*`, `fx.SkipVectorVM*` | Niagara 토글 | niagara |
| `r.Lumen.*` | Lumen GI | rendering-pipeline |
| `r.Nanite.*` | Nanite | rendering-pipeline |
| `r.RayTracing.*` | Ray Tracing | rendering-pipeline |
| `r.Shadow.Virtual.*` | Virtual Shadow Map | rendering-pipeline |
| `renderdoc.*` | RenderDoc 통합 | gpu-debugging |
| `r.DumpGPU.*` | DumpGPU 명령 | gpu-debugging |
| `r.GPUCrashDebugging.*` | GPU Crash | gpu-debugging |
| `r.ProfileGPU.*` | GPU 프로파일 | profiling |
| `csv.*` | CSV Profiler | profiling |
| `Trace.*` | Insights Trace | profiling |
| `r.Visualize*`, `r.BufferVisualization*` | 시각화 | visualization |
| `viewmode *`, `vis *` | 디버그 뷰 | visualization |
| `showflag.*` | ShowFlag | visualization |

---

## 📐 매크로 / 헬퍼 함수 검색

| 무엇을 찾는가 | 노트 위치 |
|---|---|
| `RDG_EVENT_SCOPE`, `RDG_GPU_STAT_SCOPE` | rdg-developer Part 4 |
| `RDG_ENABLE_DEBUG`, `RDG_EVENTS` | rdg-developer Part 3 |
| `Parameters.TangentToWorld[2]` 같은 멤버 | hlsl-custom-node Part 2-3 |
| `RotateAboutAxis`, `TransformWorldVectorToTangent` | hlsl-custom-node Part 4 |
| `MATERIAL_SHADINGMODEL_*`, `MATERIALBLENDING_*` | hlsl-custom-node Part 5 |
| `View.GameTime`, `ResolvedView.WorldToView` | hlsl-custom-node Part 6 |
| `Square()`, `Pow2()`, sRGB 변환 | hlsl-custom-node Part 7 |
| `SHOWFLAG_*` 매크로 등록 | visualization Part 4 |
| `VMI_*` ViewMode enum | visualization Part 3 |
| `STATGROUP_*` stat 그룹 | profiling Part 2 |
| `FMaterialPixelParameters` 전체 멤버 | hlsl-custom-node Part 2 |

---

## ⚠️ 시스템 간 충돌 / 의존 관계

여러 영역에 걸친 **상호작용 주의점**:

### Lumen ↔ Ray Tracing
- Lumen Hardware RT 모드는 `r.RayTracing=1` 필요
- 꺼져 있으면 자동 SW RT 폴백
- → [rendering-pipeline-reference.md](rendering-pipeline-reference.md) Part 7

### Nanite ↔ Virtual Shadow Map
- VSM은 Nanite와 강하게 결합 — 한쪽만 끄면 동작 이상 가능
- 셰이더 작업자가 자주 충돌하는 영역
- 관련: `r.Shadow.Virtual.Cache.DeformableMeshesInvalidate`, `r.Nanite.VSMInvalidateOnLODDelta`
- → [rendering-pipeline-reference.md](rendering-pipeline-reference.md) Part 7

### RDG ImmediateMode ↔ Insights
- `r.RDG.ImmediateMode=1`이면 Insights 트레이스 자동 비활성
- → [rdg-developer-reference.md](rdg-developer-reference.md) Part 8

### ShaderDevelopmentMode ↔ ShowShaderCompilerWarnings
- `r.ShaderDevelopmentMode=1` 시 `r.ShowShaderCompilerWarnings` 무시됨
- → [shader-compiler-reference.md](shader-compiler-reference.md)

### 셰이더 디버그 cvar ↔ Shipping 빌드
- `r.RDG.Validation`, `r.RDG.Debug.*` 등 디버그 cvar 다수가 `RDG_ENABLE_DEBUG` 매크로에 의존
- Shipping/Test 빌드에서는 빌드 타임에 무력화됨
- → [rdg-developer-reference.md](rdg-developer-reference.md) Part 3

---

## 🛠 Custom Node에서 함수/struct 선언 시 주의

**⚠️ 흔한 함정**: Custom 노드 안에서 `struct` 또는 `function`을 선언하면, 그 안에서 `Parameters`에 접근 불가.

```cpp
// ❌ 컴파일 에러
struct _Helper
{
    float3 GetNormal() { return Parameters.TangentToWorld[2]; }  // Parameters 참조 불가
};

// ✅ 인자로 전달
struct _Helper
{
    float3 GetNormal(float3x3 TBN) { return TBN[2]; }
};

// ✅ 또는 인라인
float3 N = Parameters.TangentToWorld[2];
```

→ [hlsl-custom-node-reference.md](hlsl-custom-node-reference.md) Part 10 (흔한 함정)

---

## 📚 추가 학습 영역 (필요 시 요청)

본 인덱스에 포함되지 않은, 향후 학습 가능한 영역:

- **Post Process**: `r.PostProcess.*`, Tonemapper, Bloom, DoF
- **Anti-Aliasing**: TAA, TSR, DLSS, FSR, MSAA
- **Foliage / Landscape**: 폴리지, 랜드스케이프 cvar
- **Streaming**: 텍스처/메시 스트리밍 cvar
- **Audio**: 오디오 시스템 cvar
- **Animation**: 애니메이션 시스템 cvar
- **Physics (Chaos)**: Chaos cvar
- **Networking**: 네트워크 cvar
- **Editor Performance**: 에디터 성능 튜닝 cvar
- **Build Pipeline**: 쿠킹/패키징 cvar

각 영역은 동일 패턴(cvar 추출 + 시나리오별 추천 + 카테고리화)으로 학습 가능.

---

## 🗂 노트 파일 검증 (체크리스트)

| 노트 | 존재 | 시나리오 가이드 | 전체 카탈로그 |
|---|---|---|---|
| rdg-developer-reference.md | ✅ | ✅ Part 1 | ✅ Part 2 |
| shader-compiler-reference.md | ✅ | ✅ | ✅ |
| material-reference.md | ✅ | ✅ | ✅ |
| niagara-reference.md | ✅ | ✅ | ✅ |
| gpu-debugging-reference.md | ✅ | ✅ | ✅ |
| rendering-pipeline-reference.md | ✅ | ✅ | ✅ (선별) |
| profiling-reference.md | ✅ | ✅ | ✅ |
| visualization-reference.md | ✅ | ✅ | ✅ |
| hlsl-custom-node-reference.md | ✅ | ✅ | ✅ |

---

## 🔄 갱신 정책

- 엔진 버전 업그레이드 (예: 5.7 → 5.8) 시 전체 재학습 권장
- cvar 이름이 자주 바뀌므로 **추정하지 말고** 노트 → 코드 순으로 검증
- 노트 작성 시점의 엔진 커밋: 사용자 머신의 `C:\Users\admin\source\repos\UnrealEngine\` 현재 상태 (소스 빌드)
