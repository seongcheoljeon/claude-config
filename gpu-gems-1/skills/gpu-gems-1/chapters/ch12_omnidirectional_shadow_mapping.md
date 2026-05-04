# Chapter 12: Omnidirectional Shadow Mapping
> 저자: Philipp S. Gerasimov (iXBT.com)

## 핵심 개념
- **해결하려는 문제**: 점 광원(point light)에서 모든 방향으로 그림자를 캐스팅하는 전방향(omnidirectional) 섀도우 매핑 구현
- **큐브맵 기반 접근**: 6개 면에 각각 섀도우 맵을 렌더링 → 큐브맵으로 그림자 조회
- **스텐실 섀도우 vs 섀도우 매핑**: 스텐실은 높은 필레이트 비용, 섀도우 매핑은 앨리어싱 문제 → 각각 장단점 비교
- **듀얼 파라볼로이드 대안**: 큐브맵 대신 2장의 파라볼로이드 맵으로 전방향 커버 가능
- **정수/부동소수점 텍스처**: 깊이값 저장 형식에 따른 정밀도 트레이드오프

## 기술적 세부사항

### 스텐실 섀도우 vs 섀도우 매핑
| | 스텐실 섀도우 | 섀도우 매핑 |
|---|---|---|
| 장점 | 픽셀 정확, 넓은 하드웨어 지원 | 알파 테스트 지원, self-shadow, 빠른 필레이트 |
| 단점 | 실루엣 감지 CPU 비용, 높은 필레이트 | 앨리어싱, 정밀도 문제 |

### 큐브맵 섀도우 매핑 구현

**Phase 1: 섀도우 맵 렌더링**
1. 큐브맵 생성 (R16F 또는 R32F, 렌더 타겟)
2. 점 광원 위치에서 6방향으로 90° FOV 렌더링
3. 각 면에 광원~오브젝트 거리를 깊이로 저장
4. 뷰 행렬: up, down, east, west, north, south 방향

**Phase 2: 그림자 적용**
1. 각 픽셀에서 광원까지의 벡터 계산
2. 이 벡터로 큐브맵에서 저장된 깊이 샘플링
3. 현재 픽셀의 광원 거리와 비교
4. 저장된 깊이 < 현재 거리 → 그림자

### 깊이 인코딩 방식

**부동소수점 텍스처 (R16F/R32F)**
- 직접 거리값 저장 → 간단하고 정확
- 하드웨어 지원 필요

**정수 텍스처 (A8R8G8B8)**
- 깊이를 여러 채널에 분산 인코딩:
  ```
  encode: color.rgb = frac(depth * float3(1, 256, 65536))
  decode: depth = dot(color.rgb, float3(1, 1/256, 1/65536))
  ```
- 더 넓은 하드웨어 호환성

### Vertex/Pixel Shader
```
Vertex Shader:
  worldPos = mul(world, position)
  lightVec = worldPos - lightPosition
  depth = length(lightVec)  // 광원까지 거리
  
Pixel Shader:
  storedDepth = texCUBE(shadowCubeMap, lightVec)
  if (storedDepth + bias < currentDepth)
    shadow = 0  // 그림자
  else
    shadow = 1  // 밝음
```

## 수식 및 알고리즘

**광원 거리 계산:**
$$d = |\mathbf{P}_{world} - \mathbf{P}_{light}|$$

**큐브맵 조회:**
$$d_{stored} = texCUBE(shadowMap, \mathbf{P}_{world} - \mathbf{P}_{light})$$

**그림자 판정:**
$$shadow = \begin{cases} 0 & \text{if } d_{stored} + bias < d \\ 1 & \text{otherwise} \end{cases}$$

**정수 인코딩/디코딩:**
$$encoded = frac(d \times [1, 256, 65536])$$
$$decoded = encoded \cdot [1, 1/256, 1/65536]$$

**알고리즘 흐름:**
1. 큐브맵 6면 × 렌더 패스: 광원 시점에서 깊이 렌더링
2. 카메라 시점 렌더링: 각 픽셀에서 큐브맵 조회 → 깊이 비교 → 그림자 판정
3. 조명 계산 × 그림자 팩터 → 최종 색상

## UE5 관점에서의 활용
- **Point Light Shadows**: UE5의 점 광원 그림자는 큐브맵 섀도우 매핑 사용. 이 챕터의 직접적 후손.
- **Virtual Shadow Maps**: UE5의 VSM은 큐브맵 대신 가상 텍스처 페이지로 점 광원 그림자를 처리해 해상도 문제 해소
- **성능 이슈**: 6면 렌더링은 비용이 높음. UE5에서는 가시성 컬링으로 필요한 면만 업데이트.
- **Ray Traced Point Shadows**: 하드웨어 RT로 큐브맵 없이 점 광원 그림자 생성 가능 (더 정확하고 소프트)
- **Movable/Stationary/Static**: UE5는 광원 모빌리티에 따라 다른 섀도우 기법 선택. 정적 광원은 라이트맵으로 구움.

## 핵심 요약 (3줄)
- 점 광원의 전방향 그림자를 큐브맵에 6면 깊이를 렌더링하고 비교하는 방식으로 구현한다.
- 부동소수점/정수 텍스처 두 가지 깊이 인코딩 방식과 각각의 트레이드오프를 분석했다.
- 이 큐브맵 기반 점 광원 섀도우 매핑은 현대 엔진의 점 광원 그림자 구현의 직접적 기반이다.
