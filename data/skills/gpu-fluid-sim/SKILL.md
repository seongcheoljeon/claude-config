---
name: gpu-fluid-sim
description: GPU 유체 시뮬레이션 구현 가이드 — Stam Stable Fluids/Navier-Stokes 기반 GPU Gems Ch.38 알고리즘, UE5 Compute Shader(RDG)/Niagara 적용 경로, Houdini Pyro/FLIP 노드 매핑, 파라미터 기본값과 검증 방법. 유체·연기·물 시뮬레이션, Navier-Stokes, advection/diffusion/projection, Jacobi solver, vorticity confinement, Niagara Grid2D/Grid3D, Gas DOP 노드 작업 시 참조.
---

# GPU 유체 시뮬레이션 (GPU Gems Ch.38)

원문: Mark J. Harris (UNC Chapel Hill), GPU Gems Ch.38
기반 알고리즘: Jos Stam, "Stable Fluids" (SIGGRAPH 1999)
원본 노트: `/mnt/c/Users/seongcheoljeon/Downloads/parallel-weaving-pixel.md` (WSL 경로 — 현재 머신에 없을 수 있음)

## 핵심 전제

- **비압축성**: ∇·u = 0
- **균질성**: ρ = const
- Operator Splitting 으로 Navier-Stokes 를 단계별로 분해해 순차 적용한다.

## 파이프라인 (1 프레임)

```
Advect velocity (Semi-Lagrangian backward trace + bilinear interp)
  → Diffuse velocity (Implicit Jacobi, α=δx²/(ν·dt), β=4+α, 20~50 iter)
  → Add Forces (Gaussian splat: u += F·dt·exp(-dist²/r))
  → Project:
      1. Divergence(w) → div texture
      2. Clear pressure → Jacobi pressure solve (α=-δx², β=4, 40~80 iter)
      3. Gradient subtract: u = w - 0.5/δx · ∇p
  → Advect scalar (dye, temperature)
  → Boundary Conditions (velocity: scale=-1, pressure: scale=+1)
```

Projection 이 비압축성을 강제하는 단계다(Helmholtz-Hodge 분해). 이걸 빼면 발산이 누적돼
필드가 폭발한다.

## 파라미터 기본값

| 항목 | 값 |
|------|---|
| Jacobi iterations (pressure) | 실시간 20~40 / 품질 60~80 |
| Jacobi iterations (diffusion) | 20~50 (ν≈0이면 skip 가능) |
| Grid 해상도 | 2D: 128²~512², 3D: 32³~128³ |
| Timestep dt | 고정 1/60 or 1/30 권장 |
| Texture format | velocity: RG16F/RG32F, pressure: R16F/R32F |

`dt` 를 프레임 델타로 쓰면 히칭 시 advection 이 셀을 건너뛰어 불안정해진다 → 고정 스텝 권장.

## 수식 Quick Reference

```
[Advection]    q(x, t+dt) = q(x - u·dt, t)                 ← backward trace + bilerp
[Diffusion]    (I - ν·dt·∇²)u_new = u_old                  ← implicit Jacobi
[Force]        u += F·dt·exp(-dist²/r)                      ← Gaussian splat
[Divergence]   div = 0.5/δx·((wR.x-wL.x)+(wT.y-wB.y))
[Pressure]     ∇²p = div(w)    α=-δx², β=4                  ← Jacobi
[Projection]   u = w - 0.5/δx·∇p
[Boundary-vel] u_boundary = -u_interior                      ← no-slip
[Boundary-p]   p_boundary = +p_interior                      ← Neumann
[Buoyancy]     F = s·(T-T0)·ĵ
[Smoke]        F = -k·d·ĵ + s·(T-T0)·ĵ
[Vorticity]    ω=∇×u, N=∇|ω|/|∇|ω||, f=ε·(N×ω)            ← confinement
[Jacobi]       x_new = (xL+xR+xB+xT + α·bC) * (1/β)
```

## GPU 구현 아키텍처

- **Slab Operation** — 각 단계를 풀스크린 패스 하나로 처리
- **Ping-Pong** — read/write 텍스처 교대. 같은 리소스를 SRV/UAV 로 동시 바인딩하지 말 것
- 필요 텍스처: velocity, pressure, divergence, dye/temperature (+ 각 ping-pong 짝)

## UE5 적용 경로

1. **Compute Shader + RDG** (가장 유연)
   - `FGlobalShader` 상속, `RWTexture2D<float2>` ping-pong
   - UE5.7+: `FRDGBuilder` + `AddPass()` 로 각 단계를 그래프 노드로 등록
   - 셰이더 구성: AdvectCS / JacobiCS / DivergenceCS / GradientSubtractCS / AddForceCS / BoundaryCS
   - RDG 가 배리어/전이를 관리하므로 수동 transition 을 넣지 말 것

2. **Niagara Grid2D / Grid3D Collection**
   - Scratch Pad / Custom HLSL 로 위 로직 직접 작성
   - 파티클-유체 coupling 이 자연스럽다
   - `VorticityConfinementScale` 파라미터 내장

3. **Material Custom Node** — 시뮬 결과 텍스처 시각화 전용

## Houdini 매핑

| GPU Gems 개념 | Houdini DOP |
|---------------|------------|
| Semi-Lagrangian advection | `Gas Advect` |
| Pressure solve (Jacobi) | `Gas Project Non-Divergent` (내부 Multigrid/PCG) |
| Diffusion | `Gas Diffuse` |
| External forces / Buoyancy | `Gas External Forces`, `Gas Buoyancy` |
| Vorticity confinement | `Gas Vorticle Forces` / `Gas Vortex Confinement` |
| Boundary | Collision SDF + `Gas Enforce Boundary` |
| Staggered grid | VDB 기본 staggered 지원 |

Pyro Solver 내부 순서: Source → Advection → Diffusion → Buoyancy → Vorticity → Projection → Dissipation

## 확장

Vorticity Confinement · 3D · Staggered Grid(MAC) · Arbitrary Boundaries ·
Free Surface · Buoyancy

## 검증

- **발산 체크**: projection 후 max|∇·u| 가 0 에 수렴하는지 (안 하면 projection/경계 버그)
- **질량 보존**: dye 총합이 dissipation 없이 유지되는지
- **대칭성**: 대칭 초기조건 → 대칭 결과 (깨지면 advection 샘플링/경계 비대칭)
- **Jacobi 수렴**: iteration 을 2배로 늘려 결과가 눈에 띄게 바뀌면 반복이 부족한 것
