# Chapter 19: Image-Based Lighting
> 저자: Kevin Bjorke, NVIDIA

## 핵심 개념
- **해결하려는 문제**: 전통적인 큐브맵 반사는 무한히 먼 환경만 반영하여, 실내 환경에서 오브젝트 위치에 따른 반사 변화를 표현하지 못하는 한계를 극복
- **핵심 아이디어**:
  1. **Localized Cube Map**: 큐브맵을 무한 거리가 아닌 유한 크기의 지오메트리(반지름 1.0의 구)로 취급
  2. **Lighting Space 좌표계**: 큐브맵 자체 기준의 새로운 좌표 프레임. 오브젝트 위치에 따른 반사 계산 가능
  3. **구-레이 교차**: lighting space에서의 레이-구 교차로 올바른 반사 룩업 포인트 결정
  4. **Fresnel 감쇠**: 시선 각도에 따른 반사 강도 변조 (Schlick 근사)
  5. **Bump Mapping 통합**: 탄젠트 공간 노멀맵으로 표면 법선 교란 후 반사 계산

## 기술적 세부사항

### 좌표 공간 변환 파이프라인
1. 버텍스 위치 → `WorldXf` → 월드 공간
2. 월드 공간 → `LightingXf` → lighting space
3. 노멀/탄젠트/바이노멀: 역전치 행렬(`WorldITXf`, `LightingITXf`)로 변환
4. 시선 벡터: `LightingEyePos - surfacePos` (lighting space에서 계산)

### 반사 벡터 계산
```hlsl
// 범프 맵 적용
Nb = Nu + (bumps.x * Tu + bumps.y * Bu);
Nb = normalize(Nb);

// Fresnel 계산
fres = KrMin + (Kr - KrMin) * pow(1.0 - abs(vdn), FresExp);

// 반사 벡터
reflVect = normalize(reflect(Vu, Nb));
```

### 구-레이 교차 (핵심 알고리즘)
Lighting space의 단위구와 반사 레이의 교차점을 2차 방정식으로 풀기:

```hlsl
b = -2.0 * dot(reflVect, IN.LightingPos);
c = dot(IN.LightingPos, IN.LightingPos) - 1.0;
discrim = b * b - 4.0 * c;

// 판별식 > 임계값이면 교차 존재
if (discrim > 0.00001) {
  nearT = (sqrt(discrim) - b) / 2.0;
  // 교차점으로 큐브맵 룩업
  reflVect = nearT * reflVect - IN.LightingPos;
}
reflColor = fres * texCUBE(EnvMap, reflVect);
```

### Fresnel 근사 (Schlick 1994)
```hlsl
fres = KrMin + (Kr - KrMin) * pow(1.0 - abs(vdn), FresExp);
```
- `KrMin`: 최소 반사율 (보통 0.05 × Kr)
- `Kr`: 반사 강도
- `FresExp`: 지수 (기본 5.0, 낮으면 래커 느낌)
- 최적화: FresExp=4.0이면 곱셈 2번으로 pow() 대체 가능

### Vertex Shader 구조
- 입력: Position, UV, Normal, Tangent, Binormal
- 4개 행렬 변환: WorldViewProj, World, LightingXf, LightingITXf
- 출력: 클립 공간 위치, 텍스처 좌표, lighting space의 노멀/탄젠트/바이노멀, 시선 벡터, 표면 위치

### Pixel Shader 구조
1. 입력 벡터 정규화
2. 노멀맵 샘플링: `bumps = Bumpiness × (tex2D(NormalMap) - 0.5)`
3. 범프 노멀 계산: `Nb = Nu + bumps.x × Tu + bumps.y × Bu`
4. 시선 벡터 + Fresnel 계산
5. 반사 벡터 → 구 교차 → 큐브맵 룩업
6. 최종: `SurfColor × reflColor`

## 수식 및 알고리즘

### 구-레이 교차 2차 방정식
$$b = -2(\mathbf{r} \cdot \mathbf{P}), \quad c = \mathbf{P} \cdot \mathbf{P} - 1$$
$$\text{discrim} = b^2 - 4c$$
$$t = \frac{\sqrt{\text{discrim}} - b}{2}$$

교차점: $\mathbf{Q} = t \cdot \mathbf{r} - \mathbf{P}$ (이것이 큐브맵 룩업 방향)

### Schlick Fresnel 근사
$$F(\theta) = F_{min} + (F_{max} - F_{min})(1 - |\cos\theta|)^5$$

### Diffuse IBL
사전 컨볼루션된 diffuse 큐브맵: 노멀 방향으로 단순 룩업. 위치 의존성 없이 Lambertian 적분을 사전 계산.

### 행렬 사전 결합 최적화
CPU에서 변환 행렬을 사전 결합하면 버텍스 셰이더의 행렬 곱 2개를 1개로 줄일 수 있다.

## UE5 관점에서의 활용

- **UE5 Reflection Capture**: 이 챕터의 Localized Cube Map 개념이 직접 발전한 것. UE5의 Sphere/Box Reflection Capture가 정확히 이 기법을 사용
- **Parallax-Corrected Cubemap**: UE5의 Box Reflection Capture는 구 대신 박스와의 레이 교차로 parallax correction을 수행 — 이 챕터의 구 교차와 동일한 원리
- **Fresnel**: UE5의 PBR 셰이딩에서 Schlick Fresnel은 표준. F0 (금속의 경우 albedo, 비금속의 경우 0.04) 기반
- **Lumen과의 비교**: Lumen의 Screen Probe + Radiance Cache가 이 기법의 상위 호환. 위치별 조명 변화를 동적으로 캡처하지만, 비용이 훨씬 큼
- **현대적 대안**: Planar Reflection, SSR (Screen-Space Reflection), RT Reflection이 localized cubemap의 한계를 보완
- **Bump + IBL**: UE5에서도 노멀맵이 반사 방향에 영향. roughness + 노멀맵 조합이 이 챕터의 bump + localized cubemap 조합을 대체

## 핵심 요약 (3줄)
- Localized Cube Map은 큐브맵을 유한 크기의 구로 취급하고, 레이-구 교차로 오브젝트 위치에 따른 반사 변화를 표현하는 기법이다
- Lighting Space 좌표 변환 + Schlick Fresnel + 범프 매핑을 조합하여 위치 의존적인 IBL을 실시간으로 구현한다
- 이것이 UE5의 Reflection Capture (Sphere/Box)의 직접적 원조이며, Parallax-Corrected Cubemap이라는 이름으로 현재도 널리 사용된다
