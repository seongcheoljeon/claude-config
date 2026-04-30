---
name: flow-postprocess
description: Post-process pipeline — Bloom, DiaphragmDOF, MotionBlur, SMAA, ACES tonemap, SSD denoise framework, VRS.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: full (folder file lists verified; SSD signal config verified by source)
---

# Post-Process & Denoise Flow

## Typical post-process order (after rendering)

```
SceneColor (HDR linear)
  ↓
[SSD denoise] — for Lumen/RT/SSGI/AO/shadow signals (see SSD framework)
  ↓
[Translucent composite] — ComposeSeparateTranslucency.usf
  ↓
[MotionBlur] — Private/MotionBlur/
  ↓
[DepthOfField] — Private/DiaphragmDOF/  (or PostProcessDOF.usf legacy)
  ↓
[Bloom] — Private/Bloom/  (or PostProcessBloom.usf legacy)
  ↓
[Lens flare / Local exposure] — PostProcess{LensFlares, LocalExposure}.usf
  ↓
[EyeAdaptation read] — PostProcessEyeAdaptation.usf  (histogram from earlier in frame)
  ↓
[CombineLUTs + Tonemap] — PostProcessCombineLUTs.usf  + ACES path
  ↓
[TSR / TAA / SMAA / FXAA] — depends on r.AntiAliasingMethod
  ↓
[DeviceEncoding] — PostProcessDeviceEncodingOnly.usf  (sRGB/Rec709/PQ/Rec2020)
  ↓
Final framebuffer
```

## Bloom (modern convolution-based)

`Private/Bloom/` — FFT-style kernel pipeline (11 files):

```
BloomCommon.ush

# Kernel preparation
BloomFindKernelCenter.usf
BloomResizeKernel.usf
BloomClampKernel.usf
BloomDownsampleKernel.usf

# Energy survey (normalization)
BloomReduceKernelSurvey.usf
BloomSurveyKernelCenterEnergy.usf
BloomSurveyMaxScatterDispersion.usf
BloomSumScatterDispersionEnergy.usf

# Apply
BloomPackKernelConstants.usf
BloomFinalizeApplyConstants.usf
```

Custom kernel image (lens-shape) → resize → energy normalize → convolve.

Cvars: `r.Bloom.HalfResolutionFFT`, `r.Bloom.AsyncCompute`.

Legacy gaussian: `Private/PostProcessBloom.usf`.

## DiaphragmDOF — physical bokeh (22 files)

`Private/DiaphragmDOF/`:

```
# Setup
DOFSetup.usf
DOFCommon.ush
DOFReduce.usf
DOFDownsample.usf / .ush

# Circle of Confusion tile classification
DOFCocTileCommon.ush
DOFCocTileFlatten.usf            tile CoC min/max
DOFCocTileDilate.usf

# Gather (separate FG/BG, accumulate)
DOFGatherCommon.ush
DOFGatherKernel.ush
DOFGatherAccumulator.ush
DOFGatherTileSuggest.ush
DOFGatherPass.usf

# Hybrid scatter (large-CoC pixels splatted as vertices)
DOFHybridScatterCommon.ush
DOFHybridScatterCompilation.usf / .ush
DOFHybridScatterVertexShader.usf
DOFHybridScatterPixelShader.usf

# Postfilter + recombine
DOFPostfiltering.usf
DOFRecombine.usf

# Bokeh + vignette
DOFBokehLUT.usf                  diaphragm shape LUT
DOFVignetteCommon.ush
```

Pipeline: Setup → CocFlatten → CocDilate → Downsample → GatherPass (FG + BG) → HybridScatter (big CoC) → Postfiltering → Recombine.

Cvars: `r.DOF.Algorithm`, `r.DOF.Kernel.MaxBackgroundRadius`, `r.DOF.Recombine.Quality`.

Legacy gaussian: `Private/PostProcessDOF.usf`.

## MotionBlur — tile-based scatter-as-gather

`Private/MotionBlur/` (10 files):

```
MotionBlurCommon.ush

# Velocity flatten
MotionBlurVelocityFlatten.usf / .ush     per-tile max velocity

# Tile classify
MotionBlurFilterTileClassify.usf

# Scatter / gather
MotionBlurTileScatter.usf                neighbors receive motion
MotionBlurTileGather.usf                 self + neighbors collected

# Apply
MotionBlurApply.usf

# Debug
MotionBlurVisualize.usf
VisualizeMotionVectors.usf
```

McGuire-2012 style. Cvars: `r.MotionBlurQuality`, `r.MotionBlur.HalfResolution`.

## SMAA — subpixel morphological AA (3-pass)

`Private/SMAA/`:

```
SMAA.ush                                    core algorithm
SMAACommon.ush
SMAAEdgeDetectionShader.usf                 1: luma/color/depth-based edge detect
SMAABlendingWeightCalculationShader.usf     2: area/search LUT → weights
SMAANeighborhoodBlendingShader.usf          3: weighted blend
SMAADebugVisualization.usf
```

`r.AntiAliasingMethod 0=None 1=FXAA 2=TAA 3=MSAA 4=TSR` — SMAA isn't directly bound to that switch in modern UE5 (mostly subsumed by TSR). Available via post-process material if needed.

## ACES — color management

`Private/ACES/` (UE 5.7 introduces ACES 1.3 + 2.0):

```
ACESCommon.ush                          shared
ACESTonescale.ush                       RRT tonescale
ACESOutputTransform.ush                 RRT + ODT combined
ACESDisplayEncoding.ush                 sRGB / Rec709 / Rec2020 / PQ HDR encode
ACESUtilities.ush                       color matrices, transfer functions
ACES_v1.3.ush                           v1.3
# v2.0 .tps license bundled
```

Called from `PostProcessCombineLUTs.usf` and `PostProcessDeviceEncodingOnly.usf`.

Cvars: `r.TonemapperFilm`, `r.HDR.Display.OutputDevice`.

## Eye Adaptation (auto-exposure)

```
PostProcessHistogram.usf                  build histogram (CS)
PostProcessHistogramReduce.usf            reduce
PostProcessHistogramCommon.ush
PostProcessEyeAdaptation.usf              EV solve
PostProcessEyeAdaptationUtils.usf
PostProcessLocalExposure.usf              spatial local exposure
PostProcessExposureMaterial.ush
EyeAdaptationCommon.ush                   read EV in any shader
```

History-based: histogram of N-1 → exposure for N. `r.EyeAdaptationQuality`.

## SSD — Screen-Space Denoise framework (20 files)

`Private/ScreenSpaceDenoise/`:

```
# Core
DenoisingCommon.ush
SSDCommon.ush
SSDDefinitions.ush
SSDPublic.ush                              external API

# Signal abstraction (the magic)
SSDSignalCore.ush                          FSSDSignalSample (sample count + payload)
SSDSignalFramework.ush                     framework + CONFIG_SIGNAL_PROCESSING dispatch
SSDSignalAccumulator.ush                   per-pixel accumulator state
SSDSignalAccumulatorArray.ush
SSDSignalArray.ush                         multiple multiplexed signals
SSDSignalCompression.ush                   variance-preserving pack
SSDSignalBufferEncoding.ush
SSDPublicHarmonics.ush                     SH for IBL / shadow
SSDPublicBufferEncoding.ush

# Metadata
SSDMetadata.ush
SSDCompressMetadata.usf                    pack normal/depth/material ID

# Compute passes
SSDInjest.usf                              noisy input → signal
SSDSpatialAccumulation.usf                 bilateral filter
SSDSpatialKernel.ush
SSDTemporalAccumulation.usf                velocity reproj + history
SSDComposeHarmonics.usf                    SH combine
```

### Signal types (`CONFIG_SIGNAL_PROCESSING`)

```hlsl
SIGNAL_PROCESSING_SHADOW_VISIBILITY_MASK
SIGNAL_PROCESSING_POLYCHROMATIC_PENUMBRA_HARMONIC
SIGNAL_PROCESSING_REFLECTIONS                 // pulls MonteCarlo + BRDF + DeferredShadingCommon
SIGNAL_PROCESSING_AO
SIGNAL_PROCESSING_DIFFUSE_INDIRECT_AND_AO
SIGNAL_PROCESSING_DIFFUSE_SPHERICAL_HARMONIC
SIGNAL_PROCESSING_SSGI
SIGNAL_PROCESSING_DIFFUSE_PROBE_HIERARCHY
```

Each pass `#define`s its signal type, then includes `SSDSignalFramework.ush`. Different signals get different bilateral weights, history rules, harmonic projection.

### Required defines per pass

```hlsl
MAX_SIGNAL_BATCH_SIZE       // # independent signals denoised together
SIGNAL_ARRAY_SIZE           // multiplexed sample count
COMPILE_SIGNAL_COLOR
COMPILE_SIGNAL_COLOR_SH
COMPILE_SIGNAL_COLOR_ARRAY
```

Used by: Lumen reflection / GI denoise, RT AO/shadow/GI denoise, SSGI, screen-space shadow.

## Stochastic Lighting denoise (3 files)

`Private/StochasticLighting/`:

```
StochasticLightingCommon.ush
StochasticLightingTileClassification.usf      tile noise variance
StochasticLightingUpsample.ush
```

Lighter-weight than SSD — for stochastic shadow / sampled lighting general-purpose.

## VRS — Variable Rate Shading (6 files)

`Private/VariableRateShading/`:

```
VRSShadingRateCommon.ush

VRSShadingRateCalculate.usf                motion + luminance based tile rate
VRSShadingRateCombine.usf                  merge multiple sources
VRSShadingRateFoveated.usf                 gaze-centered (XR/HMD)
VRSShadingRateReproject.usf                temporal coherence
VRSShadingRatePreview.usf                  visualize
```

D3D12 / Vulkan VRS Tier 2. `r.VRS.Enable`, `r.VRS.ContrastAdaptiveShading`.

## Post-process material domain

`Private/PostProcessMaterialShaders.usf` — runs material shader as a screen-space pass with full GBuffer access. Used by post-process volumes / chains.

## Misc

```
PostProcessLensFlares.usf
PostProcessSelectionOutline.usf            editor-only
PostProcessCompositePrimitives.usf         editor primitives
PostProcessGBufferHints.usf                debug GBuffer overlay
PostProcessSubsurface.usf                  SSS blur
PostProcessSubsurfaceCommon.ush
PostProcessHMD.usf                         HMD distortion
PostProcessAlphaInvert.usf
PostProcessNoiseBlur.usf
PostProcessPassThrough.usf
PostProcessMitchellNetravali.usf           upsample filter
PostProcessAmbientOcclusion.usf            legacy SSAO
PostProcessAmbientOcclusionCommon.ush
PostProcessAmbientOcclusionMobile.usf
PostProcessMobile.usf                      single-pass mobile combined
```

## Bink Video

```
Private/Bink.usf            decode + colorspace
```

## Common debug

```
Stat GPU                                 per-pass timings
r.PostProcessing.PreferCompute           compute over pixel where possible
r.MotionBlurQuality
r.DOF.Algorithm
r.Bloom.AsyncCompute
r.SceneColorFringeQuality                chromatic aberration
r.Tonemapper.Quality
r.AntiAliasingMethod
r.HDR.Display.OutputDevice
r.LocalExposure
r.EyeAdaptationQuality
```
