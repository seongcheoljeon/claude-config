# Chapter 2: Rendering Water Caustics
> 저자: Juan Guardado (NVIDIA), Daniel Sánchez-Crespo (Universitat Pompeu Fabra/Novarama Technology)

## 핵심 개념
- **해결하려는 문제**: 수면 아래 바닥에 나타나는 코스틱(caustic) 패턴을 실시간으로 렌더링하는 것
- **미학 기반 접근(Aesthetics-driven)**: 물리적 정확성 대신 시각적으로 그럴듯한 결과에 집중
- **굴절 기반 광선 추적**: 수면의 파동 함수 → Snell의 법칙으로 굴절 → 바닥면과의 교차점 계산 → 빛 집중도 계산
- **프로시저럴 생성**: 완전히 절차적으로 생성되므로 셰이딩 언어로 깔끔하게 구현 가능
- **멀티패스 렌더링**: OpenGL/셰이더 기반 구현 모두 다중 패스 사용

## 기술적 세부사항

### 코스틱 생성 원리
1. 수면을 파동 함수로 정의 (사인파 합산, Perlin Noise 등)
2. 각 수면 점에서 수직 광선을 발사
3. 광선이 수면과 만나는 점에서 법선(gradient) 계산
4. **Snell의 법칙**으로 굴절된 광선 방향 계산
5. 굴절된 광선이 바닥면(평면)과 만나는 교차점 계산
6. 교차점들의 밀도가 높은 곳 = 밝은 코스틱 영역

### OpenGL 구현 (CPU 기반)
1. 1st pass: 바닥 텍스처 렌더링
2. 2nd pass: 세밀한 메시의 각 정점에서 광선 발사 → 굴절 → 바닥 교차 → per-vertex 라이팅으로 코스틱 계산
3. 3rd pass: 수면 렌더링 (환경 맵 반사)

### 셰이더 구현 (GPU 기반, Cg)
- 파동 함수, gradient, 광선-평면 교차를 모두 vertex/pixel shader에서 계산
- 옥타브(octave)를 겹쳐 더 복잡한 패턴 생성 (프랙탈 접근)
- dependent texture read로 코스틱 라이트맵을 가져와 바닥 텍스처에 합성

### 핵심 코드 구조
```
WAVESIZE = amplitude, FACTOR = frequency, SPEED = animation speed
OCTAVES = fractal octave count
wave(pt, t) = sin(pt * FACTOR + t * SPEED) * WAVESIZE
gradient = wave(pt + δ) - wave(pt - δ)  // 수치 미분
refracted_ray = Snell's law(incident, normal, η)
intercept = line-plane intersection(refracted_ray, ground_plane)
```

## 수식 및 알고리즘

**Snell의 법칙:**
$$\eta_1 \sin\theta_1 = \eta_2 \sin\theta_2$$
- $\eta_1$ = 공기의 굴절률 (1.0), $\eta_2$ = 물의 굴절률 (~1.33)

**파동 함수:**
$$wave(p, t) = A \cdot \sin(p \cdot f + t \cdot s)$$

**광선-평면 교차:**
$$distance = \frac{planeD - \mathbf{N} \cdot lineP}{\mathbf{N} \cdot lineDir}$$
$$intersection = lineP + lineDir \times distance$$

**알고리즘 흐름:**
1. 메시 정점마다 수직 광선 발사
2. 파동 함수로 수면 높이/법선 계산
3. Snell의 법칙으로 굴절 방향 계산
4. 굴절 광선과 바닥면 교차점 계산
5. 교차점을 텍스처 좌표로 사용해 코스틱 맵 fetch
6. 바닥 텍스처에 additive blending

## UE5 관점에서의 활용
- **Water Caustics in UE5**: UE5의 Water 시스템은 프로젝티브 코스틱 텍스처를 사용. 이 챕터의 프로시저럴 접근이 기반.
- **Ray Tracing Caustics**: Lumen/하드웨어 RT로 물리적으로 정확한 코스틱 가능하지만 비용이 높음
- **현대적 대안**: 프로시저럴 코스틱 텍스처 + 프로젝션이 여전히 가장 실용적. Screen-space 코스틱, photon mapping 등도 연구 중
- **Decal 기반**: UE5에서는 코스틱 패턴을 Decal로 바닥에 프로젝션하는 방식도 흔히 사용

## 핵심 요약 (3줄)
- 수면의 파동 함수와 Snell의 법칙을 결합해 실시간 코스틱을 프로시저럴하게 생성하는 기법이다.
- 물리적 정확성보다 시각적 설득력에 초점을 맞춘 미학 기반 접근법을 취한다.
- GPU 셰이더로 완전히 구현 가능하며, 프랙탈 옥타브를 추가해 복잡한 패턴을 만들 수 있다.
