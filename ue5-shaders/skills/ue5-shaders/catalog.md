---
name: catalog
description: File inventory for Engine/Shaders/ — every subfolder + key root-level files with one-line role.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: full (folder lists and file existence verified directly)
---

# File Catalog

## Top-level layout

```
Engine/Shaders/
├── Private/         (engine internals — most .usf/.ush)
├── Public/          (external-facing headers — 21 ush + Platform/)
├── Shared/          (C++/HLSL co-headers — 30+ .h)
└── StandaloneRenderer/   (Slate UI; D3D/ + OpenGL/)
```

## `Private/` subfolders (39)

| Folder | Files | Role |
|--------|-------|------|
| `ACES/` | 5 ush + tps | Color management — ACES 1.3 + 2.0 transforms |
| `Bloom/` | 11 usf+ush | Convolution bloom (FFT-style kernel pipeline) |
| `DiaphragmDOF/` | 22 usf+ush | Physical depth-of-field (CoC tile + gather + hybrid scatter) |
| `DistanceField/` | 9 | Global Distance Field clipmap build/update |
| `Froxel/` | 2 ush | Light/volume froxelization (3D grid build) |
| `GPUScene/` | 2 | GPU-side primitive/instance data writes (`GPUSceneWriter.ush`) |
| `HairStrands/` | 50+ | Strand simulation, deep shadow, Marschner BSDF, voxel/coverage |
| `HeterogeneousVolumes/` | 33 | Volumetric rendering — frustum/sparse voxel + live shading |
| `InstanceCulling/` | 6 | GPU instance culling, occlusion query, load balancing |
| `Landscape/` | (folder) | Heightfield-specific |
| `LightFunctionAtlas/` | 2 | Light-function materials → atlas |
| `LocalFogVolumes/` | 3 | Box/sphere local fog → froxel splat |
| `Lumen/` | 91 | GI: surface cache, radiance cache, reflections, ReSTIR, HW/SW RT |
| `MaterialCache/` | 8 | UV-space material baking (distinct from Lumen surface cache) |
| `MegaLights/` | 23 | GPU-driven light list, stochastic shading + denoise |
| `MotionBlur/` | 10 | Tile-based scatter-as-gather motion blur |
| `Nanite/` | 47 | Cluster culling, SW rasterizer, shade binning, RT, voxel |
| `OIT/` | 1 | `OITSorting.usf` — depth sort for transparency |
| `PathTracing/` | 40+ | Offline PT — Material/ + Light/ modular BSDFs |
| `PostProcessing/` | (folder) | Some newer PP passes (most still at root) |
| `RayTracing/` | 62 | Realtime RT — payloads, RayGen, hit groups, inline RT |
| `SMAA/` | 4 + tps | Subpixel Morphological AA (3-pass) |
| `SSRT/` | 6 | Screen-space ray tracing for diffuse/specular |
| `SceneCulling/` | 3 | Hierarchical scene-level culling |
| `ScreenSpaceDenoise/` | 20 | SSD signal framework — generic denoiser for noisy signals |
| `Skinning/` | 4 | Bone palette, anim bank evaluation |
| `SparseVolumeTexture/` | 2+ | OpenVDB-style sparse 3D textures |
| `StochasticLighting/` | 3 | Generic stochastic shadow tile classify + upsample |
| `Substrate/` | 24 | Closure-tree BSDF (modern UE5 default) |
| `TemporalSuperResolution/` | 23 | TSR upscaler — 10 compute passes + helpers |
| `Tools/` | 7 | Debug viz, FullscreenVertexShader, indirect-args setup |
| `VariableRateShading/` | 6 | VRS Tier-2 rate calculation/combine/foveated/reproject |
| `VirtualShadowMaps/` | 38 | Page mgmt, projection, SMRT, Nanite integration |

## Root-level `Private/` (legacy + foundation)

Foundation:

```
Common.ush                     # baseline include — MaterialFloat types, FloatDeriv
CommonViewUniformBuffer.ush
SceneData.ush                  # GPU Scene access (GetSceneDataIntermediates)
SceneTexturesCommon.ush        # GBuffer/Velocity/Depth RT access
DeferredShadingCommon.ush      # FGBufferData, GBuffer encode/decode
ShadingCommon.ush              # SHADINGMODELID_* (legacy)
BRDF.ush                       # GGX/Lambert/Burley + BxDFContext
ShadingModels.ush              # IntegrateBxDF (legacy path)
ShadingModelsMaterial.ush
ShadingModelsSampling.ush
ShadingEnergyConservation.ush
MaterialTemplate.ush           # ★ translator template (slots + helpers)
```

Material/BasePass:

```
BasePassPixelShader.usf
BasePassVertexShader.usf
BasePassCommon.ush
BasePassVertexCommon.ush
AnisotropyPassShader.usf
DepthOnlyPixelShader.usf / DepthOnlyVertexShader.usf
ShadowDepthPixelShader.usf / ShadowDepthVertexShader.usf
TranslucentShadowDepthShaders.usf
ShadowProjectionPixelShader.usf / ShadowProjectionVertexShader.usf
ShadowDepthCommon.ush / ShadowProjectionCommon.ush
ShadowFilteringCommon.ush / ShadowPercentageCloserFiltering.ush
CapsuleShadowShaders.usf
DistanceFieldShadowing.usf
VelocityShader.usf / VelocityUpdate.usf
HitProxyPixelShader.usf / HitProxyVertexShader.usf / HitProxyCopy.usf
DitheredTransitionStencil.usf
SingleLayerWaterComposite.usf / SingleLayerWaterRefractionCulling.usf
```

Lighting:

```
DeferredLightingCommon.ush
ForwardLightingCommon.ush
LightGridCommon.ush / LightGridInjection.usf
ClusteredDeferredShadingPixelShader.usf / VertexShader.usf
TranslucentLightingShaders.usf / TranslucentLightInjectionShaders.usf
DynamicLightingCommon.ush
VolumeLightingCommon.ush / VolumeLightingCommonSampling.ush
SkyLightingShared.ush / SkyLightingDiffuseShared.ush
DistanceFieldLightingPost.usf / DistanceFieldLightingShared.ush
DistanceFieldScreenGridLighting.usf
HybridIndirectLighting.ush
HeightfieldLightingShared.ush
```

Atmosphere/Cloud/Reflection:

```
SkyAtmosphere.usf / SkyAtmosphereCommon.ush
VolumetricCloud.usf / VolumetricCloudCommon.ush / VolumetricCloudMaterialPixelCommon.ush
HeightFogPixelShader.usf / HeightFogVertexShader.usf / HeightFogCommon.ush
ReflectionEnvironmentShaders.usf / ReflectionEnvironmentPixelShader.usf
ReflectionEnvironmentComposite.ush / ReflectionEnvironmentShared.ush
PlanarReflectionShaders.usf / PlanarReflectionShared.ush
AmbientCubemapComposite.usf
```

Vertex Factories (19):

```
LocalVertexFactory.ush / LocalVertexFactoryCommon.ush
GpuSkinVertexFactory.ush
LandscapeVertexFactory.ush
GeometryCollectionVertexFactory.ush / GeometryCacheVertexFactory.ush
ParticleSpriteVertexFactory.ush / ParticleBeamTrailVertexFactory.ush
MeshParticleVertexFactory.ush / ParticleGPUSpriteVertexFactory.ush
ParticleVertexFactoryCommon.ush
VectorFieldVisualizationVertexFactory.ush
VertexFactoryCommon.ush / VertexFactoryDefaultInterface.ush / VertexFactoryDefaultFwd.ush
HairStrands/HairStrandsVertexFactory.ush / HairCardsVertexFactory.ush
Nanite/NaniteVertexFactory.ush
```

Mobile:

```
MobileBasePassPixelShader.usf / MobileBasePassVertexShader.usf / MobileBasePassCommon.ush
MobileDeferredShading.usf / MobileDeferredUtils.usf
MobileFog.usf / MobileGGX.ush
MobileLightingCommon.ush / MobileLocalLightsBuffer.usf / MobileSSR.ush
SceneDataMobileLoader.ush / SceneDataMobileWriter.ush
PostProcessMobile.usf / PostProcessAmbientOcclusionMobile.usf
```

Post-process (root, alongside `Bloom/` `DiaphragmDOF/` `MotionBlur/` `SMAA/`):

```
PostProcessCommon.ush
PostProcessAmbientOcclusion.usf / PostProcessAmbientOcclusionCommon.ush
PostProcessBloom.usf            # legacy gaussian
PostProcessCombineLUTs.usf      # LUT + ACES
PostProcessDOF.usf              # legacy gaussian
PostProcessDownsample.usf
PostProcessEyeAdaptation.usf / PostProcessEyeAdaptationUtils.usf
PostProcessHistogram.usf / PostProcessHistogramReduce.usf / PostProcessHistogramCommon.ush
PostProcessLensFlares.usf
PostProcessLocalExposure.usf
PostProcessMaterialShaders.usf
PostProcessMitchellNetravali.usf
PostProcessSelectionOutline.usf
PostProcessSubsurface.usf / PostProcessSubsurfaceCommon.ush
PostProcessDeviceEncodingOnly.usf
PostProcessGBufferHints.usf
PostProcessHMD.usf
PostProcessNoiseBlur.usf
PostProcessPassThrough.usf
PostProcessAlphaInvert.usf
PostProcessCompositePrimitives.usf
PostProcessExposureMaterial.ush
ComposeSeparateTranslucency.usf
CompositeUIPixelShader.usf
```

Decals:

```
DBufferDecalShared.ush / DBufferNormalReprojection.ush / DecalCommon.ush
```

Skinning:

```
BoneTransform.ush               # FBoneTransform / FBoneTransformWithScale
```

Bink video:

```
Bink.usf
```

Math/utility helpers:

```
WorldSpaceMath.ush              # LWC (FWSVector3, FWSMatrix)
Quaternion.ush
FastMath.ush
Random.ush / SobolRandom.ush / MonteCarlo.ush
BlueNoise.ush
MortonCode.ush
OctahedralCommon.ush
ColorSpace.ush / ColorMap.ush / ColorUtils.ush / ColorDifference.ush / ColorDeficiency.ush
GammaCorrectionCommon.ush
PackUnpack.ush / BitPacking.ush / BinarySearch.ush
ASTCCompressionCommon.ush / BCCompressionCommon.ush / BlockCompressionCommon.ush
Quantization.ush
ByteBuffer.usf / ByteBuffer.ush
AssertionMacros.ush
```

Other lighting helpers:

```
CapsuleLight.ush / CapsuleLightIntegrate.ush / CapsuleLightSampling.ush
RectLight.ush
AreaLightCommon.ush
TransmissionCommon.ush
HairBsdf.ush / HairBsdfSample.ush / HairShadingCommon.ush
ClearCoatCommon.ush
BurleyNormalizedSSSCommon.ush / SubsurfaceProfileCommon.ush
SpecularProfileCommon.ush
ParticipatingMediaCommon.ush
ThinFilmBSDF.ush / ThinTranslucentCommon.ush
EyeAdaptationCommon.ush
```

## `Public/` (21 ush + Platform/)

```
Platform.ush                    # FEATURE_LEVEL_*, PLATFORM_GPU_ARCH_*
FP16Math.ush                    # half/min16float
BindlessResources.ush
RootConstants.ush
SubstratePublic.ush             # external module reads Substrate data
IndirectVirtualTexture.ush / IndirectVirtualTextureCommon.ush
LaneVectorization.ush / DualPixelVectorization.ush
WaveBroadcastIntrinsics.ush
OverloadMacros.ush
ShaderVersion.ush
Platform/D3D/   Platform/GL/   Platform/Metal/   Platform/Vulkan/
```

## `Shared/` C++/HLSL (30+ .h)

→ See [defines.md](defines.md) for the constants in each.

```
HLSLTypeAliases.h / HLSLMathAliases.h / HLSLReservedSpaces.h / HLSLStaticAssert.h
LightDefinitions.h / LightSceneData.h / LightViewData.h / LightGridDefinitions.h
SceneDefinitions.h / SceneCullingDefinitions.h / InstanceCullingDefinitions.h
LumenDefinitions.h / MegaLightsDefinitions.h
NaniteDefinitions.h / NaniteRayTracingDefinitions.h
RayTracingDefinitions.h / RayTracingPayloadType.h / RayTracingTypes.h
RayTracingBuiltInResources.h / RayTracingDebugTypes.h / RaytracingDebugDefinitions.h
PathTracingDefinitions.h
SubstrateDefinitions.h / SubstrateVisualizeDefinitions.h
VirtualShadowMapDefinitions.h
SkinningDefinitions.h / SplineMeshShaderParams.h
FroxelDefinitions.h / SingleLayerWaterDefinitions.h
HairStrandsDefinitions.h
RenderCurveDefinitions.h / EnvironmentComponentsFlags.h
IndirectVirtualTextureDefinitions.h / MaterialCacheDefinitions.h
ViewDefinitions.h
ThirdParty/{AMD,NVIDIA,Intel}/  (vendor intrinsics)
```

## `StandaloneRenderer/` (Slate UI bootstrap)

```
D3D/SlateDefaultVertexShader.hlsl     D3D/SlateElementPixelShader.hlsl
D3D/GammaCorrectionCommon.hlsl
OpenGL/SlateVertexShader.glsl         OpenGL/SlateElementPixelShader.glsl
OpenGL/SplashVertexShader.glsl        OpenGL/SplashFragmentShader.glsl
```

Raw `.hlsl` / `.glsl` — does **not** go through the UE shader compiler / translator.
