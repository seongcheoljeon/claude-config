---
name: ue5-shaders
description: UE 5.7.4+ Engine/Shaders HLSL 트리(.usf/.ush) 라우터 레퍼런스. Material translator, Vertex Factory, BasePass/ShadowDepth/Velocity, legacy ShadingModels(BRDF/GBuffer)+Substrate BSDF, Lumen/Nanite/VSM/TSR HLSL 흐름, Ray/Path Tracing payload, Sky Atmosphere, Translucency/Decals, Post-process. 트리거: "엔진 셰이더 코드", "BasePass HLSL", "Substrate BSDF", "Lumen 셰이더", "Nanite 셰이더", MaterialTemplate.ush, "Vertex Factory contract", "셰이더 #define", "where is X usf". 다루지 않음: cvar (→ unreal-dev-kb), RDG C++ API 작성 (→ ue5-rdg).
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: SKILL.md routing only — see individual files for content verification level
---

# UE5 Shaders Reference

> Index for `Engine/Shaders/` (UE 5.7.4). The skill is a **router** — open the right `.md` for your question.

## First Principle

UE5 shader tree is built in 5 layers (top → bottom):

```
Material node graph (uasset, edited in editor)
   ↓ FHLSLMaterialTranslator → injects code into placeholders
MaterialTemplate.ush     (translator fills GetMaterial* slots)
   ↓ #include
VertexFactory*.ush       (geometry-type-specific input contract)
   ↓ #include
Pass shader              (BasePass / ShadowDepth / Velocity / Lumen / Nanite shade / RT CHS / …)
   ↓ #include
Common.ush + Public/Platform.ush     (HW abstraction, types, intrinsics)
```

Every PSO is the cross-product (Material × VF × Pass). Compile cost / shader explosion problems are almost always rooted in this product.

## Branch-condition cheat-sheet

The most-used `#if` conditions when reading shader code:

| Condition | Meaning |
|-----------|---------|
| `SUBSTRATE_ENABLED` | Engine build option — Substrate material system on |
| `MATERIAL_IS_SUBSTRATE` | Per-material — uses Substrate node graph |
| Both 1 | Path → `SubstrateEvaluateBSDF` (closure tree) |
| Either 0 | Path → legacy `ShadingModels.ush` `IntegrateBxDF` |
| `MATERIALBLENDING_TRANSLUCENT` / `_ADDITIVE` / `_MODULATE` | BasePass rebinds `SceneTextures` to `TranslucentBasePass` UB |
| `IS_NANITE_SHADING_PASS && IS_BASE_PASS` | `COMPILER_FORCE_WAVE32_MODE` (WPO register pressure) |
| `SHADING_PATH_MOBILE` | Mobile forward+/deferred path |
| `SHADING_PATH_DEFERRED` | Desktop deferred (default for opaque) |
| `FORWARD_SHADING` | Forward+ desktop |
| `USE_VERTEX_FACTORY_FWD` | translator forward-includes VF (`/Engine/Generated/VertexFactoryFwd.ush`) |
| `MATERIAL_LWC_ENABLED` | Large World Coordinates on (FP64-equivalent emulation) |
| `PIXELSHADER` / `VERTEXSHADER` / `COMPUTESHADER` | Stage selection |
| `ADAPTIVE_VOLUMETRIC_SHADOW_MAP` | BasePass includes `HeterogeneousVolumesAdaptiveVolumetricShadowMapSampling.ush` |

## Routing table

Pick the file that matches your question type:

| Question shape | File |
|---------------|------|
| "Where is file X / what does folder Y contain?" | [catalog.md](catalog.md) |
| "What does `#define FOO` mean? what bit is BAR?" | [defines.md](defines.md) |
| "What's the signature of function Z? where is struct S defined?" | [api.md](api.md) |
| "Why does my shader silently take branch P?" / debugging | [quirks.md](quirks.md) |
| "How does BasePass / Material / VF / GBuffer work end-to-end?" | [flows/basepass.md](flows/basepass.md) |
| "How does Lumen GI/reflection compute one pixel?" | [flows/lumen.md](flows/lumen.md) |
| "How does Nanite go from mesh to pixel?" | [flows/nanite.md](flows/nanite.md) |
| "How are VSM pages allocated, marked, projected?" | [flows/vsm.md](flows/vsm.md) |
| "What are TSR's 10 stages?" | [flows/tsr.md](flows/tsr.md) |
| "RT vs PT, payload types, mask bits?" | [flows/rt_pt.md](flows/rt_pt.md) |
| "Sky / Cloud / Fog / Heterogeneous Volumes pipeline?" | [flows/atmosphere.md](flows/atmosphere.md) |
| "Translucency / Decals / MegaLights / SSRT / Hair?" | [flows/translucency.md](flows/translucency.md) |
| "Bloom / DOF / MotionBlur / SSD denoise / ACES tonemap?" | [flows/postprocess.md](flows/postprocess.md) |

## Verification legend

Each reference file declares its verification level in frontmatter:

- `full` — every claim was verified against the live source (file paths exist, line numbers match, function signatures read directly).
- `partial` — file paths and major struct/function names verified; some narrative inferred from naming.
- `inferred` — file existence verified; behavior described from name/role only. **Treat as starting hypothesis, not ground truth.**

When working on production code, **always re-read the source** before relying on a claim — the engine moves fast and any mismatch with reality should be reported back so this skill can be updated.

## Out of scope

- C++ rendering code (`Engine/Source/Runtime/Renderer/`) — separate concern.
- Niagara shaders — live in `Engine/Plugins/FX/Niagara/Shaders/`, not in this tree.
- Per-platform RHI shader compilation pipeline (`ShaderCompiler*.cpp`).
- Material editor UX, asset cooking.

---

## Companion plugins

본 plugin은 **Engine/Shaders HLSL 트리 라우터**에 특화. 다음 plugin과 동시 활성화 시 시너지:

| 시나리오 | 협력 plugin | 본 plugin 역할 | 협력 plugin 역할 |
|---|---|---|---|
| 셰이더 디버깅/시각화 | `unreal-dev-kb` | HLSL 코드 위치/의미 | `r.Shaders.*` cvar, ShowFlag, ViewMode |
| C++ 패스에서 셰이더 호출 | `ue5-rdg` | 호출 대상 .usf 분석 | C++ 패스 작성 패턴 |
| 머티리얼 Custom Node HLSL | `unreal-dev-kb` | MaterialTemplate.ush 트리 | Custom Node 헬퍼 함수 카탈로그 |

**검색 흐름 권장**: 본 plugin으로 셰이더 코드 위치 파악 → `unreal-dev-kb`의 시각화 명령으로 GPU 출력 확인 → `ue5-rdg`로 호출 컨텍스트 확장.
