# Chapter 1: Effective Water Simulation from Physical Models
> 저자: Mark Finch (Cyan Worlds)

## 핵심 개념
- **해결하려는 문제**: GPU에서 실시간으로 대규모 수체(water body)를 시뮬레이션하고 렌더링하는 것. Cyan Worlds의 *Uru: Ages Beyond Myst*에서 실제 사용됨.
- **기하학적 파동 + 동적 노멀맵**: 베이스 메시의 기하학적 변형(vertex shader)과 동적 노멀맵 생성(pixel shader)을 결합한 하이브리드 시스템
- **사인 함수 합산(Sum of Sines)**: 여러 사인파를 합산해 수면 높이와 방향을 계산하는 접근법
- **Gerstner 파동**: 사인파보다 더 뾰족한 파봉(crest)과 넓은 골(trough)을 만들어 거친 바다를 표현. 정점을 파봉 쪽으로 이동시켜 고주파 영역에 정점을 집중시킴
- **물리 기반 파라미터**: 파장, 진폭, 속도, 방향 등 물리적으로 의미 있는 파라미터로 제어

## 기술적 세부사항

### 사인파 합산 (Vertex Shader)
1. 여러 개의 사인파를 정의: 각각 파장(λ), 진폭(A), 속도(S), 방향(D)을 가짐
2. 각 정점 위치에서 모든 파동 함수를 합산해 높이(y)를 계산
3. 각 파동의 편미분을 합산해 표면 법선(normal)을 계산
4. 파장과 속도의 관계: 깊은 물에서 $S = \sqrt{g \cdot L / (2\pi)}$ (g=중력, L=파장)

### Gerstner 파동
- 사인파와 달리 정점의 x, z 좌표도 이동시킴 → 파봉에 정점이 집중
- Q 파라미터로 파봉의 뾰족함을 제어 (Q=0이면 일반 사인파, Q=1/(ωA)이면 루프 형성 직전)
- 여러 Gerstner 파동을 합산할 때 Q_i = Q / (ω_i × A_i × N) (N=파동 수)로 설정해 과도한 루핑 방지

### 동적 노멀맵 (Pixel Shader)
- 기하학적 파동으로는 표현 못하는 세밀한 물 표면 디테일을 텍스처로 캡처
- 타일링 가능한 노멀맵을 실시간 생성 (파장 4~32 텍셀)
- 기하 파동과 텍스처 파동의 파장 범위가 약간 겹치도록 설계
- 범프 환경 매핑(bump environment mapping) 파라미터를 생성해 두 시스템을 결합

### 방향 파동 vs 원형 파동
- **방향 파동**: D·(x, y) — 평면파, 넓은 바다에 적합
- **원형 파동**: |P - C| — 점 소스에서 퍼져나가는 파동, 돌이 떨어진 효과 등에 적합

## 수식 및 알고리즘

**기본 사인파 높이 함수:**
$$W_i(x, y, t) = A_i \times \sin(D_i \cdot (x, y) \times \omega_i + t \times \varphi_i)$$

**Gerstner 파동 위치:**
$$x' = x + \sum Q_i A_i D_{ix} \cos(\omega_i D_i \cdot (x,y) + \varphi_i t)$$
$$y' = \sum A_i \sin(\omega_i D_i \cdot (x,y) + \varphi_i t)$$

**개선된 보간:**
- 파봉을 더 뾰족하게: $2A \left(\frac{\sin(\cdot) + 1}{2}\right)^k$ (k로 날카로움 제어)
- 골을 더 넓게: $2A \left(1 - \left(\frac{\cos(\cdot) + 1}{2}\right)^k\right)$

**법선 계산:**
각 파동의 편미분을 합산 → Binormal, Tangent, Normal 벡터 구성

### LOD 전략 및 성능 최적화
- **파동 수 제어**: 4~8개 파동이면 설득력 있는 수면 표현 가능. 파동 추가 시 진폭을 줄여 디테일 보완
- **거리 기반 LOD**: 카메라에서 먼 영역은 기하학적 파동 수를 줄이고 노멀맵에 더 의존
- **Tessellation 활용**: 가까운 수면은 테셀레이션으로 정점 밀도를 높여 Gerstner 파봉의 해상도 확보
- **주파수 분리**: 저주파 파동(긴 파장) → 버텍스 변형, 고주파 파동(짧은 파장) → 노멀맵 디테일
- 파동 수 N이 증가하면 VS 비용이 선형 증가 → 실무에서는 파동 수보다 **파라미터 튜닝**이 더 효과적

### 한계와 확장
- Gerstner 파동은 **개방 수역(open water)**에 최적화 — 해안선 굴절, 부서지는 파도는 별도 처리 필요
- 유체 역학적 상호작용(오브젝트↔물) 없음 — 순수 시각적 시뮬레이션
- FFT 기반(Tessendorf 2001)이 통계적으로 더 정확한 해양 스펙트럼을 재현하지만, Gerstner는 파라미터 직관성과 성능 면에서 유리
- 현대적으로는 **Gerstner(실시간) + FFT(원거리) + 파티클(상호작용)** 하이브리드가 AAA 표준

## UE5 관점에서의 활용
- **Water System**: UE5의 Water 플러그인은 Gerstner 파동 기반으로 수면을 시뮬레이션. `AWaterBody` 액터의 `WaveParameters`가 이 챕터의 파동 파라미터와 직접 대응
- **Material Editor**: 노멀맵 기반 세부 파동은 UE5 머티리얼의 World Position Offset + Normal 조합으로 구현 가능
- **Single Layer Water 셰이딩 모델**: 굴절, 흡수, 산란을 물리 기반으로 처리. 이 챕터의 기하학적 파동 위에 적용
- **현대적 대안**: FFT 기반 해양 시뮬레이션(Tessendorf), 플로우맵 기반 방향 제어, Compute Shader 기반 시뮬레이션이 대세지만 Gerstner 파동은 여전히 가성비 좋은 선택
- **Niagara + Fluid Simulation**: 파티클 기반 유체는 별도 영역이지만, 수면 셰이더는 여전히 이 챕터의 접근법을 기반으로 함

## 핵심 요약 (3줄)
- 여러 사인파/Gerstner 파동을 합산해 GPU에서 실시간 수면 시뮬레이션을 구현하는 방법을 다룬다.
- Vertex Shader로 기하학적 파동, Pixel Shader로 동적 노멀맵을 생성해 거시적/미시적 디테일을 모두 표현한다.
- 물리 기반 파라미터(파장, 속도, 진폭)를 사용해 직관적이고 확장 가능한 시스템을 만들었다.
