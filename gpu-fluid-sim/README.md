# gpu-fluid-sim

GPU 기반 Eulerian fluid simulation (Stable Fluids, Navier-Stokes) 알고리즘 가이드 플러그인.

## 다루는 영역

- **Pipeline**: Advect → Diffuse → AddForce → Project → Boundary
- **Advection**: Semi-Lagrangian / MacCormack / BFECC (선택 기준 + 트레이드오프)
- **Pressure solve**: Jacobi / Red-Black Gauss-Seidel / Multigrid / PCG
- **Boundary**: no-slip / free-slip / Neumann
- **Vorticity Confinement**, **Curl Noise**, **Buoyancy** (smoke)
- **CFL 조건**, **MAC vs Collocated grid**
- **GPU 구현**: Ping-pong textures, FP precision (R32F pressure 필수)
- **UE5 매핑**: Compute Shader, Niagara Grid2D/3D Collection
- **Houdini DOP 매핑**: Gas Advect / Project Non-Divergent / Pyro Solver 분해

## 자동 트리거

다음 키워드를 포함한 질문에 자동 활성화:
- Navier-Stokes, "Stable Fluids", "fluid simulation"
- "smoke/fire 시뮬", "Pyro solver", "Niagara Grid2D/3D"
- MacCormack, BFECC, "Jacobi pressure", "vorticity confinement"

## 명시적 호출

```text
/gpu-fluid-sim
```

## 함께 사용하면 좋은 plugin

- `ue5-rdg` — UE5 Compute Shader로 구현 시 RDG Pass 작성 패턴
- `unreal-dev-kb` — UE5 Niagara Grid 사용 시 `fx.Niagara.*` cvar (튜닝/디버깅)
- `ue5-shaders` — HLSL 셰이더 컨벤션, 헬퍼 함수
- `hdk-reference` — Houdini DOP/Pyro custom 구현 시 HDK API
