---
name: flow-translucency
description: Translucency / OIT / Decals / MegaLights / SSRT / HairStrands — the lighting-effect family.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: partial (file lists verified; per-effect internals partially read)
---

# Lighting Effects Flow

## Translucency — forward+ inside BasePass

```
TranslucentLightingShaders.usf          per-light loop (LightGrid)
TranslucentLightInjectionShaders.usf    boundless 3D volume light injection
TranslucentShadowDepthShaders.usf       deep shadow opacity volume
ComposeSeparateTranslucency.usf         separate-translucency final blend
ThinTranslucentCommon.ush               thin-translucent thickness model
```

Translucent BasePass:
- Reads `TranslucentBasePass.SceneTextures` UB (not opaque's).
- Forward+ light loop via `LightGridCommon.ush` + `ForwardLightingCommon.ush`.
- Lumen translucency volume injects indirect.
- AVSM (Heterogeneous Volumes) gives volume self-shadow when enabled.

### Separate Translucency

Renders to a separate RT first, then composes via `ComposeSeparateTranslucency.usf` — keeps DOF/MotionBlur applied only to opaque if desired.

## OIT (Order-Independent Transparency)

```
Private/OIT/OITSorting.usf
```

Per-pixel depth sort compute pass. Single file — no MBOIT / linked-list infra in the core engine tree.

## Decals (DBuffer)

```
DBufferDecalShared.ush             prepass encode/decode (Color/Normal/Roughness)
DBufferNormalReprojection.ush
DecalCommon.ush
Substrate/SubstrateDBuffer.usf     Substrate-specific binding
```

### Flow

```
1. Decal prepass (material domain = DeferredDecal)
   → writes DBuffer MRTs (Color, Normal, Roughness)
2. BasePass opaque
   → samples DBuffer → blend into GBuffer encode

[Substrate fast/single path] decals applied EARLIER (separate pass) — see quirks.md
```

## MegaLights — GPU-driven light system (23 files)

Goal: handle thousands of dynamic shadowed lights with stochastic shadowing + denoise.

### Core

```
MegaLights.usf / .ush
MegaLightsShading.usf / .ush             per-tile deferred apply
MegaLightsSampling.usf / .ush            importance sampling per pixel
MegaLightsMaterial.ush
```

### Light hash + tile classify

```
MegaLightsVisibleLightHash.usf           build spatial light hash
MegaLightsFilterVisibleLightHash.usf     coarse filter
MegaLightsTileClassification.ush         tile by light count / type
```

### Shadow tracing

```
MegaLightsRayTracing.usf / .ush          SW path
MegaLightsHardwareRayTracing.usf         HW path
MegaLightsVSMMarking.usf                 request VSM pages
MegaLightsVSMTracing.usf                 sample VSM
```

### Denoise

```
MegaLightsDenoiserSpatial.usf
MegaLightsDenoiserTemporal.usf
```

### Volumetric variant

```
MegaLightsVolume.ush
MegaLightsVolumeShading.usf
MegaLightsVolumeSampling.usf
MegaLightsVolumeRayTracing.usf
MegaLightsVolumeHardwareRayTracing.usf
```

### Pipeline

```
1. Build VisibleLightHash         (frustum + occlusion)
2. TileClassification             (group tiles by light counts / types)
3. Sampling                       (per-pixel light importance sample)
4. Tracing                        (HW or SW RT, or stochastic shadow)
5. VSMMarking                     (request shadow pages)
6. Shading                        (BSDF eval per sampled light)
7. Spatial → Temporal denoise
```

Cvars: `r.MegaLights`, `r.MegaLights.MaxShadowedDirectLights`, `r.MegaLights.HardwareRayTracing`, `r.MegaLights.Volume`.

## Light Function Atlas

```
Private/LightFunctionAtlas/
  LightFunctionAtlasCommon.usf         atlas layout
  LightFunctionAtlasRender.usf         render LF materials → atlas
```

Light Function materials → pre-rendered into a single 2D atlas. Deferred lighting / MegaLights sample this atlas for cookie/projection effects.

## SSRT (Screen-Space Ray Tracing)

`Private/SSRT/` — fallback for areas Lumen / RT don't reach:

```
SSRTReflections.usf                      main reflection
SSRTDiffuseIndirect.usf                  diffuse GI fallback
SSRTRayCast.ush                          HZB + GBuffer raymarch
SSRTTileClassification.usf
SSRTTileClassificationBuffer.ush
SSRTPrevFrameReduction.usf               prev-frame mip chain
```

Pipeline:

```
PrevFrameReduction → mip chain
TileClassification → roughness/type tiles
RayCast → HZB-accelerated screen-space march
(optional) SSD denoise
```

Off-screen → fall back to cubemap / Lumen / sky.

## HairStrands — 50+ files

`Private/HairStrands/`:

### VF + mesh path

```
HairStrandsVertexFactory.ush             strand mesh
HairCardsVertexFactory.ush               card LOD
HairStrandsMesh.usf
HairStrandsMaterial{VS,PS}.usf
HairCardsGeneration.usf
HairCardsDeformation.usf
HairCards{Attribute,Texture}Common.ush
HairStrandsMaterialCommon.ush
```

### Cluster + AABB

```
HairStrandsClusterCulling.usf
HairStrandsClusterCommon.ush
HairStrandsAABB.usf
HairStrandsAABBCommon.ush
```

### Simulation / skin

```
HairStrandsGuideDeform.usf               sim guide strands
HairStrandsInterpolation.usf             guide → real strand
HairStrandsSkinUpdate.usf
HairStrandsBindingCommon.ush
HairStrandsTangent.usf
```

### Deep Shadow (hair self-shadow)

```
HairStrandsDeepShadowAllocation.usf
HairStrandsDeepShadowVS.usf
HairStrandsDeepShadowPS.usf              opacity encoding
HairStrandsDeepShadowMask.usf            per-light mask
HairStrandsDeepShadowCommon.ush
HairStrandsDeepShadowCommonStruct.ush
```

### Transmittance — Marschner BCSDF + dual scattering

```
HairStrandsDeepTransmittanceCommon.ush
HairStrandsDeepTransmittanceDualScattering.ush
HairStrandsDeepTransmittanceMask.usf
HairBsdf.ush
HairBsdfSample.ush
```

### Forward / coverage

```
HairStrandsForwardCulling.usf
HairStrandsForwardRaster.usf
HairStrandsCoverage.usf
```

### Environment lighting

```
HairStrandsEnvironmentLighting.usf
HairStrandsEnvironmentAO.usf
HairStrandsEnvironmentLightingCommon.ush
HairStrandsLUT.usf                       preintegrated LUTs
```

### RT

```
HairStrandsRaytracing.ush
HairStrandsRaytracingGeometry.usf
HairStrandsScreenTracing.ush
```

### Misc

```
HairStrandsLightSample.usf
HairStrandsFollicleMask.usf              haircut mask
HairStrandsHitProxy.usf
HairStrandsTexturesGeneration.usf
HairStrandsComposition.usf               final composite to SceneColor (alpha)
HairStrandsGBufferCommon.ush
HairStrandsPack.ush
HairStrandsAttributeTemplate.ush
HairStrandsAttributeCommon.ush
HairStrandsCommon.ush
HairStrandsDebug.usf / *CommonStruct.ush
```

### Per-frame flow

```
1. SkinUpdate / GuideDeform
2. Interpolation (guide → strand)
3. ClusterCulling + AABB
4. Forward raster (or strand mesh raster)
5. Coverage accumulation
6. DeepShadowAllocation → DeepShadow VS+PS (per shadow-casting light)
7. DeepTransmittanceMask (per light)
8. EnvironmentLighting + LightSample (direct + indirect)
9. Composition → SceneColor alpha-blend
```

Cvars: `r.HairStrands`, `r.HairStrands.Strands`, `r.HairStrands.Cards`, `r.HairStrands.DeepShadow`, `r.HairStrands.Voxelization.Raymarching`.

## Composition order (lighting effects part of frame)

```
[Opaque BasePass + Decals via DBuffer]
   ↓
[VSM / classic Shadow projection]
   ↓
[Lumen GI/Reflections + SSRT fallback]
   ↓
[MegaLights deferred apply + LightFunctionAtlas sampling]
   ↓
[HairStrands deep shadow + transmittance + composition]
   ↓
[Sky + Cloud + Fog + HeterogeneousVolumes]
   ↓
[Translucent BasePass + Forward Lights + AVSM + Lumen translucency volume]
   ↓
[ComposeSeparateTranslucency]
   ↓
[Post-process]
```
