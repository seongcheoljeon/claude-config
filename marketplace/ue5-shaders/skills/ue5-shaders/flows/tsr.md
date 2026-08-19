---
name: flow-tsr
description: TSR (Temporal Super Resolution) — UE5 default upscaler. 10-stage compute pipeline.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: full (file list verified; TSRRejectShading entry helpers verified by line)
---

# TSR Flow — Temporal Super Resolution

## Concept

- Render at low resolution (e.g. 50%) → temporally accumulate samples → reconstruct high-resolution output.
- 10 compute passes, plus a fallback spatial AA path.
- Uses **wave-cooperative LDS-tiled spatial convolution** (not a neural network — see [quirks.md](../quirks.md#tsr-is-not-a-neural-network)).
- History rejection via color variance + Moiré detection + thin geometry guards.

## Pipeline (10 main passes + helpers)

```
1. TSRClearPrevTextures.usf
   First frame / camera cut: clear history.

2. TSRDilateVelocity.usf
   Max-filter the velocity buffer (preserves subpixel motion).

3. TSRDecimateHistory.usf
   Downsample history to processing resolution.

4. TSRDetectThinGeometry.usf
   Identify hair / wires / sub-pixel triangles → special-case weights.

5. TSRMeasureCoverage.usf
   Per-pixel coverage estimate (motion confidence).

6. TSRMeasureFlickeringLuma.usf
   Luma variance over time → flag pixels prone to specular flicker / RT noise ghosting.

7. TSRRejectShading.usf
   Color-variance based ghost detection.
   - Wave-cooperative spatial convolution (TSRConvolutionNetwork.ush)
   - Dozens of Fetch* helpers (see api.md for verified list)
   - OverwriteReprojectionFieldWithResurrection for occluded pixels

8. TSRUpdateHistory.usf
   Reproject prev history with velocity, accumulate new sample with weight.

9. TSRResolveHistory.usf
   Reconstruct at output resolution.

10. TSRSpatialAntiAliasing.usf
    Spatial AA for regions where history is rejected.

(plus)
TSRWeightRelaxation.usf       — weight smoothing
TSRVisualize.usf              — debug
```

## Files

```
Private/TemporalSuperResolution/

# Main passes
TSRClearPrevTextures.usf
TSRDilateVelocity.usf
TSRDecimateHistory.usf
TSRDetectThinGeometry.usf
TSRMeasureCoverage.usf
TSRMeasureFlickeringLuma.usf
TSRRejectShading.usf
TSRUpdateHistory.usf
TSRResolveHistory.usf
TSRSpatialAntiAliasing.usf
TSRWeightRelaxation.usf
TSRVisualize.usf

# Shared headers
TSRCommon.ush
TSRColorSpace.ush                # YCoCg / luma transforms
TSRClosestOccluder.ush           # near-depth lookup for reproj
TSRDepthVelocityAnalysis.ush
TSRReprojectionField.ush         # reproject grid struct
TSRKernels.ush                   # spatial kernel definitions
TSRShadingAnalysis.ush
TSRThinGeometryCommon.ush
TSRSpatialAntiAliasing.ush

# Wave-cooperative convolution (NOT neural)
TSRConvolutionNetwork.ush        # requires WAVE_COUNT_X/Y, LANE_COUNT_X/Y; uses LaneVectorization.ush
TSRConvolutionNetworkPass.ush    # per-pass instantiation
```

## TSRRejectShading entry helpers (verified line numbers)

```hlsl
void FetchThinGeometryEdge(...);                         // 123
void FetchDecimateMask(...);                             // 142
void FetchSceneColorAndTranslucency(...);                // 165
void FetchHistoryGuide(...);                             // 183
void FetchReprojectedHistoryGuide(...);                  // 211
void FetchMoireInput(...);                               // 226
void FetchResurrectedHistoryGuide(...);                  // 248
void FetchDeviceZ(...);                                  // 319
void OverwriteReprojectionFieldWithResurrection(
    tsr_tensor_bool bResurrectHistory,
    tsr_tensor_float DeviceZ);                            // 334
void RefetchInputAndHistoryFromLDSOrCache(...);          // 404
```

`tsr_tensor_*` types come from `TSRConvolutionNetwork.ush` — they encode lane×wave 2D tensors over LDS.

## "Resurrection" mechanism

When a pixel's history is rejected (disocclusion, ghost), `OverwriteReprojectionFieldWithResurrection` can pull color from a previously-validated buffer rather than falling all the way to spatial AA. This is the key trick for thin geometry that disappears/reappears between frames.

## Inputs / outputs

| Input | Source |
|-------|--------|
| Pre-tonemap SceneColor | Renderer output |
| Velocity buffer | `VelocityShader.usf` / `VelocityUpdate.usf` |
| SceneDepth | depth prepass |
| Stencil | per-primitive flags |
| Prev frame history | TSR's own ring buffer |

| Output | Consumer |
|--------|----------|
| Reconstructed SceneColor (output res) | Tonemap / post-process |
| Updated history | next frame's TSR |

## Quality controls

```
r.TSR.History.R11G11B10           // 0=RGBA16F, 1=R11G11B10F (smaller history)
r.TSR.History.SampleCount         // accumulation cap
r.TSR.RejectionAntiAliasingQuality
r.TSR.ShadingRejection.Flickering.Period
r.TSR.Velocity.WeightClampingSampleCount
r.AntiAliasingMethod              // 0=None 1=FXAA 2=TAA 3=MSAA 4=TSR
```

## Choosing TSR vs alternatives

| Method | When |
|--------|------|
| **TSR** | Default. Best quality + upscaling. Needs Velocity. |
| **TAA** (legacy) | UE4-style temporal AA. Falling out of use. |
| **FXAA** | Cheap fallback. Single-frame. Mobile. |
| **SMAA** | Higher quality single-frame. Mobile/low-end. See `Private/SMAA/`. |
| **MSAA** | Forward path only. Limited use in deferred. |
| **None** | Reference / debug. |

## Debug

- `r.TSR.Visualize` — overlay (rejected pixels, velocity, history weight)
- `r.TSR.RejectionAntiAliasingQuality 0` — disable convolution-based rejection (raw temporal accum)
- `Stat GPU` — per-stage cost
- Camera cut frame: full-frame rejection — first-frame artifacts are expected

## Common issues

- **Ghosting on specular**: increase flickering period; or denoise upstream (Lumen / RT / SSD).
- **Disoccluded edges shimmer**: thin-geometry pass + resurrection guards; check `r.TSR.ShadingRejection.*`.
- **Fizzle on small UI elements**: stencil-mark UI with `Custom Stencil` and exclude from TSR via material flag.
- **Slow on console**: drop to `R11G11B10` history (`r.TSR.History.R11G11B10=1`).
