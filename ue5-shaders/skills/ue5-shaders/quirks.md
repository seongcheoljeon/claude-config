---
name: quirks
description: Branch-condition gotchas, subtle behaviors, debug tips, and breaking-change risk. Use when a shader silently behaves wrong or you need to invalidate caches.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: full (every claim verified against the live source or comments in source)
---

# Quirks & Debug

## Forced re-compile of all material shaders

`Private/MaterialTemplate.ush` line ~67:

```hlsl
#pragma message("UESHADERMETADATA_VERSION E745A0A0-E5E2-4976-B407-F7C36FCE9880")
```

Editing this GUID **forces every material shader to recompile**. Source comment:

> "Update this GUID to force all material shaders to recompile. Merge conflicts on this line should be resolved by generating a new GUID"

Use this when you change anything in `MaterialTemplate.ush` / translator that doesn't trip DDC hashing automatically.

## Substrate enable / per-material disable

In `BasePassPixelShader.usf` near top:

```hlsl
#if !MATERIAL_IS_SUBSTRATE && SUBSTRATE_ENABLED
    #undef SUBSTRATE_ENABLED
    #define SUBSTRATE_ENABLED 0
#endif
```

So even with the engine flag on, **a non-Substrate material drops to the legacy path within BasePass.** Be careful when you read `#if SUBSTRATE_ENABLED` — it can have been silently downgraded by this block.

## DBuffer disabled in Substrate fast/single path

```hlsl
#if SUBSTRATE_ENABLED && SUBSTRATE_USE_DBUFFER_PASS && USE_DBUFFER && (SUBSTRATE_FASTPATH || SUBSTRATE_SINGLEPATH)
    #undef USE_DBUFFER
    #define USE_DBUFFER 0
#endif
```

Substrate's optimised paths skip DBuffer in BasePass — decals are applied earlier (`Substrate/SubstrateDBuffer.usf`). Adding decal logic into BasePass alone won't apply for those tiles.

## Translucent BasePass uses different SceneTextures UB

Around `BasePassPixelShader.usf:25–80`:

```hlsl
#if MATERIALBLENDING_TRANSLUCENT || MATERIALBLENDING_ADDITIVE || MATERIALBLENDING_MODULATE
    #define SceneTexturesStruct        TranslucentBasePass.SceneTextures
    #define EyeAdaptationStruct        TranslucentBasePass
    #define SceneColorCopyTexture      TranslucentBasePass.SceneColorCopyTexture
    #define SceneColorCopySampler      TranslucentBasePass.SceneColorCopySampler
    #define UseBasePassSkylight        TranslucentBasePass.Shared.UseBasePassSkylight
    #define SubstrateStruct            TranslucentBasePass.Substrate
    #define BlueNoise                  TranslucentBasePass.BlueNoise
    #define LightFunctionAtlasStruct   TranslucentBasePass.Shared.LightFunctionAtlas
#else
    #define EyeAdaptationStruct        OpaqueBasePass
    // ... reads from OpaqueBasePass.* instead
#endif
```

If you add a new sampled resource and only put it in `OpaqueBasePass`, translucent will silently sample garbage. Add to both UBs.

## Single-Layer Water has its own BlueNoise binding

```hlsl
#if MATERIAL_SHADINGMODEL_SINGLELAYERWATER
    #define BlueNoise SingleLayerWater.BlueNoise
#endif
```

This **overrides** the `BlueNoise` macro defined above. Order matters.

## Nanite WPO forces wave32 mode

```hlsl
#if PIXELSHADER && IS_NANITE_SHADING_PASS && IS_BASE_PASS
    COMPILER_FORCE_WAVE32_MODE
#endif
```

Nanite's `NaniteExportGBuffer.usf` evaluates WPO in pixel space → register pressure huge → wave64 occupancy collapses. The macro forces wave32. Side effect: any wave-intrinsic that assumes wave64 will break here.

## VSM page flags are hierarchical OR (mostly)

`VirtualShadowMapPageAccessCommon.ush` says:

> "These page flags are combined hierarchically using bitwise OR, so plan/negate them appropriately"

But the `VSM_EXTENDED_FLAG_*` (bits 4–10) are **physical-page-only**:

> "Stored in the physical meta data flags and must be higher than the VSM_*_FLAG. These are NOT valid to be used with hierarchical flag lookups!"

Mixing them in hierarchical queries silently corrupts page state.

## VSM Handle bisects single-page vs multi-page

```hlsl
static FVirtualShadowMapHandle MakeFromId(uint Id)
{
    Result.bIsSinglePageSM = (Id < VSM_MAX_SINGLE_PAGE_SHADOW_MAPS);
}
```

If you construct a handle from a raw `Id`, the flag is set automatically. **Directional lights** must use `MakeFromIdDirectional` (forces `bIsSinglePageSM = false`) or you lose mip levels.

## Material translator placeholder

`MaterialTemplate.ush` line ~370:

```hlsl
struct FPixelMaterialInputs
{
    %{pixel_material_inputs}     // ← placeholder, NOT a real macro
```

This is **literal text the translator string-replaces**. Any tool that pre-parses the file as HLSL will choke. Don't grep for `BaseColor` / `Metallic` here — the slots only exist after translation.

## SSD requires CONFIG_SIGNAL_PROCESSING

Including `SSDSignalFramework.ush` without defining `CONFIG_SIGNAL_PROCESSING` triggers `#error Missing CONFIG_SIGNAL_PROCESSING`. Each pass must declare which signal domain (REFLECTIONS / AO / SSGI / etc.) it processes.

## TSR is NOT a neural network

`TSRConvolutionNetwork.ush` requires `WAVE_COUNT_X/Y` and `LANE_COUNT_X/Y` and uses `LaneVectorization.ush` for **wave-cooperative LDS-tiled spatial convolution** — it's a hand-rolled tile/wave compute kernel pattern, not a learned ConvNet. Don't expect weights.

## Legacy Hair BxDF is deprecated

`ShadingModels.ush` HairBxDF carries:

```hlsl
// UE_DEPRECATED 5.7 - Deprecated by Substrate
FDirectLighting HairBxDF(FGBufferData GBuffer, ...);
```

For Substrate hair: `Substrate/Substrate.ush` `SUBSTRATE_BSDF_TYPE_HAIR` + `Private/HairStrands/HairBsdf.ush`.

## Path Tracing has a single RayGen entry

`Private/PathTracing/PathTracing.usf:86`:

```hlsl
RAY_TRACING_ENTRY_RAYGEN(PathTracingMainRG)
```

All bouncing/sampling happens inside this RG. Don't expect per-bounce dispatched RayGens — it's a uber-shader.

## RT recursion depth is 1

`Shared/RayTracingDefinitions.h`:

```hlsl
#define RAY_TRACING_MAX_ALLOWED_RECURSION_DEPTH 1   // Only allow ray tracing from RayGen shader
```

CHS / AHS / Miss cannot `TraceRay` again. Multi-bounce realtime effects must loop in RayGen.

## Niagara is NOT in this tree

`Engine/Shaders/` has zero `Niagara*.usf`. Niagara shaders live in `Engine/Plugins/FX/Niagara/Shaders/`. Don't grep here for them.

## StandaloneRenderer bypasses the translator

`StandaloneRenderer/D3D/*.hlsl` and `OpenGL/*.glsl` are raw — no `Common.ush`, no translator, no `MaterialFloat`. Editing them only affects Slate UI bootstrap, not the engine's main render.

## Common debug console variables

| Console | Effect |
|---------|--------|
| `r.Shaders.SymbolsExport=1` | dump compiled shader debug info to `Saved/ShaderDebugInfo/` |
| `r.ShaderDevelopmentMode=1` | retry on shader compile errors instead of crashing |
| `r.ShaderPipelineCache.PrintMissingPipelines=1` | log PSO misses |
| `r.RDG.Debug` | RDG validation |
| `r.RDG.Debug.GraphCapture` | dump RDG graph |
| `r.RDG.Visualize` | enable `vis <RT>` and `Tools/VisualizeTexture.usf` |
| `r.RDG.Debug.FlushPasses=1` | serialize all passes (find race conditions) |
| `r.Lumen.Visualize` | Lumen visualization layer |
| `r.Lumen.HardwareRayTracing.LightingMode` | SurfaceCache / HitLighting |
| `r.Substrate` | enable Substrate at runtime (in addition to compile-time) |
| `r.Substrate.BytesPerPixel` | per-pixel Substrate budget (smaller = simpler closures) |
| `r.Nanite` | toggle Nanite |
| `r.Nanite.Visualize` | visualize layer |
| `r.Nanite.ProgrammableRaster.WPODistanceLimit` | disable WPO past this distance |
| `r.Shadow.Virtual.Enable` | toggle VSM |
| `r.Shadow.Virtual.MaxPhysicalPages` | physical page pool size |
| `r.Shadow.Virtual.Cache` | VSM cache |
| `r.Shadow.Virtual.ShowStats` | print stats |
| `r.Shadow.Virtual.Visualize` | visualize layer (use with `VIRTUAL_SHADOW_MAP_VISUALIZE_*`) |
| `r.Shadow.Virtual.SMRT.RayCount*` | screen-space ray count |
| `r.AntiAliasingMethod` | 0=None 1=FXAA 2=TAA 3=MSAA 4=TSR |
| `r.TSR.Visualize` | TSR visualize layer |
| `r.TSR.RejectionAntiAliasingQuality` | 0 disables ConvNet-style reject |
| `r.MegaLights` | toggle MegaLights |
| `r.PathTracing` | activate path tracer |
| `r.PathTracing.MaxBounces` | bounces |
| `r.PathTracing.SamplesPerPixel` | SPP |
| `r.RayTracing.PSOPrecaching` | precompile RT PSOs |
| `r.GlobalDistanceField` | toggle GDF |
| `r.GlobalDistanceField.NumClipmaps` | LOD levels |
| `r.GenerateMeshDistanceFields` | mesh SDF gen at cook |
| `r.HairStrands.Strands` / `.Cards` / `.DeepShadow` | hair toggles |
| `r.VolumetricCloud` / `.SampleCountMin/Max` | cloud quality |
| `r.SkyAtmosphere.MultiScatteringLUT.HighQuality` | sky LUT quality |
| `r.HDR.Display.OutputDevice` | tonemap output device (sRGB / Rec709 / PQ / …) |
| `r.TonemapperFilm` | enable filmic tonemap (ACES path) |

## When in doubt — verify

The engine moves fast. Every claim in this skill bundle is dated to UE 5.7.4 @ `260bb2e1c561`. If a function name, line number, or struct field disagrees with what you see in the file:

1. Trust the file, not this skill.
2. If you have time, update the relevant `.md` and bump frontmatter `verified-against`.
