# Chapter 38: Fast Fluid Dynamics Simulation on the GPU
> 저자: Mark J. Harris (University of North Carolina at Chapel Hill)

## 핵심 개념
- **해결하려는 문제**: Navier-Stokes 방정식 기반 유체 시뮬레이션을 GPU에서 실시간 수행
- Jos Stam의 **Stable Fluids** 기법을 GPU에 이식
- CPU 대비 최대 **6배 속도 향상** (GeForce FX 기준)
- 물, 연기, 불, 구름 등 다양한 유체 현상의 기초가 되는 범용 빌딩 블록
- 수학적 원리부터 GPU 구현까지 전 과정을 다룸

## 기술적 세부사항

### Navier-Stokes 방정식
비압축성 유체의 운동을 기술하는 편미분 방정식:

$$\frac{\partial \mathbf{u}}{\partial t} = -(\mathbf{u} \cdot \nabla)\mathbf{u} + \nu \nabla^2 \mathbf{u} + \mathbf{f} - \frac{1}{\rho}\nabla p$$

$$\nabla \cdot \mathbf{u} = 0$$

- $\mathbf{u}$: 속도 벡터 필드
- $p$: 압력
- $\nu$: 점성 계수 (kinematic viscosity)
- $\rho$: 밀도
- $\mathbf{f}$: 외력

### 풀이 5단계 (Operator Splitting)
1. **Advection (이류)**: 속도 필드를 따라 유체 속성 이동
2. **Diffusion (확산)**: 점성에 의한 속도 확산
3. **Force Application (외력 적용)**: 사용자 입력 등 외력
4. **Pressure Projection**: 발산 제거 → 비압축성 조건 충족
5. **Boundary Conditions**: 경계 조건 적용

### 핵심 알고리즘

#### Semi-Lagrangian Advection
- 전진적(forward) 이류는 GPU에서 불가능 (scatter 필요)
- **역방향 추적**: 현재 위치에서 속도 역방향으로 추적하여 이전 값 읽기
- 안정적(unconditionally stable) — 큰 타임스텝에서도 폭발하지 않음
```
// 의사코드
new_value[x] = texture_lookup(old_value, x - u[x] * dt)
```

#### Jacobi Iteration (야코비 반복법)
- Poisson 방정식($\mathbf{A}\mathbf{x} = \mathbf{b}$) 풀이에 사용
- 단순하고 GPU 병렬화에 적합
- 각 반복: 이웃 4개 셀의 평균으로 업데이트
$$x_{i,j}^{(k+1)} = \frac{x_{i-1,j}^{(k)} + x_{i+1,j}^{(k)} + x_{i,j-1}^{(k)} + x_{i,j+1}^{(k)} + \alpha \cdot b_{i,j}}{\beta}$$
- 수렴이 느리지만, 실시간에서는 20~50 반복이면 충분

### GPU 구현 세부사항

#### 텍스처 = 그리드
- 2D 속도 필드 → RGBA 텍스처 (R=u, G=v)
- 압력 필드 → 별도 텍스처
- 발산 필드 → 별도 텍스처

#### 피드백 = Ping-Pong 버퍼
- Render-to-Texture 시 읽기/쓰기 동시 불가
- 두 텍스처를 교대로 사용 (읽기 텍스처 ↔ 쓰기 텍스처)

#### 경계 조건 프래그먼트 프로그램
```cg
void boundary(half2 coords : WPOS,
              half2 offset : TEX1,      // 경계 오프셋
              out half4 bv : COLOR,
              uniform half scale,        // 속도=-1, 압력=1
              uniform samplerRECT x)
{
    bv = scale * h4texRECT(x, coords + offset);
}
```
- 속도: scale=-1 (no-slip, 벽에서 반사)
- 압력: scale=1 (Neumann 경계 조건)

### 전체 시뮬레이션 루프
```
for each timestep:
    1. Advect(velocity, velocity, dt)    // 자기 이류
    2. Diffuse(velocity, viscosity, dt)  // Jacobi 반복
    3. ApplyForces(velocity, forces, dt) // 외력
    4. ComputeDivergence(velocity)       // 발산 계산
    5. SolvePressure(divergence)         // Jacobi 반복
    6. SubtractGradient(velocity, pressure) // 발산 제거
    7. ApplyBoundaryConditions()         // 경계 처리
```

## 수식 및 알고리즘

### Helmholtz-Hodge 분해
모든 벡터 필드를 발산-없는(divergence-free) 부분과 기울기(gradient) 부분으로 분해:
$$\mathbf{w} = \mathbf{u} + \nabla p$$

여기서 $\nabla \cdot \mathbf{u} = 0$. 압력 Poisson 방정식을 풀어 $p$를 구한 후:
$$\mathbf{u} = \mathbf{w} - \nabla p$$

### Poisson 압력 방정식
$$\nabla^2 p = \nabla \cdot \mathbf{w}$$

## UE5 관점에서의 활용
- UE5의 **Niagara Fluid Simulation** 모듈이 이 챕터의 직접적 후계
- **FluidNinja**, **Chaos Fluids** 등 UE5 플러그인이 GPU 유체 시뮬레이션 활용
- 현대 구현은 Compute Shader로 — 프래그먼트 프로그램 대신 직접 RWTexture 접근
- **3D Navier-Stokes**로 확장 (이 챕터는 2D)
- 현대적 대안:
  - **Position-Based Fluids (PBF)**: 입자 기반 접근, Niagara에서 사용
  - **SPH (Smoothed Particle Hydrodynamics)**: 라그랑지안 방법
  - **FLIP/PIC**: 하이브리드 그리드-입자 방법 (Houdini 등)
  - Semi-Lagrangian advection은 여전히 핵심 기법

## 핵심 요약 (3줄)
1. Navier-Stokes 방정식을 Operator Splitting(이류→확산→외력→압력 투영)으로 분해하고, 각 단계를 프래그먼트 프로그램으로 구현한다.
2. Semi-Lagrangian 역추적으로 안정적 이류, Jacobi 반복으로 Poisson 방정식을 풀며, 피드백은 핑퐁 버퍼로 처리한다.
3. 이 기법은 현대 GPU 유체 시뮬레이션(Niagara, Compute Shader 기반)의 직접적 기초가 된다.
