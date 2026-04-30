# RDG 내부 동작 원리 (First Principle)
> 출처: xtozero 블로그 "Render Graph :: 게임 엔진 개발" (2025.10.17)
>       원조: GDC 2017 "FrameGraph: Extensible Rendering Architecture in Frostbite"

---

## RDG의 기원 — Why Render Graph?

2017년 GDC Frostbite 발표("FrameGraph")에서 처음 소개.
UE5 → **Render Dependency Graph (RDG)**, Unity → **Render Graph**.

### 필요성의 근본 원인

**모던 그래픽 API (DX12, Vulkan, Metal)**가 드라이버에서 자동으로 해주던 작업을
사용자(프로그래머)가 직접 제어해야 하는 방향으로 바뀌었기 때문.

구체적으로:
- **리소스 상태 전환(Resource Barrier)** 을 직접 명시해야 함 (렌더 타겟 → 셰이더 입력 등)
- 상태 전환을 **배치(batch)** 로 처리해야 최적 성능 가능
- 리소스 수가 방대해 수작업 관리는 실수 필연적

RDG가 해결하는 세 가지:
1. **리소스 관리 자동화** — 어떤 리소스를 읽고/쓰는지 파악해 barrier 자동 처리
2. **의존성 기반 스케줄링** — Async Compute 병렬 실행, 동기화 포인트 자동 삽입
3. **렌더링 최적화** — 불필요한 패스 컬링, 중간 리소스 재활용(메모리 에일리어싱)

---

## 3단계 구조 (Frostbite 원조 → UE5 동일)

```
Setup   →   Compile   →   Execute
(리소스 설정/생성)  (그래프 정렬)  (패스 실행)
```

UE5에서의 대응:
```
GraphBuilder.CreateTexture()    →  FRDGBuilder 구성 단계
GraphBuilder.AddPass()          →  구성 단계 (람다 연기)
GraphBuilder.Execute()          →  Compile + Execute
```

---

## Compile 단계 — 내부 알고리즘

UE5 RDG와 Frostbite 구현 모두 동일한 3단계로 컴파일:

```
BuildPassAdjacencyLists()  →  SortPasses()  →  CompilePassEvent()
(인접 리스트 구축)            (위상 정렬)         (GPU 프로파일 이벤트)
```

### Step 1: 인접 리스트 구축

각 패스의 `resourceWrites`(출력) 가 다른 패스의 `resourceReads`(입력) 에 포함되면
→ 그래프에 간선(edge) 추가.

```
Pass A writes Texture X
Pass B reads  Texture X
→ Edge: A → B (B는 A에 의존)
```

**이 간선이 자동 barrier 삽입과 Pass Culling의 기반.**

### Step 2: Kahn's Algorithm 위상 정렬 (Topological Sort)

```cpp
// 1. 진입 차수(in-degree) 계산
for each pass i:
    for each edge i→j:
        inDegree[j]++

// 2. in-degree == 0 인 패스를 priority_queue에 삽입
//    ★ stable sort를 위해 패스 인덱스 오름차순 정렬 (원래 순서 최대한 보존)

// 3. BFS 방식 정렬
while queue not empty:
    passIndex = queue.top(); queue.pop()
    sortedPasses.add(passes[passIndex])
    for each neighbor j of passIndex:
        inDegree[j]--
        if inDegree[j] == 0:
            queue.push(j)
        // ★ Async Compute fence 삽입 여부 결정 (아래 참조)
```

**결과**: 의존성을 고려한 실행 순서 → 렌더 패스가 올바른 순서로 실행됨.

---

## Async Compute Fence 삽입 시점 (핵심)

위상 정렬 **도중** 간선을 처리할 때, 큐 타입이 다르면 동기화 플래그를 세팅.

```cpp
// SortPasses 내부
for each neighbor j of passIndex:
    // 큐 타입이 다르면 (Graphics ↔ Compute) 동기화 필요
    bool waitForOtherQueue =
        GetQueueType(passes[passIndex]->type) != GetQueueType(passes[j]->type);
    passes[j]->waitForOtherQueue |= waitForOtherQueue;
```

그리고 Execute 전 Prologue에서:
```cpp
// Direct 큐 패스 실행 전: Compute 큐 완료 대기
if (pass.waitForOtherQueue && queue == Direct)
    GraphicsInterface().WaitQueue(QueueType::Compute);

// Compute 큐 패스 실행 후: Direct 큐에 신호
if (pass.waitForOtherQueue && queue == Compute)
    GraphicsInterface().WaitQueue(QueueType::Direct);
```

**UE5 RDG도 동일 원리**: 위상 정렬 시 마지막 생산자(Producer) → 펜스 삽입,
첫 번째 소비자(Consumer) → 그래픽 파이프 재합류.

---

## 리소스 상태(Access Flag) 분류 기준

패스 파라미터에 선언된 리소스가 어떤 용도로 쓰이는지에 따라
**읽기(Read)** / **쓰기(Write)** 로 분류해 barrier를 결정.

| 접근 타입 | 읽기 리소스 | 쓰기 리소스 |
|-----------|-------------|-------------|
| SRV | ✅ | |
| UAV | ✅ | ✅ |
| CopySource | ✅ | |
| CopyDest | | ✅ |
| RTV | | ✅ |
| DSV (ReadOnly) | ✅ | |
| DSV (ReadWrite) | | ✅ |

> **UAV가 읽기+쓰기 양쪽에 포함되는 이유**: Compute Shader에서 UAV는
> 읽기와 쓰기를 동시에 할 수 있기 때문. 의존성 추적 시 양방향으로 처리.

---

## 선형 할당자 패턴 (Frame Allocator)

RDG 리소스(패스, 텍스처 디스크립터 등)를 모두 **선형 할당자**로 관리.

```
Execute() 완료
    → CleanUp() 호출
        → m_allocator.Flush()   ← 전체 메모리 한 번에 해제
        → 컨테이너 재구성 (construct_at)
```

**장점**:
- `new`/`delete` 개별 호출 없이 포인터 범프(bump)만으로 할당 → 매우 빠름
- 프레임 단위 일괄 해제 → fragmentation 없음
- UE5 RDG의 `GraphBuilder.AllocPOD<T>()` / `AllocObject<T>()` 와 동일 원리

```cpp
// UE5 대응 패턴
FMyObject* Obj = GraphBuilder.AllocPOD<FMyObject>();    // 선형 할당
// → GraphBuilder 소멸 시 전체 일괄 해제 (프레임 끝)
```

---

## RDG 리소스 래핑 패턴

실제 GPU 리소스를 **즉시 할당하지 않고** 디스크립터(trait)만 보관.
패스가 실제 실행될 때(Prologue) GPU 메모리 할당.

```
CreateTexture() → 디스크립터만 저장 (GPU 메모리 X)
                          ↓
              Execute() → PreparePassResource()
                          → 리소스 풀에서 재사용 가능한 것 탐색
                          → 없으면 새로 할당
```

**외부 리소스 구분**: `m_isExternal = true` 플래그로 구분.
외부 리소스는 PreparePassResource에서 할당 스킵.

UE5 대응:
```
CreateTexture()          → 내부(Transient) 리소스, Execute 시 할당
RegisterExternalTexture() → 외부 리소스, m_isExternal = true
```

---

## Setup 함수 — Parameters에서 의존성 자동 추출

UE5에서 `AddPass(Parameters, ...)` 시 RDG가 Parameters 구조체를 순회해
리소스 의존성을 자동으로 추출하는 원리.

내부적으로:
```cpp
for each member in Parameters (via reflection metadata):
    if member is SRV/CopySource:
        pass.resourceReads.add(resource)
    if member is UAV/RTV/CopyDest:
        pass.resourceWrites.add(resource)
        if UAV:
            pass.resourceReads.add(resource)  // UAV는 양쪽 모두
```

**이것이 UE5에서 `SHADER_PARAMETER_RDG_TEXTURE_SRV` 등의 매크로가
단순 바인딩 이상의 역할을 하는 이유** — RDG 의존성 그래프 구축에 직접 참여.

---

## 요약: UE5 RDG ↔ Frostbite/Custom RG 대응표

| 개념 | Frostbite/Custom | UE5 RDG |
|------|-----------------|---------|
| 3단계 구조 | Setup→Compile→Execute | AddPass→Execute(내부 컴파일) |
| 그래프 정렬 | Kahn's Topological Sort | 동일 |
| 인접 리스트 | resourceWrites→resourceReads 매칭 | Shader Parameters 메타데이터 |
| Async 펜스 | SortPasses 도중 waitForOtherQueue 세팅 | 그래프 탐색 후 자동 펜스 삽입 |
| 선형 할당자 | m_allocator.Flush() | GraphBuilder.AllocPOD/AllocObject |
| 지연 GPU 할당 | PreparePassResource() in Prologue | Execute 시 Transient 할당 |
| 외부 리소스 | m_isExternal = true | RegisterExternalTexture |
| 리소스 분류 | RenderGraphResourceFlag 비트마스크 | ERHIAccess 마스크 |
