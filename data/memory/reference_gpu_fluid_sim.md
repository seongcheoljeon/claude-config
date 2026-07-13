---
name: GPU Gems Ch.38 Fluid Simulation 학습 노트
description: Stam Stable Fluids 기반 GPU 유체 시뮬 알고리즘(Navier-Stokes) + UE5 Compute Shader/Niagara + Houdini Pyro/FLIP 적용 가이드. 유체 시뮬, Navier-Stokes, Niagara fluid, Pyro solver 관련 작업 시 참조.
type: reference
originSessionId: d63a7e37-026b-4de2-a8e8-1e3c8ff78422
---
## 원본 파일

`/mnt/c/Users/seongcheoljeon/Downloads/parallel-weaving-pixel.md`

원문: Mark J. Harris (UNC Chapel Hill), GPU Gems Ch.38
기반 알고리즘: Jos Stam, "Stable Fluids" (SIGGRAPH 1999)

---

## 커버 범위 (12섹션)

1. 핵심 전제 조건 — 비압축성(∇·u=0), 균질성(ρ=const)
2. 수학적 배경 — Navier-Stokes 방정식, 벡터 미적분 연산자, Helmholtz-Hodge 분해, Operator Splitting
3. 각 단계 상세 구현 — Advection / Diffusion / Force / Projection
4. Boundary Conditions — No-slip(velocity) / Neumann(pressure)
5. GPU 구현 아키텍처 — Slab Operation, Ping-Pong 패턴, 필요 텍스처 목록
6. 전체 시뮬레이션 파이프라인 (1 프레임 흐름도)
7. 확장 — Vorticity Confinement, 3D, Staggered Grid(MAC), Arbitrary Boundaries, Free Surface, Buoyancy
8. Unreal Engine 적용 전략
9. Houdini 적용 전략
10. 핵심 수식 Quick Reference
11. 참고 문헌
12. Verification(검증 방법)

---

## 핵심 알고리즘 파이프라인 (1 프레임)

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

---

## 주요 파라미터 기본값

| 항목 | 값 |
|------|---|
| Jacobi iterations (pressure) | 실시간 20~40 / 품질 60~80 |
| Jacobi iterations (diffusion) | 20~50 (ν≈0이면 skip 가능) |
| Grid 해상도 | 2D: 128²~512², 3D: 32³~128³ |
| Timestep dt | 고정 1/60 or 1/30 권장 |
| Texture format | velocity: RG16F/RG32F, pressure: R16F/R32F |

---

## UE5 적용 경로 (3가지)

1. **Compute Shader + RDG** (가장 유연)
   - `FGlobalShader` 상속, `RWTexture2D<float2>` ping-pong
   - UE5.7+: `FRDGBuilder` + `AddPass()`로 각 단계를 그래프 노드 등록
   - Shader 파일 구조: AdvectCS / JacobiCS / DivergenceCS / GradientSubtractCS / AddForceCS / BoundaryCS

2. **Niagara Grid2D / Grid3D Collection**
   - Scratch Pad / Custom HLSL로 위 로직 직접 작성
   - 파티클-유체 coupling 자연스러움
   - `VorticityConfinementScale` 파라미터 내장

3. **Material Custom Node** (시각화 전용)
   - 시뮬 결과 텍스처 바인딩 후 렌더링

---

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

Pyro Solver 내부 구조: Source → Advection → Diffusion → Buoyancy → Vorticity → Projection → Dissipation

---

## Quick Reference 수식

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
