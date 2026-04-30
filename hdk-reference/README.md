# hdk-reference

Houdini 21.0 HDK (Houdini Development Kit) C++ 레퍼런스 플러그인. 공식 HDK 샘플 코드에서 추출한 검증된 패턴만 포함.

## 다루는 영역

- **DSO Entry Points**: SOP/DM/GUI/SIM/RAY/VEX/COP2/CHOP/Custom Prim/OBJ/ROP/DM Mouse
- **SOP Patterns**: 레거시 `SOP_Node` 상속, 신규 GA-based SOP, GU_Detail 조작
- **Custom Primitive**: GEO → GT → GR (3-layer 파이프라인)
- **Viewport Render Hooks**: `DM_RenderTable`, RE_Geometry/RE_Shader
- **Packed Primitives**: `GU_PackedImpl` 패턴
- **Mantra Procedurals**: `RAY_Procedural` + `RAY_PixelFilter`
- **Simulation Solvers**: `SIM_Data` + `IMPLEMENT_DATAFACTORY`
- **VEX Custom Functions**: `newVEXOp` 등록 + `CVEX_*` API
- **Core API 패턴**: `GA_Handle`, `GA_AttributeOwner`, `PRM_Template`, Data ID 관리
- **GPU Acceleration**: CUDA 커널 통합 (선택)
- **Debugging**: gdb, valgrind, `UT_ASSERT`, `HOUDINI_DSO_ERROR`, crash recovery

## 자동 트리거

다음 키워드를 포함한 질문에 자동 활성화:
- "Houdini HDK", "SOP plugin", "VEX custom function"
- "DSO 작성", "custom primitive", "viewport hook"
- "HDK 디버깅"

## 명시적 호출

```text
/hdk-reference
```

## 함께 사용하면 좋은 plugin

- `gpu-fluid-sim` — Houdini Pyro/Gas DOP에 fluid simulation 구현 시

UE5 영역과는 별개 컨텍스트라 다른 plugin들과 함께 트리거되지 않도록 description 조정됨.
