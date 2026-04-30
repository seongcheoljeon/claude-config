# UnrealEngine RDG 개발자 레퍼런스

> 출처: `C:\Users\admin\source\repos\UnrealEngine\Engine\Source\Runtime\RenderCore\` (소스 빌드 엔진)
> 적용 범위: 이 엔진으로 여는 모든 UE 프로젝트
> 작성일: 2026-04-30
> 검증: 엔진 소스 코드 직접 추출 (cvar 31개 + 매크로 21개)

---

## Part 1: 시나리오별 cvar 추천 (빠른 참조)

### 1.1 패스 크래시 디버깅 (lambda 안에서 죽음)

```ini
r.RDG.ImmediateMode=1          ; 패스 즉시 실행 → 콜스택 보존
r.RDG.Validation=1             ; (기본값) API 오용/의존성 오류 검출
r.RDG.ClobberResources=2       ; 리소스를 NaN으로 채움 → 미초기화 데이터 검출
r.RDG.Debug.FlushGPU=1         ; 매 패스 후 GPU sync (async/parallel 자동 OFF)
r.RDG.TransitionLog=1          ; 리소스 상태 전이 로그
```

**복구 전 끄기**:
```ini
r.RDG.ImmediateMode=0
r.RDG.ClobberResources=0
r.RDG.Debug.FlushGPU=0
r.RDG.TransitionLog=0
```

### 1.2 Transient 리소스 / Aliasing 버그

```ini
r.RDG.Debug.ExtendResourceLifetimes=1     ; 리소스 라이프타임 강제 확장 (메모리 별칭 방지)
r.RDG.Debug.ResourceFilter="MyTexture"    ; 특정 리소스만 디버깅 대상
r.RDG.Debug.DisableTransientResources=1   ; transient allocator 우회
r.RDG.TransientAllocator=0                ; transient allocator 자체 OFF
r.RDG.AsyncComputeTransientAliasing=0     ; cross-queue aliasing OFF
```

### 1.3 GPU 디버거 (RenderDoc / PIX) 캡처 시

```ini
r.RDG.Events=2                 ; 모든 이벤트 + RDG_EVENT_SCOPE_FINAL 무시
; 또는
r.RDG.Events=3                 ; + RDG 패스 이름까지 표시 (가장 상세)

; (다른 cvar이지만 함께 켤 것)
r.Shaders.ExtraData=1          ; 셰이더 이름 표시
r.Shaders.Symbols=1            ; 셰이더 심볼/PDB
```

### 1.4 패스 병렬 실행 디버깅

```ini
r.RDG.ParallelExecuteStress=1  ; 패스마다 task 1개 → 강제 최대 병렬 + render pass 병합 OFF
r.RDG.ParallelExecute=0        ; 병렬 실행 끔 (기본값 2)
r.RDG.AsyncCompute=0           ; async compute 끔 (기본값 1)
r.RDG.ParallelSetup=0          ; 병렬 setup 끔
r.RDG.ParallelCompile=0        ; 병렬 compile 끔
```

### 1.5 성능 측정 / 프로파일링

```ini
r.RDG.VerboseCSVStats=1        ; 단계별 CSV 통계 (compile/setup/execute 분리)
r.RDG.CullPasses=0             ; pass culling 끔 (실제 부하 측정)
r.RDG.MergeRenderPasses=0      ; render pass 병합 끔
```

### 1.6 Unreal Insights 트레이스

```ini
r.RDG.ImmediateMode=0          ; 필수! ImmediateMode면 트레이스 자동 비활성화
; + Insights 실행 후 "RDGChannel" 트레이스 채널 활성화
```

### 1.7 특정 그래프/패스만 격리해서 보기

```ini
r.RDG.Debug.GraphFilter="MyGraphName"     ; 특정 그래프 이름
r.RDG.Debug.PassFilter="PostProcess*"     ; 패스 이름 패턴
r.RDG.Debug.ResourceFilter="SceneColor"   ; 리소스 이름 패턴
```

→ 위 cvar들은 **다른 디버그 옵션과 결합**해서 노이즈 줄이는 용도. 단독으로는 효과 없음.

---

## Part 2: cvar 전체 카탈로그 (31개)

모든 cvar는 `RenderGraphPrivate.cpp`에 정의됨. 위치는 줄 번호.

### Validation
| cvar | 기본값 | 설명 |
|---|---|---|
| `r.RDG.Validation` | 1 | API 오용 / 패스 매개변수 의존성 검증 |
| `r.RDG.Debug.DisableTransientResources` | 0 | transient allocator에서 리소스 제외 |

### Debugging
| cvar | 기본값 | 설명 |
|---|---|---|
| `r.RDG.ImmediateMode` | 0 | 패스를 생성 즉시 실행 (lambda 콜스택 보존) |
| `r.RDG.Debug.FlushGPU` | 0 | 매 패스 후 GPU sync. async/parallel 자동 비활성 |
| `r.RDG.Debug.ExtendResourceLifetimes` | 0 | 리소스 라이프타임 확장 → 별칭 방지 |
| `r.RDG.ClobberResources` | 0 | 1=1000, 2=NaN, 3=+INF로 채움 (ECVF_Cheat) |
| `r.RDG.Debug.GraphFilter` | "" | 특정 그래프만 디버그 |
| `r.RDG.Debug.PassFilter` | "" | 특정 패스만 디버그 |
| `r.RDG.Debug.ResourceFilter` | "" | 특정 리소스만 디버그 |

### Events / Tracing
| cvar | 기본값 | 설명 |
|---|---|---|
| `r.RDG.Events` | 1 | 0=off, 1=기본, 2=FINAL 무시, 3=패스 이름 포함 |
| `r.RDG.TransitionLog` | 0 | >0=N프레임, <0=무한, 0=off |

### Performance & Optimization
| cvar | 기본값 | 설명 |
|---|---|---|
| `r.RDG.AsyncCompute` | 1 | 0=off, 1=태그된 패스만, 2=모든 compute 패스 |
| `r.RDG.CullPasses` | 1 | 사용 안 되는 출력의 패스 제거 |
| `r.RDG.MergeRenderPasses` | 1 | 동일 연속 render pass 병합 |
| `r.RDG.OverlapUAVs` | 1 | UAV 작업 겹침 허용 (없으면 항상 barrier) |

### Memory & Resource
| cvar | 기본값 | 설명 |
|---|---|---|
| `r.RDG.TransientAllocator` | 1 | 0=off, 1=on, 2=FastVRAM만 |
| `r.RDG.TransientExtractedResources` | 1 | 0=off, 1=on, 2=강제 (비추) |
| `r.RDG.AsyncComputeTransientAliasing` | 1 | 그래픽스/컴퓨트 큐 메모리 별칭 (fence 사용) |
| `r.RDG.TransientAllocator.IndirectArgumentBuffers` | 0 | indirect argument 버퍼의 transient 사용 (UE-115982 회피) |

### Parallel Execution
| cvar | 기본값 | 설명 |
|---|---|---|
| `r.RDG.ParallelDestruction` | 1 | 그래프 정리를 async task로 |
| `r.RDG.ParallelSetup` | 1 | AddSetupTask 병렬 |
| `r.RDG.ParallelCompile` | 1 | 그래프 컴파일 병렬 |
| `r.RDG.AsyncSetupQueue` | 1 | FlushSetupQueue 호출 시 패스 setup 병렬 |
| `r.RDG.ParallelSetup.TaskPriorityBias` | 1 | setup task 우선순위 bias |
| `r.RDG.ParallelExecute` | 2 | 0=off, 1=await, 2=async (기본) |
| `r.RDG.ParallelExecute.PassMin` | 1 | 병렬 실행 최소 패스 묶음 크기 |
| `r.RDG.ParallelExecute.PassMax` | 32 | 최대 패스 묶음 크기 |
| `r.RDG.ParallelExecute.PassTaskModeThreshold` | 2 | task mode 불일치 시 batch flush 정책 |
| `r.RDG.ParallelExecuteStress` | 0 | stress test: 패스당 task 1개 + render pass 병합 OFF |
| `r.RDG.ParallelMobile` | 0 | 모바일 렌더러 병렬 실행 |

### Diagnostics
| cvar | 기본값 | 설명 |
|---|---|---|
| `r.RDG.VerboseCSVStats` | 0 | 0=실행 단위, 1=phase별 CSV 통계 |

---

## Part 3: 컴파일 시간 매크로 (9개)

`RenderGraphDefinitions.h`에 정의됨. **빌드 타입에 따라 cvar 동작이 달라지는 핵심**.

### 빌드별 활성화 매트릭스

| 매크로 | Development | Debug | Test | Shipping |
|---|---|---|---|---|
| `RDG_ENABLE_DEBUG` | ✅ | ✅ | ❌ | ❌ |
| `RDG_ENABLE_TRACE` | ✅ | ✅ | ❌ | ❌ |
| `RDG_DUMP_RESOURCES` | WITH_DUMPGPU 조건 | WITH_DUMPGPU 조건 | ❌ | ❌ |
| `RDG_EVENTS` | STRING_COPY (2) | STRING_COPY (2) | STRING_REF (1) | STRING_REF (1) |
| `SUPPORTS_VISUALIZE_TEXTURE` | ✅ | ✅ | WITH_EDITOR 시 | ❌ |

### 핵심 매크로 상세

**`RDG_ENABLE_DEBUG`**
- 정의: `(!UE_BUILD_SHIPPING && !UE_BUILD_TEST)`
- **이게 OFF면 거의 모든 디버그 cvar가 무력화됨**
- 영향 받는 cvar: `r.RDG.Validation`, `r.RDG.Debug.*`, `r.RDG.ClobberResources`, `r.RDG.ImmediateMode`, `r.RDG.TransitionLog`

**`RDG_ENABLE_TRACE`**
- 정의: `UE_TRACE_ENABLED && !IS_PROGRAM && !UE_BUILD_SHIPPING`
- Insights 통합. 이 매크로가 OFF면 RDGChannel 데이터 안 나옴
- 추가 조건: `r.RDG.ImmediateMode=0` 이어야 트레이스 작동

**`RDG_EVENTS` (값 3종)**
```cpp
RDG_EVENTS_NONE        = 0  // 이벤트 처리 안 함 (성능 최적)
RDG_EVENTS_STRING_REF  = 1  // 상수 TCHAR* 참조만 저장
RDG_EVENTS_STRING_COPY = 2  // FString으로 포매팅 (가장 풍부)
```
- Development: 자동 STRING_COPY
- Test/Shipping: STRING_REF (`WITH_PROFILEGPU || WITH_RHI_BREADCRUMBS` 시)

**`RDG_DUMP_RESOURCES`**
- 정의: `(WITH_DUMPGPU)`
- DumpGPU 명령으로 프레임 내 모든 RDG 리소스 메모리/라이프타임 덤프

### IF_RDG_* 헬퍼 매크로
```cpp
IF_RDG_ENABLE_DEBUG(SomeDebugCode);  // RDG_ENABLE_DEBUG ON일 때만 컴파일
IF_RDG_ENABLE_TRACE(SomeTraceCode);  // RDG_ENABLE_TRACE ON일 때만 컴파일
```

---

## Part 4: 패스 작성 매크로 (12개)

RDG 패스 작성 시 직접 호출하는 매크로. `RenderGraphEvent.h`에 정의됨.

### 4.1 이벤트 이름 / 스코프

```cpp
// 패스 이름 생성 (포맷 지원)
FRDGEventName Name = RDG_EVENT_NAME("PostProcess %dx%d", W, H);
GraphBuilder.AddPass(Name, ...);

// 스코프: GPU 디버거에서 그룹으로 표시
RDG_EVENT_SCOPE(GraphBuilder, "TonemappingPass");

// 조건부 스코프
RDG_EVENT_SCOPE_CONDITIONAL(GraphBuilder, bDebugMode, "DebugDrawPass");

// 자식 스코프 비활성화 (병합)
RDG_EVENT_SCOPE_FINAL(GraphBuilder, "MergedPasses");

// 이미 만든 EventName 재사용
RDG_EVENT_SCOPE_CONDITIONAL_NAME(GraphBuilder, bShow, ExistingEventName);
```

### 4.2 GPU 통계 (Legacy GPU profiler)

```cpp
// 통계 + 이벤트 함께
RDG_EVENT_SCOPE_STAT(GraphBuilder, MyPassStat, "MyPass");

// 통계만
RDG_GPU_STAT_SCOPE(GraphBuilder, MyPassStat);

// 통계 + 설명
RDG_GPU_STAT_SCOPE_VERBOSE(GraphBuilder, MyPassStat, TEXT("Description"));
```

> 활성 조건: `HAS_GPU_STATS && (RHI_NEW_GPU_PROFILER == 0)`

### 4.3 CSV 프로파일러

```cpp
// 배타적 스코프 (다른 통계와 시간 누적 분리)
RDG_CSV_STAT_EXCLUSIVE_SCOPE(GraphBuilder, "Lighting");
```

> 활성 조건: `CSV_PROFILER_STATS`

### 4.4 RDG + RHI 복합

```cpp
// RDG 타임라인 + RHI 타임라인 양쪽에 이벤트
RDG_RHI_EVENT_SCOPE(GraphBuilder, "MyPass");

// + 통계까지
RDG_RHI_EVENT_SCOPE_STAT(GraphBuilder, MyPassStat, "MyPass");
RDG_RHI_GPU_STAT_SCOPE(GraphBuilder, MyPassStat);
```

### 4.5 RHI 직접 접근 (비추, 필요 시만)

```cpp
{
    RDG_ALLOW_RHI_ACCESS_SCOPE();
    // 이 스코프 내에서는 RHI 리소스 직접 접근 가능
    // 일반적으로는 RDG 추적을 우회하므로 비권장
    SomeRHIDirectCall();
}
```

---

## Part 5: Validation 시스템

### `FRDGUserValidation` 클래스
위치: `RenderGraphValidation.cpp`

**검증 메서드들** (개발자가 직접 호출하지는 않지만, 동작 이해용):
- `ValidateCreateResource()` — 리소스 생성 검증
- `ValidateCreateTexture()` / `ValidateCreateBuffer()` — 텍스처/버퍼 검증
- `ValidateCreateSRV()` / `ValidateCreateUAV()` — 뷰 검증
- `ExecuteGuard()` — 그래프 실행 전 강제

### `RDG_ENABLE_DEBUG` 조건부 extern 변수

```cpp
extern int32 GRDGAsyncCompute;
extern int32 GRDGClobberResources;
extern int32 GRDGValidation;
extern int32 GRDGDebugFlushGPU;
extern int32 GRDGDebugExtendResourceLifetimes;
extern int32 GRDGTransitionLog;
extern int32 GRDGImmediateMode;
extern int32 GRDGOverlapUAVs;
extern bool  GRDGAllowRHIAccess;
extern bool  GRDGAllowRHIAccessAsync;
```

C++ 코드에서 직접 참조 가능 (Shipping 빌드에서는 컴파일 자체가 안 됨).

---

## Part 6: 트레이스 시스템 (Insights)

### 트레이스 채널
- 채널 이름: **`RDGChannel`**
- 정의: `RenderGraphTrace.cpp` (UE_TRACE_CHANNEL_DEFINE)

### 활성화 조건
1. 빌드: `RDG_ENABLE_TRACE` 매크로 ON (Development/Debug)
2. cvar: `r.RDG.ImmediateMode=0` (필수)
3. Insights에서: `RDGChannel` 트레이스 채널 활성화

### 추적되는 이벤트
| 이벤트 | 정보 |
|---|---|
| `RDGTrace::GraphMessage` | 그래프 시작/종료, 패스 수, 메모리 |
| `RDGTrace::PassMessage` | 패스 이름, 플래그, 파이프라인, 리소스 |
| `RDGTrace::TextureMessage` | 텍스처 할당/수명 |
| `RDGTrace::BufferMessage` | 버퍼 할당/수명 |
| `RDGTrace::ScopeMessage` | 이벤트 스코프 계층 |

### 활성화 명령 (Insights 연결 시)
```text
Trace.Enable RDGChannel
```

---

## Part 7: 빌드별 권장 설정

### Development 빌드 (셰이더/렌더링 작업 중)
```ini
r.RDG.Validation=1                       ; 기본값
r.RDG.Events=1                           ; 기본값
; 디버깅 시에만 일시 활성화:
;r.RDG.ImmediateMode=1
;r.RDG.ClobberResources=2
;r.RDG.TransitionLog=1
```

### Shipping 빌드
- 모든 디버그 cvar는 빌드 타임에 무력화됨
- 성능 cvar (CullPasses, MergeRenderPasses, AsyncCompute)는 그대로 작동
- 변경하지 말 것 (성능 저하)

### Profile 빌드 (GPU 캡처용)
```ini
r.RDG.Events=3                           ; 가장 상세한 이벤트
r.RDG.AsyncCompute=0                     ; 단순화 (캡처 분석 쉬움)
r.RDG.ParallelExecute=0                  ; 병렬 끔 (타임라인 단순)
```

---

## Part 8: 자주 헷갈리는 점

### 8.1 `r.RDG.ImmediateMode` vs `r.RDG.Debug.FlushGPU`
| 항목 | ImmediateMode | FlushGPU |
|---|---|---|
| 패스 실행 시점 | 즉시 (lambda 호출 시) | 정상 (그래프 빌드 후) |
| GPU sync | ❌ | ✅ 매 패스 후 |
| 콜스택 보존 | ✅ | ❌ |
| Insights 트레이스 | ❌ 비활성화됨 | ✅ |
| 사용 목적 | C++ 크래시 디버깅 | GPU 동작 단계 추적 |

### 8.2 `r.RDG.Events`의 모드별 차이
- 0: 이벤트 시스템 OFF (오버헤드 최소)
- 1: 기본. 코드에서 `RDG_EVENT_SCOPE_FINAL` 사용한 곳은 자식 이벤트 안 보임
- 2: `RDG_EVENT_SCOPE_FINAL` 무시 → 모든 자식 이벤트 표시
- 3: 2 + RDG 내부 패스 이름까지 표시 (가장 자세함)

### 8.3 `r.RDG.OverlapUAVs=0`은 디버깅용 아님
- 이건 **퍼포먼스/안정성** 옵션. UAV 작업 사이에 항상 barrier 삽입
- UAV race condition 의심 시 사용
- 디버깅 후 다시 1로 복귀 필요

### 8.4 `RDG_EVENT_NAME`의 가변인자 최적화
```cpp
// 가변인자 없으면 Snprintf 스킵 → 거의 무비용
RDG_EVENT_NAME("StaticName");

// 가변인자 있으면 RDG_EVENTS == STRING_COPY 일 때만 포매팅
RDG_EVENT_NAME("Pass %d", Index);
```

---

## Part 9: cvar 응급 처치 (검증 명령)

에디터 콘솔(`~`)에서 즉시 확인:

```text
; 현재 값 확인
r.RDG.Validation
r.RDG.ImmediateMode

; 일시 변경 (다음 재시작 시 ConsoleVariables.ini 값으로 복귀)
r.RDG.ImmediateMode 1

; 모든 RDG cvar 보기
help r.RDG
```

명령줄로 시작 시 적용:
```text
UnrealEditor.exe MyProject -ExecCmds="r.RDG.ImmediateMode 1, r.RDG.ClobberResources 2"
```

---

## Part 10: 추가 학습이 필요한 영역

본 문서는 **cvar/매크로 카탈로그**에 집중. RDG 자체의 깊은 이해를 위해 추가 학습할 항목:

1. **RDG 패스 작성 패턴**: `BEGIN_SHADER_PARAMETER_STRUCT`, `AddPass` 람다 캡처 규칙
2. **리소스 라이프타임**: extracted vs transient, RegisterExternal vs CreateXxx
3. **PassFlags**: `ERDGPassFlags::Compute`, `Raster`, `AsyncCompute` 등
4. **Resource States**: `ERHIAccess::*` 종류와 자동 transition
5. **Async Compute**: `RDG_ASYNC_COMPUTE_*` 상수와 fence 메커니즘

이 항목들은 cvar로는 다룰 수 없는 RDG 자체의 설계. 별도 학습 권장.

---

## 부록: 관련 엔진 파일 위치

```text
Engine/Source/Runtime/RenderCore/
  Private/
    RenderGraphPrivate.cpp       ← cvar 31개 모두 정의
    RenderGraphPrivate.h         ← 매크로 + extern 변수
    RenderGraphValidation.cpp    ← 검증 시스템
    RenderGraphTrace.cpp         ← Insights 연동
    RenderGraphBuilder.cpp       ← 그래프 빌드 로직
    RenderGraphPass.cpp          ← 패스 실행
  Public/
    RenderGraphDefinitions.h     ← 컴파일 시간 매크로
    RenderGraphEvent.h           ← 패스 작성용 매크로
    RenderGraphBuilder.h         ← 패스 작성 API
    RenderGraph.h                ← 메인 헤더
```
