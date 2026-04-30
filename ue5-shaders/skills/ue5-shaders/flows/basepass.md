---
name: flow-basepass
description: End-to-end flow from draw call through Material → VertexFactory → BasePass → GBuffer/Substrate output.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: full (line numbers verified for BasePassPixelShader.usf, MaterialTemplate.ush, LocalVertexFactory.ush)
---

# BasePass Flow — DrawCall to GBuffer

## High-level

```
DrawCall (CPU records via FMeshDrawCommand)
  ↓ binds (Material × VertexFactory × BasePass) PSO + GPU Scene UB
[VS] BasePassVertexShader.usf
  ↓ VertexFactoryGet*
  ↓ MaterialTemplate's GetMaterialWorldPositionOffset (translator-injected)
  ↓ outputs FBasePassInterpolantsVSToPS + WPO-applied SV_Position
[PS] BasePassPixelShader.usf
  ↓ GetMaterialPixelParameters (VF fills)
  ↓ CalcPixelMaterialInputs (translator runs material graph)
  ↓ branch: SUBSTRATE_ENABLED && MATERIAL_IS_SUBSTRATE
    ├─ Substrate path → packed closure tree → 3 MRTs
    └─ Legacy path → ShadingModels → GBuffer A/B/C/D/E
```

## VS step-by-step

`BasePassVertexShader.usf`:

```hlsl
void Main(FVertexFactoryInput Input,
          out FBasePassVSToPS Output)
{
    // 1. Get GPU Scene primitive/instance data
    FVertexFactoryIntermediates VFIntermediates = GetVertexFactoryIntermediates(Input);

    // 2. Tangent space + world position (no WPO yet)
    float3x3 TangentToLocal = VertexFactoryGetTangentToLocal(Input, VFIntermediates);
    float4 WorldPos = VertexFactoryGetWorldPosition(Input, VFIntermediates);

    // 3. Build vertex material params
    FMaterialVertexParameters VertexParameters =
        GetMaterialVertexParameters(Input, VFIntermediates, WorldPos.xyz, TangentToLocal);

    // 4. Translator: world position offset
    float3 WPO = GetMaterialWorldPositionOffset(VertexParameters);
    WorldPos.xyz += WPO;

    // 5. Generate interpolants (handed to PS)
    Output.FactoryInterpolants =
        VertexFactoryGetInterpolantsVSToPS(Input, VFIntermediates, VertexParameters);

    // 6. Clip-space output
    Output.Position = mul(WorldPos, View.WorldToClip);
}
```

For motion-blur/TSR, `Velocity` pass uses `VertexFactoryGetPreviousWorldPosition` for the prev frame.

## PS step-by-step

`BasePassPixelShader.usf` main entry around line 909:

```hlsl
void MainPS(FBasePassVSToPS In, out OutMRTs)
{
    // 1. VF fills geometric/material params
    FMaterialPixelParameters MaterialParameters =
        GetMaterialPixelParameters(In.FactoryInterpolants, In.SvPosition);             // 909

    // 2. Translator runs the material graph
    FPixelMaterialInputs PixelMaterialInputs;                                          // 910
    CalcPixelMaterialInputs(MaterialParameters, PixelMaterialInputs);

    // 3. Coverage/alpha clip
    GetMaterialCoverageAndClipping(MaterialParameters, PixelMaterialInputs);           // 977

    // 4. Read material slots
    half3 BaseColor    = GetMaterialBaseColor(PixelMaterialInputs);                    // 994
    half  Metallic     = GetMaterialMetallic(PixelMaterialInputs);                     // 995
    half  Specular     = GetMaterialSpecular(PixelMaterialInputs);                     // 996
    float Roughness    = GetMaterialRoughness(PixelMaterialInputs);                    // 998
    float Anisotropy   = GetMaterialAnisotropy(PixelMaterialInputs);                   // 999
    uint  ShadingModel = GetMaterialShadingModel(PixelMaterialInputs);                 // 1000
    half  Opacity      = GetMaterialOpacity(PixelMaterialInputs);                      // 1001
    // ... + Emissive, Normal, Refraction, ClearCoat, AO, etc.

    // 5. Pixel depth offset (parallax)
    ApplyPixelDepthOffsetForBasePass(MaterialParameters, PixelMaterialInputs, ...);    // 767

    // 6. Branch: Substrate vs legacy
#if SUBSTRATE_ENABLED && MATERIAL_IS_SUBSTRATE
    // Build FSubstrateData closure tree from PixelMaterialInputs.GetFrontSubstrateData()
    // Pack into 3 MRT outputs (SUBSTRATE_BASE_PASS_MRT_OUTPUT_COUNT = 3)
    SubstrateBasePassEncode(...);
#else
    // Build FGBufferData from BaseColor/Metallic/Specular/Roughness/Normal/ShadingModel
    // Encode to GBuffer A/B/C/D (+E for custom data, F for anisotropy)
    EncodeGBuffer(GBuffer, OutMRTs);
#endif

    // 7. Forward-shaded contribution (translucent only)
#if MATERIALBLENDING_TRANSLUCENT || MATERIALBLENDING_ADDITIVE || MATERIALBLENDING_MODULATE
    // - Forward+ light loop via LightGrid
    // - Skylight, IBL
    // - DBuffer decals (already prepass-encoded)
    // Output to SceneColor (or SeparateTranslucency if requested)
#endif
}
```

## Translucent vs Opaque UB rebinding

(See [quirks.md](quirks.md#translucent-basepass-uses-different-scenetextures-ub) — the file rebinds UB names at top so the rest of the shader is path-agnostic.)

## Substrate output (3 MRTs)

`SUBSTRATE_BASE_PASS_MRT_OUTPUT_COUNT = 3`:

| MRT | Content |
|-----|---------|
| 0 | Pixel header (closure count, mode flags, top-layer normal, AO + irradiance) |
| 1 | Packed closure tree (operator + BSDF nodes — up to 8 closures) |
| 2 | SSS / additional per-closure data (`SUBSTRATE_SSS_DATA_UINT_COUNT = 2`) |

`SubstrateMaterialClassification.usf` later reads MRT 0 to bin tiles into FAST / SINGLE / COMPLEX paths for deferred lighting.

## Legacy GBuffer (when Substrate off / not used)

| RT | Format | Purpose |
|----|--------|---------|
| A | RGBA8 | Normal (octahedral) + Roughness |
| B | RGBA8 | Metallic + Specular + Roughness + ShadingModelID |
| C | RGBA8 | BaseColor + AO |
| D | RGBA8 | Custom data (per shading model) |
| E | RG8   | Anisotropy + Tangent (only if `MATERIAL_USES_ANISOTROPY`) |
| F | (Velocity RG16) | Per-pixel motion vectors |

`ShadingModelID` is packed into `SelectiveOutputMask` high nibble — see [defines.md](defines.md#selectiveoutputmask-high-4-bits).

## What plugs in where

| Hook | Where | What |
|------|-------|------|
| Per-VF data | `*VertexFactory.ush` | Geometry-specific input/interpolants |
| Material graph | `MaterialTemplate.ush` | translator injects via `%{pixel_material_inputs}` and `Calc*` functions |
| Decal sampling | `DBufferDecalShared.ush` | Read in BasePass before final encode |
| Skylight | `SkyLighting{Diffuse,}Shared.ush` | Indirect contribution |
| LWC | `WorldSpaceMath.ush` + `FMaterialLWCData` | World coords > FP32 range |
| Volumetric shadow | `HeterogeneousVolumesAdaptiveVolumetricShadowMapSampling.ush` | Translucent-only |

## When BasePass is wrong / weird

- Wrong tangent → check `VertexFactoryGetTangentToLocal` in your VF.
- Wrong WPO at distance → Nanite WPO distance limit (`r.Nanite.ProgrammableRaster.WPODistanceLimit`).
- Decals not appearing on Substrate fast-path materials → see [quirks.md](quirks.md#dbuffer-disabled-in-substrate-fastsingle-path).
- Black on translucent only → resource not bound to `TranslucentBasePass` UB.
- All materials recompiling → someone bumped `UESHADERMETADATA_VERSION` (intentional or merge conflict).
