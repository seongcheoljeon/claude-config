# Chapter 29: Efficient Occlusion Culling
> 저자: Dean Sekulic (Croteam)

## 핵심 개념
- **해결하려는 문제**: 카메라에 보이지 않는 오브젝트를 렌더링하지 않아 GPU 부하를 줄이는 방법
- **Occlusion Query**: GPU가 특정 지오메트리의 가시 픽셀 수를 반환하는 하드웨어 기능
- **Early-Z Rejection**: 래스터라이저 단계에서 깊이 테스트 실패한 프래그먼트를 조기 제거
- 바운딩 박스를 활용한 효율적인 오클루전 테스트 기법
- Serious Sam 엔진에서의 실전 적용 사례 (렌즈 플레어, 미러)

## 기술적 세부사항

### Occlusion Query vs Early-Z
| 특성 | Occlusion Query | Early-Z |
|------|----------------|---------|
| 동작 레벨 | 지오메트리 레벨 | 래스터라이제이션 레벨 |
| 제어 | 애플리케이션이 제어 | 자동 |
| 효과 | 전체 오브젝트 스킵 가능 | 픽셀 단위 대역폭 절약 |

### Occlusion Query 동작 과정
1. 쿼리 생성
2. 컬러 쓰기 비활성화 (color mask = false)
3. 뎁스 쓰기 비활성화 (읽기만, 업데이트 X)
4. 쿼리 시작 (가시 픽셀 카운터 리셋)
5. 바운딩 박스 "렌더링" (뎁스 테스트만 수행)
6. 쿼리 종료
7. 컬러/뎁스 쓰기 재활성화
8. 쿼리 결과 받기 (가시 픽셀 수)
9. 가시 픽셀 > 0이면 실제 오브젝트 렌더링

### Occluder vs Occludee 문제
- 바운딩 박스는 뎁스 버퍼에 쓸 수 없음 — 바운딩 박스끼리 잘못된 오클루전 결과 발생 가능
- 해결: 큰 오브젝트(벽, 건물)를 먼저 occluder로 렌더링하고, 작은 오브젝트에 대해 쿼리 수행

### GPU Stall 문제와 해결
- 쿼리 결과를 즉시 요청하면 GPU가 모든 렌더링을 끝낼 때까지 CPU가 대기(stall)
- **해결**: 결과를 1프레임 지연시켜 읽기 — 이전 프레임의 쿼리 결과를 현재 프레임에 사용
- Front-to-back 정렬 필수 — Early-Z와 오클루전 모두 이 정렬에 의존

### 실전 적용: 렌즈 플레어
- 기존: 뎁스 버퍼 읽기 → GPU stall 발생
- 개선: 오클루전 쿼리로 광원 바운딩 박스 테스트, 1프레임 지연 결과 사용

## 수식 및 알고리즘
```
// 기본 오클루전 컬링 의사코드
SortObjectsFrontToBack(objects, camera)
RenderLargeOccluders(objects)  // 뎁스 버퍼 채우기

for each object in smallObjects:
    BeginQuery(query[object])
    RenderBoundingBox(object)   // 컬러/뎁스 쓰기 OFF
    EndQuery(query[object])

// 다음 프레임에서:
for each object in smallObjects:
    if GetQueryResult(query[object]) > 0:
        RenderObject(object)
```

## UE5 관점에서의 활용
- UE5의 **Hardware Occlusion Queries**는 이 챕터의 기법을 직접 계승
- UE5는 추가로 **Software Occlusion Culling** (CPU 기반)도 지원 — 모바일 등에서 활용
- **Nanite**는 GPU-driven 파이프라인에서 클러스터 단위 오클루전 컬링을 수행 — HZB (Hierarchical Z-Buffer) 기반
- 현대적 대안: **GPU-driven rendering**에서는 compute shader로 오클루전 테스트를 배치 처리하여 stall 문제를 근본적으로 제거
- 1프레임 지연 기법은 여전히 사용되지만, temporal 아티팩트 주의 필요

## 핵심 요약 (3줄)
1. Occlusion Query는 GPU가 가시 픽셀 수를 반환하는 하드웨어 기능으로, 보이지 않는 오브젝트를 렌더링에서 제외할 수 있다.
2. GPU stall을 피하려면 쿼리 결과를 1프레임 지연시켜 읽고, front-to-back 정렬은 필수다.
3. 현대에는 HZB 기반 GPU-driven 컬링이 대세이지만, 기본 원리는 이 챕터와 동일하다.
