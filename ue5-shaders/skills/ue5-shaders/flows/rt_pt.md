---
name: flow-rt-pt
description: Realtime Ray Tracing vs offline Path Tracing — masks, payload types, RayGen entry, material binding.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: full (mask/payload defines verified; PathTracing RayGen and MaterialSampling functions verified by line)
---

# Ray Tracing & Path Tracing Flow

## RT vs PT — what they are

| Aspect | **RayTracing** (`Private/RayTracing/`) | **PathTracing** (`Private/PathTracing/`) |
|--------|----------------------------------------|------------------------------------------|
| Use case | realtime effects: AO, shadow, reflection, GI | offline / cinematic ground truth |
| Bounces | 1 (`RAY_TRACING_MAX_ALLOWED_RECURSION_DEPTH = 1`) | many (loop in RG) |
| Material payload | small per-effect (`FLumenMinimalPayload`, `FDeferredMaterialPayload`, …) | full `FPackedPathTracingPayload` |
| Inst mask | `RAY_TRACING_MASK_*` (8 bits) | `PATHTRACER_MASK_*` (8 bits, separate) |
| Sampler | URand / blue noise | Sobol + adaptive error diffusion |
| Denoise | SSD framework | accumulation + adaptive samples |

## Mask bits

### `Shared/RayTracingDefinitions.h` — RT_MASK

```hlsl
0x01  RAY_TRACING_MASK_OPAQUE              // primary, reflection, shadow
0x02  RAY_TRACING_MASK_TRANSLUCENT
0x04  RAY_TRACING_MASK_OPAQUE_SHADOW
0x08  RAY_TRACING_MASK_TRANSLUCENT_SHADOW
0x10  RAY_TRACING_MASK_THIN_SHADOW         // hair etc.
0x40  RAY_TRACING_MASK_HAIR_STRANDS        // primary against hair
0x80  RAY_TRACING_MASK_OPAQUE_FP_WORLD_SPACE  // 1st-person mesh world-space exclusion
0xFF  RAY_TRACING_MASK_ALL
```

### `Shared/PathTracingDefinitions.h` — PT_MASK (separate)

```hlsl
0x01  PATHTRACER_MASK_CAMERA               // primary
0x02  PATHTRACER_MASK_HAIR_CAMERA
0x04  PATHTRACER_MASK_SHADOW
0x08  PATHTRACER_MASK_HAIR_SHADOW
0x10  PATHTRACER_MASK_INDIRECT             // bounce
0x20  PATHTRACER_MASK_HAIR_INDIRECT
0x40  PATHTRACER_MASK_CAMERA_TRANSLUCENT
0x80  PATHTRACER_MASK_INDIRECT_TRANSLUCENT
```

## Payload types (`Shared/RayTracingPayloadType.h`)

Each system declares its own to avoid forcing big payloads on minimal users:

```hlsl
RT_PAYLOAD_TYPE_MINIMAL              // FMinimalPayload — just HitT
RT_PAYLOAD_TYPE_DEFAULT              // FDefaultPayload — + InstanceIndex/PrimitiveIndex/Bary
RT_PAYLOAD_TYPE_RAYTRACING_MATERIAL  // FPackedMaterialClosestHitPayload — full GBuffer-like
RT_PAYLOAD_TYPE_DEFERRED             // FDeferredMaterialPayload — write-then-shade
RT_PAYLOAD_TYPE_PATHTRACING_MATERIAL // FPackedPathTracingPayload — Substrate-aware
RT_PAYLOAD_TYPE_LUMEN_MINIMAL        // FLumenMinimalPayload — small (Lumen wants tiny)
RT_PAYLOAD_TYPE_VFX                  // FVFXTracePayload
RT_PAYLOAD_TYPE_DECALS               // FDecalShaderPayload
RT_PAYLOAD_TYPE_SPARSE_VOXEL         // FSparseVoxelPayload
```

## Slots (`Shared/RayTracingDefinitions.h`)

```hlsl
RAY_TRACING_SHADER_SLOT_MATERIAL     0    // CHS: material eval
RAY_TRACING_SHADER_SLOT_SHADOW       1    // CHS: shadow only (faster)
RAY_TRACING_NUM_SHADER_SLOTS         2

RAY_TRACING_MISS_SHADER_SLOT_DEFAULT 0    // sets HitT to "miss"
RAY_TRACING_MISS_SHADER_SLOT_LIGHTING 1   // returns light radiance (used by reflection/translucency)
```

## RT realtime pipeline

```
[BLAS / TLAS]
  RayTracingInstanceBufferUtil.usf      — instance buffer build
  RayTracingDynamicMesh.usf             — skinned/deformable BLAS update
  RayTracingDispatchDesc.usf            — indirect dispatch

[Grids]
  RayTracingBuildLightGrid.usf          — light spatial bin
  RayTracingBuildDecalGrid.usf

[Effects (RayGen entries)]
  RayTracingPrimaryRays.usf
  RayTracingOcclusionRGS.usf            — shadows
  RayTracingAmbientOcclusionRGS.usf
  RayTracingSkyLightRGS.usf
  Lumen reflection/GI HW RT (in Lumen/)

[Material binding]
  RayTracingMaterialDefaultHitShaders.usf   — default CHS/AHS
  RayTracingMaterialHitShaders.usf          — material-instanced CHS
  RayTracingHitGroupCommon.ush              — payload pack/unpack
  RayTracingCalcInterpolants.ush            — recompute VS interpolants in CHS

[Inline RT (RayQuery)]
  TraceRayInline.ush
  TraceRayInline{D3D12,Metal,Vulkan}.ush
```

CHS includes `MaterialTemplate.ush` — translator generates an `EvaluateMaterial` body just like in BasePass.

## Deferred material path (perf)

```
RayGen
  ↓ TraceRay → CHS with FDeferredMaterialPayload
              CHS only writes GBuffer-like data, NO lighting
  ↓ collect hits → tile-classify by material
RayTracingDeferredMaterials.usf         — separate pass, evaluates lighting per material
```

This avoids huge per-CHS register pressure — same idea as Substrate's tile classification for deferred.

## Lighting evaluation in miss shader

```hlsl
RAY_TRACING_MISS_SHADER_SLOT_LIGHTING   1
RayTracingLightingMS.usf
```

Reflections / translucency that miss the BVH evaluate sky / IBL via this miss shader instead of a separate compute pass — saves a roundtrip.

## PT pipeline

`Private/PathTracing/PathTracing.usf:86`:

```hlsl
RAY_TRACING_ENTRY_RAYGEN(PathTracingMainRG)
{
    // 1. Camera ray + lens DOF
    // 2. Loop bounces:
    //    a. TraceRay → CHS → FPackedPathTracingPayload
    //    b. NEE: SampleMaterial(...)  [Material/PathTracingMaterialSampling.ush:571]
    //    c. light pick via PathTracingLightSampling.ush + LightGrid
    //    d. shadow ray → MIS combine
    //    e. EvalMaterial(...)         [PathTracingMaterialSampling.ush:627]
    //    f. update throughput
    // 3. Russian roulette / adaptive cutoff
    // 4. Atmosphere transmittance via PathTracingBuildAtmosphereLUT
    // 5. Adaptive sampling: AdaptiveStart + BuildAdaptiveError
}

void StorePathStateData(FPathState, uint Index);   // line 69 — prep for next sample
```

### PT Material modules (`Material/`, 19 files)

Per-closure import sample + eval:

```
PathTracingMaterialCommon.ush          — closure dispatch
PathTracingMaterialSampling.ush        — SampleMaterial / EvalMaterial
PathTracingDefaultLit.ush              — standard PBR
PathTracingClearCoat.ush
PathTracingCloth.ush
PathTracingEye.ush
PathTracingHair.ush                    — Marschner BCSDF
PathTracingTwoSidedFoliage.ush
PathTracingSubsurfaceProfile.ush
PathTracingThinGlass.ush
PathTracingSolidGlass.ush

# Substrate bridge (closure tree → PT IS)
PathTracingSubstrate.ush
PathTracingSubstrateCommon.ush
PathTracingSubstrateFoliage.ush
PathTracingSubstrateSolidGlass.ush
PathTracingSubstrateThinGlass.ush

# Components
PathTracingLambert.ush                 — Diffuse
PathTracingGlossy.ush                  — GGX
PathTracingFresnel.ush
PathTracingMedium.ush                  — volume / participating media
PathTracingEnergyConservation.ush
PathTracingRadianceProbe.ush           — indirect cache
FirstBounceRayGuidingCommon.ush        — adaptive ray guiding
```

### PT Light modules (`Light/`, 8 files)

```
PathTracingLightCommon.ush
PathTracingLightSampling.ush     — MIS picker
PathTracingLightGrid.ush         — spatial bin
PathTracingDirectionalLight.ush
PathTracingPointLight.ush
PathTracingSpot? (none separate; Spot uses Point with cone)
PathTracingCapsuleLight.ush
PathTracingRectLight.ush
PathTracingSkyLight.ush
```

## RT Inline (DXR 1.1 RayQuery)

For small/cheap rays inside a regular CS/PS:

```hlsl
#include "/Engine/Private/RayTracing/TraceRayInline.ush"

FTraceRayInlineResult Result = TraceRayInline(
    AccelerationStructure, RayDesc, Mask, ...);
```

Backends in `TraceRayInline{D3D12,Metal,Vulkan}.ush`. Used by Lumen HW RT, contact shadows, etc. — no separate RTPSO required.

## Common console variables

```
r.RayTracing                                # toggle
r.RayTracing.PSOPrecaching                  # precompile RT PSOs
r.RayTracing.Shadow / .AO / .GlobalIllumination / .Reflections   # per-effect
r.RayTracing.Translucency
r.RayTracing.UseInline                      # inline RT vs RTPSO

r.PathTracing                               # PT toggle
r.PathTracing.MaxBounces
r.PathTracing.SamplesPerPixel
r.PathTracing.AdaptiveSampling
r.PathTracing.SamplerType                   # 0=default 1=error diffusion
r.PathTracing.MISMode
r.PathTracing.UseAtmosphere
```

## Common issues

- **CHS too expensive** → switch to deferred materials path (`RayTracingDeferredMaterials.usf`).
- **Lumen HW RT shader hang** → payload size; keep `FLumenMinimalPayload` minimal.
- **PT noise won't converge** → check `MaxBounces`, `r.PathTracing.SamplerType=1` for stratified.
- **Mask off-by-one** → RT_MASK and PT_MASK are **separate** systems even when they look similar.
- **Hair invisible to RT** → set `RAY_TRACING_MASK_HAIR_STRANDS` and ensure BLAS exists for hair geometry.
- **First-person weapon shows in reflections** → use `RAY_TRACING_MASK_OPAQUE_FP_WORLD_SPACE` to exclude.
