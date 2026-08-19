# RDG 디버깅 & Profiling

## 콘솔 변수 (CVar)

```
r.RDG.Debug 1               — Pass 목록, 리소스 정보 출력
r.RDG.Debug.GraphFilter     — 특정 패스 이름 필터링
r.RDG.Breakpoint 1          — 패스 실행 전 중단점 (디버거 필요)
r.RDG.ClobberResources 1    — 리소스를 더미 값으로 초기화 (미초기화 감지)
r.RDG.OverlapUAVs 0         — UAV 오버랩 비활성화 (동기화 문제 디버깅)
r.RDG.ImmediateMode 1       — Deferred 비활성화, 즉시 실행 (디버깅 전용)
r.RDG.TransientResourceCache 0 — Transient 비활성화 (메모리 추적)
r.RDG.VerboseCSVStats 1     — CSV 통계 상세 출력
```

## RDG ImmediateMode

```
r.RDG.ImmediateMode 1
```

- `AddPass()` 즉시 GPU 커맨드 발행.
- Deferred 모델 관련 버그(Culling, 수명 등) 격리에 유용.
- **성능 저하 심함** — 디버깅 전용.

## GPU Insights / RenderDoc 연동

```cpp
// RDG 이벤트는 GPU Insights에서 계층 구조로 표시
// RDG_EVENT_NAME 으로 명명한 이름이 그대로 GPU Capture에 나타남

RDG_EVENT_SCOPE(GraphBuilder, "MyPlugin");
    AddMyComputePass(GraphBuilder, ...);
    AddMyRasterPass(GraphBuilder, ...);
// 스코프 종료 → RenderDoc에서 "MyPlugin" 그룹으로 묶임
```

## Pass Culling 디버깅

패스가 실행 안 될 때:

1. `ERDGPassFlags::NeverCull` 임시 추가:
```cpp
GraphBuilder.AddPass(
    RDG_EVENT_NAME("Test"),
    Parameters,
    ERDGPassFlags::Compute | ERDGPassFlags::NeverCull,  // ← 추가
    ...
);
```

2. Output 리소스가 `QueueTextureExtraction` 되어 있는지 확인.
3. `r.RDG.Debug 1` 로 그래프 덤프 출력.

## 흔한 크래시 원인

| 증상 | 원인 | 해결 |
|------|------|------|
| Crash in Execute | Lambda에서 FRDGTextureRef 접근 | `->GetRHI()` 사용 |
| UAV Barrier 없음 | 같은 리소스 Write→Read 순서 오류 | RDG가 자동처리, 파라미터 선언 확인 |
| NULL RHI 포인터 | Execute() 전에 Extracted 리소스 접근 | Execute 이후로 이동 |
| Shader Compile Error | USF 경로 미등록 | `AddShaderSourceDirectoryMapping` 확인 |
| Pass가 실행 안 됨 | Pass Culling | `NeverCull` 추가 또는 Extract 확인 |

## Stat 명령어

```
stat RDG           — RDG 전체 시간
stat RDGMemory     — 메모리 사용량
stat GPU           — GPU Pass 별 시간 (Unreal Insights)
```

## Unreal Insights 설정

```cpp
// 코드에서 Trace 추가
TRACE_CPUPROFILER_EVENT_SCOPE(MyPlugin_RDGPass);
```

```
// 실행 시 인자
-trace=rdg,gpu,cpu,frame
```

## Validation Layer (개발 빌드)

UE5 개발 빌드에서 RDG Validation 자동 활성화:
- 잘못된 리소스 상태 전환 감지
- 사용되지 않는 Parameters 경고
- UAV 충돌 감지

```
r.RDG.Validation 1   — 명시적 활성화 (기본: 개발 빌드에서 ON)
```
