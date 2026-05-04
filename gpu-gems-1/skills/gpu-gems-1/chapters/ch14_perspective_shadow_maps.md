# Chapter 14: Perspective Shadow Maps: Care and Feeding
> 저자: Simon Kozlov (SoftLab-NSK)

## 핵심 개념
- **해결하려는 문제**: 섀도우 맵의 앨리어싱 문제를 Perspective Shadow Maps(PSM)으로 해결하되, 원래 PSM 알고리즘의 실전 문제들을 분석하고 해법 제시
- **PSM의 원리**: 카메라의 post-projective 공간에서 섀도우 맵을 생성 → 카메라 가까운 물체에 더 높은 해상도 배분
- **핵심 문제점들**: 카메라 뒤 물체의 투영 뒤집힘, 방향 광원의 특이점, 점 광원의 큐브맵 호환 문제
- **실전 해결책**: 가상 카메라, 큐브맵 방식, 필터링, depth bias 등 실용적 트릭 제시
- **Object-space vs Image-space**: 섀도우 볼륨(오브젝트)과 섀도우 맵(이미지)의 근본적 차이 분석

## 기술적 세부사항

### PSM의 기본 아이디어
1. 일반 섀도우 맵: 광원 시점에서 렌더링 → 모든 거리에 균등한 해상도
2. PSM: 카메라 투영 후 공간에서 섀도우 맵 생성 → 가까운 물체 ≫ 먼 물체 (원근 분배)
3. 결과: 카메라 가까이에서 더 상세한 그림자 → 사람 눈에 보이는 영역의 앨리어싱 감소

### 문제 1: 카메라 뒤 물체
- post-projective 공간에서 카메라 뒤 물체가 반대편 무한대로 이동
- 이 물체가 그림자 캐스터라면 잘못된 그림자 생성
- **해결**: 가상 카메라를 뒤로 슬라이드해 모든 캐스터를 절두체 안에 포함

### 문제 2: 방향 광원 + PSM
- 방향 광원(directional light)의 평행 투영은 post-projective 변환과 충돌
- post-projective 공간에서 평행 광선이 수렴/발산
- **해결**: 라이트 행렬을 적절히 변형해 안정적인 투영 유지

### 문제 3: 점 광원
- 점 광원은 큐브맵 방식이 필요
- PSM + 큐브맵 조합의 좌표 계산이 복잡
- **해결**: 큐브맵의 각 면에 대해 독립적으로 PSM 적용하거나, 멀티텍스처로 에뮬레이트

### 필터링 (PCF with PSM)
- PSM에서의 PCF는 일반 섀도우 맵과 동일하게 적용 가능
- 인접 텍셀 오프셋으로 샘플링 → 평균
- 심각한 앨리어싱은 PCF로도 완전 제거 불가 (흐릿해질 뿐)
- NVIDIA depth texture 하드웨어 PCF + 수동 PCF 조합으로 품질 향상

### Depth Bias 트릭
- Shadow acne(자기 그림자 아티팩트) 방지를 위한 bias 필수
- slope-dependent bias: 표면 기울기에 비례하는 오프셋
- PSM 공간에서의 bias 계산은 일반 SM과 다를 수 있음

## 수식 및 알고리즘

**PSM 변환:**
$$P_{PSM} = M_{light} \times M_{camera\_projection} \times P_{world}$$
- 카메라 투영 후 공간에서 광원 투영 적용

**큐브맵 텍스처 좌표 계산:**
```
VP = V - P  // 광원에서 정점까지 벡터
// 각 면까지 거리 d1~d6 계산
// 큐브와의 교차점 = VP * (1/max_component)
cbmcoord = VP * rcp(max(abs(VP.x), abs(VP.y), abs(VP.z)))
depth = Q * length(VP) - Q * Zn  // 깊이 계산
```

**가상 카메라 보정:**
$$Z_{virtual} = Z_{camera} - \Delta Z$$
- $\Delta Z$: 모든 섀도우 캐스터가 절두체 안에 들어오도록 하는 백오프 거리

**PCF with PSM (4샘플):**
```
shadow = 0
for each offset in {(-1,-1), (-1,1), (1,-1), (1,1)}:
  shadow += tex2Dproj(shadowMap, uv + offset * texelSize)
shadow /= 4
```

## UE5 관점에서의 활용
- **Cascaded Shadow Maps (CSM)**: PSM의 아이디어(가까운 곳에 더 높은 해상도)를 발전시킨 것이 CSM. 거리별 여러 캐스케이드로 해상도 분배.
- **Virtual Shadow Maps**: UE5의 VSM은 PSM/CSM의 궁극적 진화. 가상 텍스처 페이지로 필요한 곳에만 높은 해상도 할당.
- **역사적 위치**: PSM → LiSPSM → CSM → VSM으로 이어지는 섀도우 맵 앨리어싱 해결 연구의 중요한 한 단계
- **Shadow Bias**: UE5에서도 slope bias + constant bias 조합 사용. 이 챕터의 bias 분석이 기반.
- **Far Shadow**: UE5의 Far Shadow (원거리 Cascade)는 PSM의 "먼 곳은 낮은 해상도로도 충분" 관찰의 직접적 응용

## 핵심 요약 (3줄)
- PSM은 카메라 post-projective 공간에서 섀도우 맵을 생성해 가까운 곳에 높은 해상도를 배분하는 기법이다.
- 원 논문의 이론적 문제들(카메라 뒤 물체, 방향 광원 특이점)에 대한 실전 해결책과 필터링/bias 트릭을 다룬다.
- PSM은 현대의 CSM과 Virtual Shadow Maps으로 발전한 섀도우 맵 앨리어싱 연구의 핵심 이정표다.
