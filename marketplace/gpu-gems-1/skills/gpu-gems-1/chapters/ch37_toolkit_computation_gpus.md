# Chapter 37: A Toolkit for Computation on GPUs
> 저자: Ian Buck, Tim Purcell (Stanford University)

## 핵심 개념
- **해결하려는 문제**: GPU를 그래픽스가 아닌 범용 연산(GPGPU)에 활용하기 위한 프로그래밍 모델과 기본 알고리즘
- GPU는 CPU 대비 ~3배 이상의 부동소수점 연산 성능, ~4배의 메모리 대역폭
- **스트림 프로세싱 모델**: 커널(fragment program)이 스트림(텍스처)의 각 요소를 독립적/병렬로 처리
- 텍스처 = 배열, 프래그먼트 프로그램 = 커널, Render-to-Texture = 배열 쓰기
- Reduce, Sort, Search 등 기본 연산의 GPU 구현

## 기술적 세부사항

### GPU 프로그래밍 모델: 스트림 프로세싱
- **Stream**: 데이터 레코드의 집합 → GPU에서는 **텍스처**
- **Kernel**: 스트림의 각 요소에 독립적으로 적용하는 함수 → **프래그먼트 프로그램**
- 핵심 제약: 각 요소는 **독립적으로** 처리 — 요소 간 의존성 없음
- 이것이 대규모 병렬화를 가능하게 하는 핵심 조건

### GPU ↔ 배열 매핑
| CPU 개념 | GPU 대응 |
|---------|---------|
| 배열 | 텍스처 |
| 배열 읽기 | 텍스처 룩업 |
| 배열 쓰기 | Render-to-Texture |
| for 루프 | 쿼드 래스터라이제이션 |
| 함수 | 프래그먼트 프로그램 |
| 피드백 루프 | 핑퐁 버퍼 (읽기/쓰기 텍스처 교대) |

### 기본 연산 구현

#### 1. Reduce (리듀스)
- 배열을 하나의 값으로 축소 (합, 최대, 최소 등)
- **다단계 다운샘플링**: 매 패스마다 해상도를 절반으로 줄임
- N개 요소 → $O(\log N)$ 패스에 하나의 값 생성
- 각 패스: 2×2 블록을 읽어 연산 적용, 결과를 절반 크기 텍스처에 쓰기

#### 2. Sort (정렬) — Bitonic Merge Sort
- GPU의 병렬 특성에 적합한 정렬 알고리즘
- N개 요소, N개 프로세서 → $O(\log^2 N)$ 단계
- 각 단계에서 N개의 비교-교환을 병렬 수행
- 프래그먼트 프로그램이 비교할 두 요소의 텍스처 좌표를 계산하고 교환 여부 결정

#### 3. Search (검색) — Binary Search
- 정렬된 텍스처에서 이진 탐색
- 단일 패스로 100만 개 이상의 요소에서 검색 가능 (1ms 미만)
- 여러 검색을 병렬로 수행 가능 (각 프래그먼트가 하나의 검색)

### 제약 사항
- **Scatter 불가**: 프래그먼트 프로그램이 출력 위치를 변경할 수 없음
  - 해결: Scatter를 Gather로 변환 (인접 텍셀 읽기)
- **제한된 출력**: 한 번에 소수의 float4만 출력 (MRT)
- **디버깅 도구 부족**: CPU에 비해 프로파일러/디버거 미성숙

## 수식 및 알고리즘

### Reduce 알고리즘
```
// 합 Reduce: N → 1
input = sourceTexture  // N×N
for size = N/2 to 1:
    output = CreateTexture(size, size)
    RenderQuad(output, reduceKernel, input)
    // reduceKernel: 2×2 블록 합산
    input = output
result = ReadTexel(input, 0, 0)
```

### Bitonic Sort (8요소 예시)
```
Step 1: 2개씩 그룹 → 4개의 정렬된 쌍
Step 2: 4개씩 그룹 → 2개의 정렬된 리스트  
Step 3: 8개 전체 → 1개의 정렬된 리스트
총 O(log²N) 단계, 각 단계 N개 병렬 비교-교환
```

## UE5 관점에서의 활용
- 이 챕터는 **CUDA/Compute Shader의 전신** — 2004년 당시에는 그래픽스 API를 우회적으로 사용해야 했음
- UE5의 **Compute Shader**가 이 모든 것을 직접 지원:
  - 텍스처 대신 **Structured Buffer / RWTexture**
  - 프래그먼트 프로그램 대신 **Compute Kernel**
  - Scatter도 자유롭게 가능 (UAV 쓰기)
- **Niagara** (파티클 시스템)이 GPU compute로 대규모 시뮬레이션 수행
- **GPU Scene**에서 Reduce/Sort/Cull 등이 compute shader로 구현
- 현대적 대안: CUDA, OpenCL, Vulkan Compute가 전용 GPGPU 프레임워크

## 핵심 요약 (3줄)
1. GPU의 스트림 프로세싱 모델에서 텍스처=배열, 프래그먼트 프로그램=커널로 매핑하여 범용 연산을 수행한다.
2. Reduce($O(\log N)$), Bitonic Sort($O(\log^2 N)$), Binary Search(단일 패스)가 GPU 기본 연산 툴킷이다.
3. 이 연구는 CUDA와 Compute Shader의 기초가 되었으며, 현대 GPU 컴퓨팅의 출발점이다.
