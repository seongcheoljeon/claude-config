---
name: gpu-fluid-sim
description: GPU Eulerian fluid simulation (Stable Fluids / Navier-Stokes) 알고리즘 가이드. UE5 Compute Shader/Niagara Grid, Houdini Gas OpenCL/Pyro 적용. Advection(semi-Lagrangian/MacCormack/BFECC), Pressure Jacobi/Red-Black GS, Vorticity Confinement, Buoyancy, Curl Noise. 트리거: Navier-Stokes, "Stable Fluids", "fluid simulation", "smoke/fire 시뮬", "Pyro solver", "Niagara Grid2D/3D", MacCormack, BFECC, "Jacobi pressure", "vorticity confinement". 다루지 않음: 파티클 기반(FLIP/PIC/APIC) 일반 구현, Niagara cvar (→ unreal-dev-kb).
---

# GPU Fluid Simulation (Stable Fluids / GPU Gems Ch.38)

## When to use
- 2D/3D Eulerian fluid, smoke, fire, 유체 시뮬 구현
- UE5 Compute Shader 또는 Niagara Grid2D/Grid3D Collection
- Houdini Pyro/FLIP custom, Gas OpenCL DOP 포팅
- **주의**: 이 스킬은 Eulerian(격자) 방식 전용. 파티클 기반(FLIP/PIC/APIC)은 별개 접근법.

## Pipeline (per frame)
1. **Advect velocity** — semi-Lagrangian backward trace + bilerp (unconditionally stable)
2. **Diffuse** (optional, ν>0) — implicit Jacobi 20~50회
3. **Add forces** — Gaussian splat (F·dt·exp(-r²))
4. **Project** — ∇²p = ∇·w Poisson Jacobi 40~80회 → u = w − ∇p
5. **Advect scalars** (dye, temperature)
6. **Boundary** — velocity: u_b = −u_interior (no-slip), pressure: p_b = +p_interior (Neumann)

## Algorithm variants & when to swap

### Advection
| 방법 | 특성 | 선택 기준 |
|---|---|---|
| Semi-Lagrangian | 1차, 무조건 안정, 구현 단순 | 기본값 |
| **MacCormack** | 2차, 에러 보정 2패스 | 와류 디테일이 뭉개질 때 |
| **BFECC** | MacCormack 개선, 오버슛 억제 | 디테일 보존 + 안정성 |

> Semi-Lagrangian은 자연 감쇠(에너지 소실) 발생 → BFECC 또는 Vorticity Confinement로 보상.

### Pressure solve
| 방법 | 수렴 속도 | 선택 기준 |
|---|---|---|
| Jacobi | 느림 | 구현 단순, 실시간 소규모 |
| **Red-Black Gauss-Seidel** | Jacobi 대비 ~2× | in-place 가능, GPU 친화적 |
| **Multigrid / PCG** | 훨씬 빠름 | 고해상도, Houdini 내부 방식 |

### CFL 조건
Semi-Lagrangian은 발산하지 않으나 정확도를 위해: `dt · |u_max| / δx ≤ 1~5` 권장.

### Grid 구조
- 이 스킬의 공식은 **collocated grid** 기준.
- **MAC / Staggered grid** 사용 시 velocity 샘플 위치가 face-center로 바뀌어 divergence/gradient 인덱싱 달라짐.
- Houdini VDB는 기본 staggered — `Gas Project Non-Divergent` 사용 시 자동 처리됨.

## Key formulas (quick reference)
- Jacobi general: `x_new = (xL+xR+xB+xT + α·b)/β`
  - Diffusion: α = δx²/(ν·dt), β = 4+α
  - Pressure:  α = −δx²,        β = 4
- Divergence: `(wR.x−wL.x + wT.y−wB.y) / (2δx)`
- Gradient subtract: `u −= 0.5/δx · (pR−pL, pT−pB)`
- Vorticity confinement: ω = ∇×u, N = ∇|ω|/|∇|ω||, f = ε·(N×ω)
- Buoyancy (smoke): F = −k·d·ĵ + s·(T−T₀)·ĵ
- Curl noise (난류 주입): u += curl(noise(x,t))  ← 저비용 디테일 추가

## GPU implementation essentials
- Ping-pong 2 textures (RG16F/32F velocity, **R32F** pressure, R16F/32F divergence)
- 5-tap stencil (L/R/B/T + center) per shader — all neighbor-local
- UE5: `RWTexture2D<float2>`, `[numthreads(8,8,1)]`, `FRDGBuilder` 권장
- UE5 셰이더 파일 구조: `AdvectCS / JacobiCS / DivergenceCS / GradientSubtractCS / AddForceCS / BoundaryCS`
- Niagara: Grid2D/3D Collection + Custom HLSL scratch pad
- Houdini: Gas OpenCL DOP, 또는 Pyro Solver 내부 DOP 재구성

## Houdini DOP 매핑
| GPU Gems 개념 | Houdini DOP |
|---|---|
| Semi-Lagrangian advection | `Gas Advect` |
| Pressure solve | `Gas Project Non-Divergent` (내부 Multigrid/PCG) |
| Diffusion | `Gas Diffuse` |
| External forces / Buoyancy | `Gas External Forces`, `Gas Buoyancy` |
| Vorticity confinement | `Gas Vorticle Forces` / `Gas Vortex Confinement` |
| Boundary (no-slip) | Collision SDF + `Gas Enforce Boundary` |

**Pyro Solver 내부 순서**: Source → Advection → Diffusion → Buoyancy → Vorticity → Projection → Dissipation

## Recommended parameters
| | 실시간 | 고품질 |
|---|---|---|
| Grid (2D) | 128² ~ 256² | 512²+ |
| Grid (3D) | 32³ ~ 64³ | 128³+ |
| Pressure Jacobi | 20~40 | 60~80 |
| Diffusion Jacobi | 20~30 | 40~50 |
| dt | 1/60 (고정 권장) | 1/60 or 1/30 |
| Vorticity ε | 0.1~2 (smoke) | 0.05~10 |
| Force radius | 4~16 셀 | 4~16 셀 |

## Common pitfalls
- **FP16 pressure**: 누적 오차로 발산 → pressure 텍스처는 반드시 **R32F**
- **Ping-pong self-read**: 바인딩 슬롯 swap 잊으면 같은 텍스처 read+write → 검은 화면 / 폭발
- **Vorticity ε 과다**: ε > 10이면 시뮬 폭발 → 0.05~2 범위에서 시작
- **Gaussian radius 너무 작음**: 1~2셀이면 aliasing → 4셀 이상 권장
- **Semi-Lagrangian 감쇠**: 와류 소멸 빠름 → BFECC 또는 Vorticity Confinement 병행
- **경계 타입 혼동**: no-slip(velocity) `u_b = −u_interior`, free-slip = 법선 성분만 반사, Neumann(pressure) `p_b = +p_interior`
- **MAC grid 오프셋 무시**: Houdini VDB staggered에서 collocated 공식 그대로 쓰면 발산

## Full reference
전체 수식 유도, Helmholtz-Hodge 분해, 모든 HLSL 예제 셰이더, UE5/Houdini 상세 매핑:
→ `C:\Users\seongcheoljeon\docs\gpu-gems-ch38-fluid.md`

## Verification checklist
- [ ] Projection 후 divergence 텍스처 시각화 → ≈0
- [ ] Jacobi 반복 10→20→40→80 비교, vortex 수렴 확인
- [ ] Boundary leak 체크 (벽 근처 유동)
- [ ] Dye advection으로 와류 자연스러움 검사
- [ ] Semi-Lagrangian: 큰 dt에서도 blow-up 없어야 함
- [ ] BFECC 교체 시 오버슛 체크 (dye 값이 0~1 밖으로 나가지 않는지)
- [ ] Pressure R32F 확인 (R16F로 실수 시 장시간 시뮬에서 발산)

---

## 함께 활성화되면 좋은 plugin

본 plugin은 **유체 시뮬 알고리즘 가이드**에 특화. 다음 plugin과 동시 활성화 시 시너지:

| 시나리오 | 협력 plugin | 본 plugin 역할 | 협력 plugin 역할 |
|---|---|---|---|
| UE5에서 Compute Shader로 구현 | `ue5-rdg` | 알고리즘 + HLSL 의사코드 | RDG Compute Pass 작성 패턴 |
| UE5 Niagara Grid 사용 | `unreal-dev-kb` | Grid2D/3D 알고리즘 | `fx.Niagara.*` cvar (튜닝/디버깅) |
| HLSL 셰이더 문법/구조 | `ue5-shaders` | 알고리즘 | 엔진 셰이더 컨벤션, 헬퍼 함수 |
| Houdini DOP/Pyro 구현 | `hdk-reference` | Pyro 매핑 | Houdini HDK API |

**검색 흐름 권장**: 알고리즘 결정(본 plugin) → 플랫폼 선택 (UE5/Houdini) → 해당 플랫폼 plugin으로 구현.
