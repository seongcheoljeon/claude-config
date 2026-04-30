---
name: flow-lumen
description: Lumen GI/Reflection per-pixel computation flow — surface cache, radiance cache, screen probes, reflections.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: partial (LumenReflections.usf entry points verified; some upstream flows inferred from filenames)
---

# Lumen Flow — How One Pixel Gets GI

## Two caches + two evaluation paths

| Cache | Domain | Purpose |
|-------|--------|---------|
| **Surface Cache** | mesh-card UV atlas | direct lighting + albedo per-card |
| **Radiance Cache** | world-space sparse probes | multi-bounce indirect |

| Path | Use |
|------|-----|
| **Software RT** | Mesh SDF + Global Distance Field traversal → Surface Cache sample |
| **Hardware RT** | DXR/RTPSO → minimal CHS payload → Surface Cache sample (or hit lighting) |

## Per-frame pipeline

```
1. Surface Cache update
   LumenCardComputeShader.usf       // changed cards re-rendered
   LumenCardPixelShader.usf         // material → albedo/normal/emissive baked
   LumenCardVertexShader.usf

2. Direct lighting on cards
   LumenSceneDirectLighting*.usf    // each visible light → card lit pages

3. Radiosity (card-to-card inter-reflection)
   LumenRadiosity*.usf

4. Radiance Cache update (world probes)
   LumenRadianceCache.usf           // SW path
   LumenRadianceCacheHardwareRayTracing.usf   // HW path

5. Screen Probe Gather (diffuse indirect)
   LumenScreenProbeGather*.usf
   LumenScreenProbeFiltering.usf
   LumenScreenProbeIntegrate.usf
   LumenScreenProbeTracing.usf

6. Reflections (specular indirect) — see breakdown below

7. ReSTIR (variance reduction)
   LumenReSTIRGather.usf

8. Translucency volumes (3D froxel GI for transparent meshes)
   LumenTranslucencyVolume*.usf

9. Composite into deferred lighting
```

## Reflections breakdown (`LumenReflections.usf`)

Verified compute kernels:

```hlsl
[L29]  void InitReflectionIndirectArgsCS(...);
       // Builds indirect dispatch args from tile classification

[L72]  void ReflectionTileClassificationBuildListsCS(...);
       // Tags 8x8 tiles by roughness / closure / glossy vs rough

[L302] void ReflectionGenerateRaysCS(...);
       // Importance samples GGX → fills RWRayBuffer + RWRayTraceDistance

[L446] void ReflectionClearUnusedTraceTileDataCS(...);
[L484] void ReflectionClearNeighborTileCS(...);
       // Cleanup empty tiles
```

Then dispatcher branches on `r.Lumen.HardwareRayTracing`:

```
SW path:
  LumenReflectionTracing.usf
    → traverses Mesh SDF / Global SDF
    → samples Surface Cache at hit
HW path:
  LumenReflectionHardwareRayTracing.usf
    → DXR TraceRay with FLumenMinimalPayload
    → CHS = LumenHardwareRayTracingMaterials.usf
    → samples Surface Cache (or full material if hit-lighting mode)
```

Output: `RWSpecularAndSecondMoment` + `RWSpecularIndirect` → SSD denoise.

## SSD denoise (Lumen reflections)

`Private/ScreenSpaceDenoise/SSDSignalFramework.ush` instantiated with:

```hlsl
#define CONFIG_SIGNAL_PROCESSING SIGNAL_PROCESSING_REFLECTIONS
```

Pipeline: `SSDInjest.usf` → `SSDSpatialAccumulation.usf` → `SSDTemporalAccumulation.usf`.

## HW vs SW RT — differences

| Aspect | SW RT | HW RT |
|--------|-------|-------|
| BLAS | None — uses Mesh SDF | DXR BLAS per mesh |
| Cost | High in many-mesh scenes | Lower with proper LOD |
| Material | Surface Cache only | Surface Cache OR full hit-lighting |
| Payload | (no DXR payload) | `FLumenMinimalPayload` (small!) |
| Console | (default fallback) | `r.Lumen.HardwareRayTracing=1` |

## Translucency volumes

For transparent meshes that can't sample SceneColor at GBuffer locations:

```
LumenTranslucencyVolume*.usf
  → 3D froxel grid (frustum-aligned, log-Z)
  → injects radiance from cards/probes
  → Translucent BasePass samples this volume in forward shading
```

## Files map

| Stage | File |
|-------|------|
| Surface cache | `Lumen/LumenCard{Pixel,Vertex,Compute}Shader.usf`, `LumenCardCommon.ush`, `LumenCardBasePass.ush` |
| Card direct light | `LumenSceneDirectLighting*.usf`, `LumenDirectLighting*.usf` |
| Radiosity | `LumenRadiosity*.usf`, `LumenRadiosityProbeGather*.usf` |
| Radiance cache | `LumenRadianceCache.usf`, `LumenRadianceCacheCommon.ush`, `LumenRadianceCacheHardwareRayTracing.usf` |
| Screen probe | `LumenScreenProbeGather*.usf`, `LumenScreenProbeFiltering.usf`, `LumenScreenProbeIntegrate.usf`, `LumenScreenProbeTracing.usf`, `LumenIrradianceFieldGather.usf` |
| Reflections | `LumenReflections.usf`, `LumenReflectionTracing.usf`, `LumenReflectionHardwareRayTracing.usf`, `LumenReflectionDenoiser*.usf`, `LumenFrontLayerTranslucency.usf` |
| ReSTIR | `LumenReSTIRGather.usf` |
| SW RT infra | `LumenMeshSDFCulling.usf`, `LumenSceneTracing*.usf`, `LumenVoxelLighting*.usf` |
| HW RT infra | `LumenHardwareRayTracing*.usf`, `LumenHardwareRayTracingCommon.ush`, `LumenHardwareRayTracingPayloadCommon.ush`, `LumenHardwareRayTracingMaterials.usf`, `LumenHardwareRayTracingMissShader.usf`, `LumenHardwareRayTracingDeferredMaterials.usf` |
| Translucency volumes | `LumenTranslucencyVolume*.usf` |
| Visualize | `LumenVisualize*.usf`, `LumenVisualizeOctree*.usf` |

## Debug

| Symptom | Check |
|---------|-------|
| GI completely black | `r.Lumen.ScreenProbeGather`, `r.Lumen.RadianceCache` |
| Cards not capturing | Editor → Show → Visualize → Lumen Surface Cache |
| Reflections noisy | `r.Lumen.Reflections.Denoiser=0` for raw, then re-enable |
| HW RT shader hang | `LumenHardwareRayTracingMaterials.usf` payload size — keep minimal |
| Reflection ghosting | ReSTIR temporal weight; try `r.Lumen.ScreenProbeGather.ScreenTraces=0` |
| Ray count too high | Lumen quality scaling cvars; check `LumenMeshSDFCulling` results |
