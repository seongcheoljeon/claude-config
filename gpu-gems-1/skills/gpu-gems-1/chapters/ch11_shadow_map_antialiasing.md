# Chapter 11: Shadow Map Antialiasing
> 저자: Michael Bunnell (NVIDIA), Fabio Pellacini (Pixar Animation Studios)

## 핵심 개념
- **해결하려는 문제**: 섀도우 맵의 확대(magnification)로 인한 계단 현상(jaggies)을 실시간으로 줄이기
- **PCF(Percentage-Closer Filtering)**: 섀도우 맵은 일반 텍스처처럼 프리필터링 불가 → 여러 깊이 비교 결과를 평균내는 방식
- **하드웨어 가속 PCF**: GPU의 섀도우 맵 하드웨어를 최대 활용한 간소화된 PCF 구현
- **4×4 샘플링**: 16개 샘플로 안티앨리어싱 + 소프트 엣지 생성
- **바이리니어 보간 활용**: 4개의 하드웨어 바이리니어 샘플로 16개 비교 근사

## 기술적 세부사항

### 섀도우 맵 앨리어싱의 원인
- 섀도우 맵을 geometry에 투영할 때 확대가 발생
- 빛이 표면과 거의 평행하게 비추면 확대가 무한대에 가까워짐
- 해상도를 높여도 이 문제를 완전히 해결 못함
- Perspective Shadow Maps로 해상도 분배를 개선해도 한계 존재

### PCF (Percentage-Closer Filtering)
- **원리**: 여러 섀도우 맵 텍셀과 비교 → 결과를 평균 → "몇 %가 빛에 노출되는가"
- **원래 PCF (Reeves 1987)**: 셰이딩 영역을 섀도우 맵 공간에 매핑, 확률적 샘플링
- **이 챕터의 간소화**: 고정 4×4 텍셀 영역을 모든 곳에서 사용
  - 텍셀 경계에 정렬하지 않음 (정렬하면 불연속이 보임)
  - 16개 비교 결과를 가중 평균

### 하드웨어 가속 구현
- **핵심 아이디어**: GPU가 `tex2Dproj`로 한 번에 2×2 바이리니어 PCF를 수행
- 4×4 영역을 커버하려면 **4번의 바이리니어 샘플** 필요
  - 각 샘플을 2×2 블록의 중심에 위치시킴
  - 하드웨어가 자동으로 4개 텍셀과 비교 후 보간
- 16개 개별 비교 대신 4번의 텍스처 fetch로 근사

### 샘플 오프셋 계산
```
texel 크기: texelSize = 1.0 / shadowMapResolution
4개 샘플 위치: 기준 좌표에서 ±0.5~1.5 텍셀 오프셋
각 샘플의 가중치: 위치에 따라 다름 (가장자리가 낮음)
최종: weightedSum / totalWeight
```

### 결과
- 하드 섀도우 → 부드러운 가장자리 (안티앨리어싱)
- 필터 영역 크기 조절로 소프트 섀도우 근사 가능
- 4회 텍스처 fetch로 성능 효율적

## 수식 및 알고리즘

**기본 PCF:**
$$shadow = \frac{1}{N}\sum_{i=1}^{N} \begin{cases} 1 & \text{if } z_{fragment} < tex(shadowMap, uv_i) \\ 0 & \text{otherwise} \end{cases}$$

**바이리니어 PCF (하드웨어):**
$$sample_j = tex2Dproj(shadowMap, uv + offset_j)$$
- 하드웨어가 자동으로 2×2 비교 + 보간 수행

**4샘플 4×4 커버리지:**
$$shadow = \sum_{j=0}^{3} w_j \cdot sample_j$$
- $w_j$: 각 2×2 블록의 가중치
- $offset_j$: 4개 블록 중심까지의 텍셀 오프셋

**소프트 섀도우 확장:**
필터 크기를 키우고 더 많은 샘플(예: 8×8)을 사용하면 소프트 섀도우에 근접

## UE5 관점에서의 활용
- **Shadow Map Filtering**: UE5의 기본 그림자는 PCF 기반. 이 챕터의 접근법이 직접적 기반.
- **PCSS (Percentage-Closer Soft Shadows)**: 차폐물 거리에 따라 필터 크기를 동적으로 조절. PCF의 발전형.
- **Virtual Shadow Maps**: UE5의 VSM은 매우 높은 해상도의 가상 텍스처를 사용해 앨리어싱을 근본적으로 줄임
- **Ray Traced Shadows**: 하드웨어 RT로 PCF 없이도 부드러운 그림자 가능 (면광원 → 자연스러운 소프트 섀도우)
- **Shadow Bias**: PCF와 함께 적절한 depth bias 설정이 필수 (self-shadowing 아티팩트 방지)

## 핵심 요약 (3줄)
- 섀도우 맵의 계단 현상을 GPU 하드웨어의 바이리니어 PCF를 활용해 4번의 텍스처 fetch로 효율적으로 제거한다.
- 4×4 텍셀 영역에서 16개 비교를 4개의 하드웨어 바이리니어 샘플로 근사하는 실용적 기법을 제시했다.
- 이 PCF 기반 접근법은 현대 게임 엔진 그림자 필터링의 근간이며, PCSS와 VSM으로 발전했다.
