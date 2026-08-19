# Chapter 28: Graphics Pipeline Performance
> 저자: Cem Cebenoyan (NVIDIA)

## 핵심 개념
- **해결하려는 문제**: GPU 렌더링 파이프라인의 성능 병목을 체계적으로 찾고 최적화하는 방법론 제시
- 파이프라인은 가장 느린 스테이지만큼만 빠르다 — 잘못된 스테이지를 최적화하면 **성능 향상이 0**이 됨
- GPU 내부는 여러 병렬 유닛(vertex fetch, vertex shading, fragment shading, ROP)으로 구성된 파이프라인
- **병목 식별 → 최적화 → 반복**이라는 3단계 루프가 핵심 방법론
- CPU와 GPU 사이의 병목도 존재하며, 배치(batch) 크기 최적화가 중요

## 기술적 세부사항

### 파이프라인 스테이지
1. **CPU**: 드로우콜 제출, 상태 변경
2. **Vertex/Index Fetch**: 정점 데이터 읽기
3. **Vertex Shading (T&L)**: 변환 및 라이팅
4. **Fragment Shading**: 픽셀별 셰이딩
5. **ROP (Raster Operations)**: 깊이/스텐실 테스트, 알파 블렌딩, 프레임버퍼 쓰기

### 병목 식별 방법
| 스테이지 | 테스트 방법 |
|---------|-----------|
| **ROP/프레임버퍼 대역폭** | 컬러/뎁스 비트 깊이를 32→16으로 줄여보기, 메모리 클럭 변경 |
| **Fragment Shading** | 해상도를 줄여보기 (예: 뷰포트를 작게). 성능이 변하면 fragment bound |
| **Vertex Shading** | 버텍스 셰이더 명령어 수를 줄여보기. 성능 변하면 vertex bound |
| **CPU** | GPU 클럭을 내려도 성능이 안 변하면 CPU bound |

### 최적화 전략

#### CPU 병목 해결
- **배치 크기 최대화**: 드로우콜 하나당 CPU 비용이 있으므로, 한 번에 더 많은 삼각형 제출
  - 디제너레이트 삼각형으로 스트립 연결
  - **텍스처 아틀라스(Texture Page)**: 여러 텍스처를 하나의 2D 텍스처에 배치
  - GPU 셰이더 분기를 활용해 배치 합치기

#### Vertex 병목 해결
- 인덱스드 프리미티브 사용 (post-T&L 캐시 활용)
- LOD (Level of Detail) 적용
- 버텍스 셰이더 명령어 수 줄이기

#### Fragment 병목 해결
- **Depth-only 패스 먼저 렌더링**: depth complexity 높은 씬에서 효과적
- **Early-Z 최적화 활용**: 대략적 front-to-back 순서로 렌더링
- **복잡한 함수를 텍스처 룩업으로 대체**: 정규화 큐브맵 등
- 불필요한 정밀도 줄이기 (half/fixed 활용)

#### ROP 병목 해결
- 프레임버퍼 대역폭 줄이기 (비트 깊이 감소)
- 불필요한 알파 블렌딩 비활성화

## 수식 및 알고리즘
특별한 수학 공식보다는 **실험적 방법론**이 핵심:
```
while (성능 < 목표):
    for stage in [CPU, VertexFetch, VS, FS, ROP]:
        workload(stage) 변경 또는 clock(stage) 변경
        if 성능_변화:
            bottleneck = stage
            break
    optimize(bottleneck)
```

## UE5 관점에서의 활용
- UE5의 **Nanite**는 이 챕터에서 말하는 vertex/triangle 병목을 근본적으로 해결 — 소프트웨어 래스터라이저로 작은 삼각형 문제 회피
- **GPU Scene**과 **인스턴스드 드로우**는 배치 크기 최대화의 현대적 구현
- RenderDoc, Nsight Graphics 같은 프로파일러가 이 챕터의 "클럭 변경" 테스트를 대체
- Early-Z와 depth prepass는 UE5에서도 여전히 핵심 최적화 기법 (BasePass 전 PrePass)
- UE5의 **Shader Permutation** 시스템은 GPU 분기 대신 컴파일타임 분기를 사용하는 현대적 대안

## 핵심 요약 (3줄)
1. GPU 파이프라인 최적화의 본질은 **병목 식별 → 해당 스테이지 최적화 → 반복**이다.
2. 잘못된 스테이지를 최적화하면 성능 향상이 0이므로, 반드시 먼저 프로파일링해야 한다.
3. 배치 크기 최대화, depth prepass, 텍스처 룩업 활용 등의 기법은 20년이 지난 지금도 유효하다.
