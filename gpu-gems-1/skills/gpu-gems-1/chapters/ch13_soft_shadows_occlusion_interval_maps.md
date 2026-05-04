# Chapter 13: Generating Soft Shadows Using Occlusion Interval Maps
> 저자: William Donnelly, Andrew Lauritzen (University of Waterloo)

## 핵심 개념
- **해결하려는 문제**: 선형 광원(linear light source)에서 발생하는 소프트 섀도우를 실시간으로 생성
- **Occlusion Interval Map**: 광원의 각 위치에서 차폐가 시작/종료되는 구간(interval)을 미리 계산해 저장하는 이미지 기반 기법
- **소프트 섀도우의 원리**: 면/선 광원은 부분적으로 가려질 수 있음 → 반그림자(penumbra) 영역 생성
- **이미지 기반 접근**: 여러 광원 위치에서의 깊이 맵 정보를 하나의 텍스처에 압축 인코딩
- **실시간 소프트 섀도우**: 하드 섀도우 맵 여러 장을 합성하는 것보다 효율적

## 기술적 세부사항

### 소프트 섀도우의 물리
- 점 광원: 하드 섀도우만 생성 (완전 차폐 or 완전 노출)
- 면/선 광원: 광원의 일부만 차폐 → 반그림자(penumbra) 생성
- 반그림자 너비 ∝ (차폐물~수신면 거리) × (광원 크기) / (차폐물~광원 거리)

### Occlusion Interval Map 원리
1. 선형 광원을 N개의 샘플 위치로 이산화
2. 각 샘플 위치에서 섀도우 맵 렌더링
3. 각 수신 픽셀에 대해: 광원 위치를 훑으면서 차폐 시작/종료 지점을 기록
4. 이 구간 정보를 텍스처 채널에 인코딩 (시작점, 끝점 쌍)
5. 렌더링 시: 인코딩된 구간을 읽어 광원의 몇 %가 보이는지 계산

### 구간 인코딩
- 각 픽셀에서 최대 K개의 차폐 구간 저장 (보통 K=1~2)
- RGBA 4채널로 2개의 구간(시작1, 끝1, 시작2, 끝2) 인코딩 가능
- 구간이 많으면 근사 필요 (가장 큰 구간만 저장 등)

### 렌더링 단계
```
전처리:
  for each light sample position i:
    render shadow map from position i
  
  for each receiver pixel:
    sweep through light positions
    record occlusion start/end intervals
    encode into interval map texture

실시간:
  for each pixel:
    read interval map
    compute visibility = (light extent - occluded intervals) / light extent
    shadow = 1 - visibility
```

### 장점과 한계
- **장점**: 단일 텍스처 조회로 소프트 섀도우 계산, 실시간 가능
- **한계**: 전처리 필요 (정적/반정적 씬에 적합), 저장할 수 있는 구간 수 제한, 동적 오브젝트에 대한 업데이트 비용

## 수식 및 알고리즘

**가시성(Visibility) 계산:**
$$V(P) = 1 - \frac{\sum_{k} (end_k - start_k)}{L_{extent}}$$
- $start_k, end_k$: k번째 차폐 구간의 시작/종료 (광원 파라미터 공간에서 0~1)
- $L_{extent}$: 광원의 전체 범위

**반그림자 크기 근사:**
$$w_{penumbra} = \frac{d_{receiver} - d_{blocker}}{d_{blocker}} \times w_{light}$$

**구간 인코딩 (RGBA):**
$$R = start_1, \quad G = end_1, \quad B = start_2, \quad A = end_2$$

**알고리즘 흐름:**
1. 광원 N개 샘플 위치에서 깊이 맵 렌더링
2. 각 수신 픽셀: 광원 축을 따라 차폐 구간 추출
3. 구간을 텍스처에 인코딩
4. 최종 렌더링: 구간 텍스처에서 가시성 계산 → 소프트 섀도우

## UE5 관점에서의 활용
- **PCSS**: UE5에서 소프트 섀도우의 주된 방법은 PCSS(Percentage-Closer Soft Shadows). 차폐물 거리에 따라 PCF 필터 크기를 동적 조절하는 방식으로 더 실용적.
- **Contact Shadows**: 화면 공간 레이마칭으로 접촉부의 세밀한 그림자 추가
- **Ray Traced Soft Shadows**: 하드웨어 RT로 면광원에서의 물리적으로 정확한 소프트 섀도우 가능. Occlusion Interval Map의 궁극적 목표를 달성.
- **Virtual Shadow Maps**: 높은 해상도로 앨리어싱 줄이고, 필터링으로 소프트니스 추가
- **역사적 의의**: Occlusion Interval Map은 이미지 기반 소프트 섀도우 연구의 중요한 이정표. PCSS, Variance Shadow Maps 등 후속 연구에 영감.

## 핵심 요약 (3줄)
- 선형 광원의 차폐 구간을 텍스처에 인코딩해 단일 조회로 소프트 섀도우를 계산하는 이미지 기반 기법이다.
- 전처리에서 여러 깊이 맵을 합성해 구간 맵을 생성하고, 실시간에서 가시성 비율로 변환한다.
- 현대에는 PCSS와 RT 소프트 섀도우가 대세지만, 이 연구는 소프트 섀도우 기법 발전의 중요한 이정표다.
