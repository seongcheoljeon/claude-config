# 디버깅 완전 가이드 (공식 문서 기반)
> 출처: UE5.7 공식 문서 — 디버깅 및 유효성 검사 섹션 전체

---

## 즉시 모드 (Immediate Mode)

`AddPass` 호출 시점에 즉시 실행 → 그래프 컴파일 우회.
디퍼드 모델에서 발생하는 크래시의 정확한 발생 위치 추적 가능.

| 활성화 방법 | 명령 |
|-------------|------|
| 콘솔 변수 | `r.RDG.ImmediateMode 1` |
| 명령줄 인자 | `-rdgimmediate` |

```
r.RHICmdBypass 1   ← 병렬 렌더링 + 소프트웨어 명령 목록 비활성화
```

> **즉시 모드 + r.RHICmdBypass** 조합 = 모든 연기 메커니즘 제거 → 단일 콜 스택으로 디버깅

> 부작용: 일시적 할당, 그래프 컬링, 렌더 패스 병합 등 **모든 그래프 최적화 비활성화**.

---

## 기능별 개별 CVar (즉시 모드 없이)

| 변수 | 설명 |
|------|------|
| `r.RDG.CullPasses 0` | 패스 컬링 비활성화 |
| `r.RDG.MergeRenderPasses 0` | 렌더 패스 병합 비활성화 (RDG 래스터 패스당 고유 렌더 패스 사용) |
| `r.RDG.ParallelExecute 0` | 병렬 실행 비활성화 (렌더 스레드에서 연속 실행) |
| `r.RDG.TransientAllocator 0` | 일시적 할당자 비활성화 → 리소스 풀링으로 전환 |
| `r.RDG.AsyncCompute 0` | 비동기 컴퓨트 비활성화 |
| `r.RDG.ImmediateMode 1` | 즉시 모드 (위 참조) |

---

## 유효성 검사 레이어 (Validation Layer)

- **자동 활성화**: Debug / Development 빌드
- **컴파일됨 (CPU 오버헤드 있음)**: Test / Shipping 빌드
- 조기에 리소스/패스 이름을 정확히 표시하여 치명적 오류 확인

---

## 리소스 트랜지션 디버깅

### RDG 트랜지션 로그

```bash
# 명령줄 인자: N프레임 동안 모든 RDG 트랜지션 기록
-rdgtransitionlog

# 또는 콘솔에서
r.RDG.TransitionLog 5    # 5프레임 기록

# 리소스 이름으로 필터링
r.RDG.Debug.ResourceFilter SceneDepthZ

# 패스 이름으로 필터링
r.RDG.Debug.PassFilter MyPassName
```

### RHI 트랜지션 로그

```bash
# 특정 리소스 기록
-rhivalidation -rhivalidationlog=SceneDepthZ
```

### 두 로그 동시 사용 (완전 디버깅)

```bash
# RDG(렌더 스레드)와 RHI(RHI 스레드) 로그를 맞추려면
# -onethread 또는 -norhithread -forcerhibypass 필요

-rhivalidation -rhivalidationlog=SceneDepthZ -rdgtransitionlog -rdgdebugresourcefilter=SceneDepthZ -onethread
```

> 주의: RHI 스레드 비활성화 시 일부 파이프라인 간 트랜지션 오류가 보이지 않을 수 있음.

---

## 텍스처 시각화 (vis 명령)

개발(Development) 빌드에서만 사용 가능.
모든 텍스처의 UAV 또는 RTV 쓰기를 화면에 시각화.

```bash
# 콘솔에서 'vis' 입력 → 사용 가능한 리소스 목록과 명령 포맷 표시
vis

# 특정 리소스 시각화
vis SceneColor
vis SceneDepthZ
```

---

## 일시적 할당자 디버깅

아티팩트가 발생할 때:

### Step 1: 할당자 비활성화
```
r.RDG.TransientAllocator 0
```
아티팩트가 사라지면 일시적 할당 관련 문제.

### Step 2: 미초기화 리소스 확인
```
r.RDG.ClobberResources 1
```
모든 리소스를 알려진 값으로 강제 초기화.
일시적 할당자 없이도 비슷한 아티팩트 발생 → 읽기 전 초기화 누락 의심.

### Step 3: 에일리어싱 비활성화
```
r.RDG.Debug.ExtendResourceLifetimes 1
```
그래프 내 모든 에일리어싱 비활성화.
누락된 에일리어싱 배리어나 잘못된 리소스 수명 추적에 유용.

### Step 4: 특정 리소스만 일시적 할당 비활성화
```
r.RDG.Debug.DisableTransientResources 1
```

### Step 5: 영향받는 리소스 필터링
```
r.RDG.Debug.ResourceFilter MyTextureName
```

---

## RDG Insights 플러그인

**위치**: 편집(Edit) > 플러그인(Plugins) > 인사이트(Insights)

### 시각화 가능 항목

- 리소스 수명, 패스 연결, 리소스 풀 할당 오버랩
- 비동기 컴퓨트 펜스 및 오버랩
- 그래프 컬링 및 렌더 패스 병합
- 병렬 실행 패스 범위
- 일시적 메모리 레이아웃

### 답할 수 있는 질문

- 왜 비동기 컴퓨트 패스가 그래프 패스와 오버랩되지 않는가?
- 프레임에서 리소스가 어떻게 사용되고 있는가?
- 리소스 할당이 다른 리소스와 오버랩되고 있는가?
- 포스트 프로세싱에서 어떤 리소스를 사용하는가?
- 어떤 패스가 컬링되었는가?

### 트레이스 캡처

```bash
# 실행 인자
-trace=rdg,defaults

# RDG 채널만 활성화해도 충분
# ★ RDG 트레이스는 많은 데이터 생성 주의
```

---

## Timing Insights와 통합

- Timing Insights 뷰에서 다른 CPU 트랙과 함께 RDG 패스가 트랙으로 표시
- `RDG_EVENT_SCOPE`, `RDG_GPU_STAT_SCOPE`로 추가한 이름이 그대로 표시

---

## 빠른 디버깅 체크리스트

| 증상 | 시도할 명령 |
|------|------------|
| 크래시 위치 모름 | `r.RDG.ImmediateMode 1` |
| 크래시 + 스레드 문제 | `r.RDG.ImmediateMode 1` + `r.RHICmdBypass 1` |
| 패스가 실행 안 됨 | `r.RDG.CullPasses 0` |
| 렌더 패스 병합 문제 | `r.RDG.MergeRenderPasses 0` |
| 텍스처 아티팩트 | `r.RDG.TransientAllocator 0` → `r.RDG.ClobberResources 1` |
| 에일리어싱 의심 | `r.RDG.Debug.ExtendResourceLifetimes 1` |
| 특정 리소스 트랜지션 | `-rdgtransitionlog` + `r.RDG.Debug.ResourceFilter` |
| RHI 배리어 문제 | `-rhivalidation -rhivalidationlog=ResourceName -onethread` |
| 텍스처 내용 확인 | 콘솔 `vis TextureName` |
| Async Compute 오버랩 안 됨 | RDG Insights 플러그인으로 시각화 |
