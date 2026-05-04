# Chapter 8: Simulating Diffraction
> 저자: Jos Stam (Alias Systems)

## 핵심 개념
- **해결하려는 문제**: CD, 홀로그램 포장지 등 미세 구조 표면에서 빛의 파동 성질로 인해 발생하는 회절(diffraction) 무지개 패턴을 실시간으로 시뮬레이션
- **파동 이론**: 표면 디테일이 빛의 파장(~1μm) 수준일 때 기하 광학(ray theory)이 아닌 파동 이론이 필요
- **회절 격자(Diffraction Grating)**: 평행한 좁은 반사 띠가 간격 d로 배열된 표면. 구면파 간섭으로 무지개 패턴 생성.
- **탄젠트 기반 BRDF**: 기존 법선 기반 반사 모델 대신 표면의 탄젠트 방향(미세 구조 방향)을 사용
- **SIGGRAPH 1999 논문의 실시간 간소화 버전**: Stam 1999의 일반 모델을 vertex program으로 구현

## 기술적 세부사항

### 회절의 물리
1. 평면파가 회절 격자에 입사 → 각 띠에서 구면파 발생
2. 구면파들이 서로 간섭 (보강/상쇄)
3. **보강 간섭 조건**: 인접 띠에서 온 파동의 경로차 = 파장의 정수 배
   - $d(\sin\theta_i + \sin\theta_r) = n\lambda$ (n = 정수, 회절 차수)
4. 가시광 파장(0.4~0.7μm)마다 보강 각도가 다름 → **무지개 패턴**

### 셰이더 구현 (Cg Vertex Program)
1. **입력**: 정점 위치, 법선(N), 탄젠트(T) — 탄젠트는 미세 구조 띠의 방향
2. **Half 벡터**: H = L + V (조명 방향 + 시선 방향)
3. **핵심 계산**:
   - `u = dot(T, H) * d` — 탄젠트와 half 벡터의 내적 × 격자 간격
   - 각 회절 차수(n=1~7)마다 색상 기여 계산
   - 파장을 RGB 색상으로 매핑 (가우시안 근사)
4. **비등방성(Anisotropic) 하이라이트**: u=0 케이스에 대한 추가 하이라이트

### 파장→색상 변환
```cpp
float3 blend3(float3 x) {
  float3 y = 1 - x * x;
  y = max(y, float3(0,0,0));
  return y;
}
// 각 차수 n에 대해:
float y = 2 * u / n - 1;  // -1~1로 정규화
cdiff += blend3(float4(4*(y-0.75), 4*(y-0.5), 4*(y-0.25)));
```
- R, G, B 각각의 중심을 0.75, 0.5, 0.25에 두고 가우시안 형태로 매핑
- 여러 차수의 기여를 합산하면 무지개 패턴 생성

### 비등방성 하이라이트
```cpp
float w = dot(N, H);
float e = r * u / w;
float c = exp(-e * e);  // 가우시안 폴오프
anis = hiliteColor * c;
```

## 수식 및 알고리즘

**회절 격자 조건:**
$$d \cdot (\sin\theta_i + \sin\theta_r) = n\lambda$$
- d: 격자 간격, n: 회절 차수, λ: 파장

**Half 벡터 기반 조건 (벡터 형태):**
$$u = \mathbf{T} \cdot \mathbf{H} \cdot d$$
- 보강 간섭: $u = n\lambda$

**n번째 회절 차수의 색상:**
$$\lambda_n = \frac{u}{n}$$
$$color_n = blend3\left(4\left(\frac{2u/n - 1}{1} - [0.75, 0.5, 0.25]\right)\right)$$

**최종 색상:**
$$C = \sum_{n=1}^{7} color_n + anisotropic\_highlight$$

## UE5 관점에서의 활용
- **Thin Film / Iridescence**: UE5의 Clear Coat 셰이딩 모델이 유사한 간섭 효과를 지원. 비누 방울, 자동차 도장 등.
- **Custom BRDF**: 회절 효과는 커스텀 셰이딩 모델이나 머티리얼 함수로 구현 가능
- **현대적 접근**: 물리 기반 렌더링에서 thin-film interference 모델이 정립됨. 회절은 여전히 특수 효과 취급.
- **Anisotropic Shading**: UE5의 Anisotropy 파라미터가 비등방성 반사를 지원. 브러시드 메탈, 머리카락 등에 활용.
- **CD/홀로그램 효과**: 이 챕터의 접근법을 머티리얼 함수로 직접 포팅 가능 (탄젠트 맵 + 다중 차수 합산)

## 핵심 요약 (3줄)
- 빛의 파동 이론과 회절 격자 모델을 기반으로 CD 표면의 무지개 반사를 실시간 시뮬레이션한다.
- 탄젠트 벡터와 half 벡터의 내적으로 회절 차수별 색상을 계산하는 간결한 vertex program을 제시했다.
- 이 접근법은 현대의 thin-film interference와 anisotropic shading 모델의 초기 형태다.
