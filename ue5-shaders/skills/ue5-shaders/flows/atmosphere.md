---
name: flow-atmosphere
description: Sky Atmosphere LUTs, Volumetric Cloud, Fog (Height + Local + Heterogeneous Volumes), Reflection captures.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: full (SkyAtmosphere/VolumetricCloud entry lines verified; HeterogeneousVolumes 33-file list and entry kernels verified)
---

# Atmosphere & Volumetrics Flow

## Sky Atmosphere — Bruneton-style LUT pipeline

`Private/SkyAtmosphere.usf` builds 5 LUTs per frame, then ray-marches sky:

```
[Compute LUT chain]  (verified line numbers)
  RenderTransmittanceLutCS                 1144   2D: view height × zenith cos
  RenderMultiScatteredLuminanceLutCS       1200   multi-scattering term
  RenderSkyViewLutCS                       1326   low-freq sky view (fast lookup)
  RenderDistantSkyLightLutCS               1404   distant sky light cube
  RenderCameraAerialPerspectiveVolumeCS    1510   3D froxel aerial-persp.

[Render sky (background)]
  SkyAtmosphereVS                          851
  RenderSkyAtmosphereRayMarchingPS         905
  UpdateVisibleSkyAlpha                    889

[Debug]
  RenderSkyAtmosphereDebugPS               1705
  RenderSkyAtmosphereEditorHudPS           1854
```

LUT param helpers (`SkyAtmosphereCommon.ush`):

```hlsl
void UvToLutTransmittanceParams(out float ViewHeight, out float ViewZenithCosAngle, in float2 UV);   // 199
void LutTransmittanceParamsToUv(in  float ViewHeight, in float ViewZenithCosAngle, out float2 UV);   // 205
void UvToSkyViewLutParams(out float3 ViewDir, in float ViewHeight, in float2 UV);                     // 214
```

Cvars: `r.SkyAtmosphere.{TransmittanceLUT.Width,MultiScatteringLUT.HighQuality,AerialPerspectiveLUT.Width|Depth|DepthResolution,SampleCountMin|Max}`.

## Volumetric Cloud — material-driven raymarch

`Private/VolumetricCloud.usf` (verified entries):

```hlsl
// Material evaluation (cloud material domain = MATERIAL_DOMAIN_VOLUME)
void VolumetricCloudCalcPixelMaterialInputs(...);                  // 96
void ConvertCloudPixelMaterialInputsToWorkingColorSpace(...);       // 161

// Render (raster + compute variants)
void MainVS(...);                                                   // 211
void MainCommon(...);                                               // 456
void MainPS(...);                                                   // 1745
void MainCS(uint2 ...);                                             // 1779
void MainCS(uint3 ...);                                             // 1935
void MainPS(...);                                                   // 2068 (alternate)

// Self-shadow pipeline
void CloudShadowData_WriteDst(...);                                 // 2267
void MainShadowFilterCS(...);                                       // 2273
void MainDrawDebugShadowCS(...);                                    // 2371
void MainShadowTemporalProcessCS(...);                              // 2431
```

Headers: `VolumetricCloudCommon.ush`, `VolumetricCloudMaterialPixelCommon.ush`.

Cvars: `r.VolumetricCloud`, `r.VolumetricCloud.SampleCountMin/Max`, `r.VolumetricCloud.CloudShadow`, `r.VolumetricCloud.DistantSkyLightLUT`.

## Reflection environment & planar

```
ReflectionEnvironmentShaders.usf            cube capture raster
ReflectionEnvironmentPixelShader.usf        deferred composite
ReflectionEnvironmentComposite.ush          AO-weighted blend
ReflectionEnvironmentShared.ush

PlanarReflectionShaders.usf
PlanarReflectionShared.ush

AmbientCubemapComposite.usf                 ambient cubemap
```

Capture → preconvolved IBL (split-sum) → BasePass / Lumen IBL fallback.

## Fog — three tiers

### 1. Height Fog (analytic exponential)

```
HeightFogPixelShader.usf
HeightFogVertexShader.usf
HeightFogCommon.ush
```

Post-opaque fullscreen pass. In-scatter / transmittance closed-form integral.

### 2. Local Fog Volumes (box / sphere)

```
Private/LocalFogVolumes/
  LocalFogVolumeSplat.usf            compute splat into froxel grid
  LocalFogVolumeTiledCulling.usf     per-tile volume list
  LocalFogVolumeCommon.ush
```

### 3. Heterogeneous Volumes (full 3D volumetrics) — 33 files

`Private/HeterogeneousVolumes/`:

```
[Pipeline (.usf)]
  HeterogeneousVolumesPreshadingPipeline.usf            stage 1: pre-shading prep
  HeterogeneousVolumesMaterialBakingPipeline.usf        stage 2: bake material into voxel grid
                                                         (HeterogeneousVolumesBakeMaterialCS,
                                                          RasterizeBottomLevel{Ortho,Frustum}GridCS)
  HeterogeneousVolumesFrustumVoxelGrid.usf              stage 3a: frustum-aligned grid
                                                         (MarkTopLevelGridVoxelsForFrustumGridCS)
  HeterogeneousVolumesSparseVoxelPipeline.usf           stage 3b: sparse octree
  HeterogeneousVolumesVoxelGridPipeline.usf             stage 3c: world-aligned grid
  HeterogeneousVolumesVoxelGridRendering.usf            voxel grid render
  HeterogeneousVolumesVoxelGridShadows.usf              voxel grid self-shadow
  HeterogeneousVolumesLiveShadingPipeline.usf           live shading (no bake)
                                                         (RenderLightingCacheWithLiveShadingCS,
                                                          RenderSingleScatteringWithLiveShading{,Indirect}CS)
  HeterogeneousVolumesLiveShadingGlobalPipeline.usf     global live shading
                                                         (ScreenTileClassificationCS,
                                                          ConvertTexture3DFixedPointToFloatCS,
                                                          DilateExistenceMaskCS)
  HeterogeneousVolumesLiveShadingShadows.usf            live shading shadows
                                                         (RenderVolumetricShadowMapForLightWithLiveShadingCS)
  HeterogeneousVolumesAmbientOcclusionPipeline.usf      AO
                                                         (RenderAmbientOcclusionWithLiveShadingCS,
                                                          RenderExistenceMaskWithLiveShadingCS)
  HeterogeneousVolumesShadowMask.usf                    shadow mask
  HeterogeneousVolumesHardwareRayTracing.usf            HW RT variant
  HeterogeneousVolumesComposite.usf                     final composite
                                                         (HeterogeneousVolumesUpsampleCS,
                                                          HeterogeneousVolumesFilterCS,
                                                          HeterogeneousVolumesCompositeCS)
  HeterogeneousVolumesVisualizeCascades.usf             debug

[Headers (.ush)]
  HeterogeneousVolumesAdaptiveVolumetricShadowMapSampler.ush     AVSM read
  HeterogeneousVolumesAdaptiveVolumetricShadowMapSampling.ush    ★ included by BasePassPixelShader.usf when ADAPTIVE_VOLUMETRIC_SHADOW_MAP=1
  HeterogeneousVolumesAdaptiveVolumetricShadowMapUtils.ush
  HeterogeneousVolumesBeerShadowMapUtils.ush
  HeterogeneousVolumesFrustumVoxelGridUtils.ush
  HeterogeneousVolumesLightingUtils.ush
  HeterogeneousVolumesLiveShadingUtils.ush
  HeterogeneousVolumesRayMarchingTypes.ush
  HeterogeneousVolumesRayMarchingUtils.ush
  HeterogeneousVolumesSparseVoxelUniformBufferUtils.ush
  HeterogeneousVolumesSparseVoxelUtils.ush
  HeterogeneousVolumesStochasticFiltering.ush
  HeterogeneousVolumesTracingUtils.ush
  HeterogeneousVolumesTransmittanceVolumeUtils.ush
  HeterogeneousVolumesVoxelGridRenderingUtils.ush
  HeterogeneousVolumesVoxelGridTraversal.ush
  HeterogeneousVolumesVoxelGridTypes.ush
  HeterogeneousVolumesVoxelGridUtils.ush
```

### Lifecycle

```
Preshading
  → MaterialBaking (bake density/extinction/emission into voxel grid)
  → choose grid type:
        Frustum (camera-aligned, dense near, sparse far)
        VoxelGrid (world-aligned)
        SparseVoxel (octree)
  → Live Shading (skip baking, direct material eval)
  → Render single-scattering
  → Voxel grid shadows / AVSM (Adaptive Volumetric Shadow Map)
  → Composite (upsample + filter + blend with SceneColor)
```

### BasePass integration

`BasePassPixelShader.usf` includes when `ADAPTIVE_VOLUMETRIC_SHADOW_MAP=1`:

```hlsl
#define AVSM TranslucentBasePass.AVSM
#include "HeterogeneousVolumes/HeterogeneousVolumesAdaptiveVolumetricShadowMapSampling.ush"
```

→ translucent meshes can sample volume self-shadow.

## Sparse Volume Texture (OpenVDB-style)

```
Private/SparseVolumeTexture/
  UpdateSparseVolumeTexture.usf
  SparseVolumeTextureCommon.ush      # included by MaterialTemplate.ush
```

VFX / simulation data exposed as 3D textures sampleable in materials.

## Single Layer Water

```
SingleLayerWaterComposite.usf
SingleLayerWaterRefractionCulling.usf
```

`Shared/SingleLayerWaterDefinitions.h`. BasePass branches on `MATERIAL_SHADINGMODEL_SINGLELAYERWATER`; composite resolves refraction + caustics + transmission.

## Composition order (per frame, post BasePass)

```
1. SkyAtmosphere LUTs (compute) → SceneColor (background fill)
2. VolumetricCloud (raymarch, optionally compute) → blend over sky
3. ReflectionEnvironment composite (deferred IBL)
4. HeterogeneousVolumes (Preshading → bake/live → render → composite)
5. HeightFog + LocalFogVolumes (fullscreen analytic / froxel)
6. Translucent BasePass (AVSM, VolumetricCloud transmittance applied)
7. PostProcess
```

## Common console variables

```
r.SkyAtmosphere
r.SkyAtmosphere.MultiScatteringLUT.HighQuality
r.SkyAtmosphere.SampleCountMin / Max
r.VolumetricCloud
r.VolumetricCloud.CloudShadow
r.VolumetricFog                                # height fog volumetric fallback
r.HeterogeneousVolumes
r.HeterogeneousVolumes.LiveShading
r.HeterogeneousVolumes.Shadows
r.HeterogeneousVolumes.HardwareRayTracing
r.LocalFogVolume.ApplyOnTransparent
```
