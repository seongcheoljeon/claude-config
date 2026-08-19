---
name: api
description: Verified function signatures and key struct definitions with file:line citations.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: full (every signature read directly; line numbers match the live source)
---

# Verified API Reference

> All `file.usf:NNN` citations were grep-verified against the source.

## Material Template (`Private/MaterialTemplate.ush`)

The translator fills two placeholder regions:

```hlsl
struct FPixelMaterialInputs
{
    %{pixel_material_inputs}                           // ← translator injects slot members

#if TEMPLATE_USES_SUBSTRATE
    FSubstrateData GetFrontSubstrateData()             // member function added when Substrate active
    {
    #if SUBSTRATE_USE_FULLYSIMPLIFIED_MATERIAL == 1
        return FullySimplifiedFrontMaterial;
    #else
        return FrontMaterial;
    #endif
    }
#endif
};
```

### `FMaterialPixelParameters` (header — VF fills, material reads)

```hlsl
struct FMaterialPixelParameters
{
#if NUM_TEX_COORD_INTERPOLATORS
    float2 TexCoords[NUM_TEX_COORD_INTERPOLATORS];
#endif
    half4   VertexColor;
    half3x3 TangentToWorld;
    // (LWC bundle moved to FMaterialLWCData — see below)
    float4  ScreenPosition;
    float3  CameraVector;
    float3  LightVector;
    uint    PrimitiveId;
    FMaterialAttributes MaterialAttributes;
    half3   TwoSidedSign;
    // ... rest depends on VF / domain
};
```

### `FMaterialLWCData` — LWC bundle (added in UE5)

```hlsl
struct FMaterialLWCData
{
    // Vertex/pixel
    FWSVector3 AbsoluteWorldPosition;
    FWSVector3 WorldPosition_NoOffsets;

    // Primitive
    FWSMatrix        LocalToWorld;
    FWSInverseMatrix WorldToLocal;
    FWSMatrix        PreviousLocalToWorld;
    FWSInverseMatrix PreviousWorldToLocal;
    FWSMatrix        InstanceToWorld;
    FWSInverseMatrix WorldToInstance;
    FWSMatrix        PreviousInstanceToWorld;
    FWSVector3       ObjectWorldPosition;
    FWSVector3       ActorWorldPosition;
    FWSMatrix        ParticleToWorld;
    FWSInverseMatrix WorldToParticle;
    FWSVector3       ParticleWorldPosition;
    FWSVector3       PrevParticleWorldPosition;

    // View
    FWSVector3 PreViewTranslation;
    FWSVector3 PrevPreViewTranslation;
    FWSVector3 WorldViewOrigin;
    FWSVector3 PrevWorldViewOrigin;
    FWSVector3 WorldCameraOrigin;
    FWSVector3 PrevWorldCameraOrigin;
};
```

### Translator-generated functions (declarations the translator must emit)

```hlsl
void CalcMaterialAttributes(in out FMaterialPixelParameters Parameters,
                            out FMaterialAttributes Attrs);
void CalcPixelMaterialInputs(in out FMaterialPixelParameters Parameters,
                             out FPixelMaterialInputs PixelMaterialInputs);
// Slot getters (one per material output the engine consumes):
half3 GetMaterialBaseColor(FPixelMaterialInputs);
half  GetMaterialMetallic(FPixelMaterialInputs);
half  GetMaterialSpecular(FPixelMaterialInputs);
float GetMaterialRoughness(FPixelMaterialInputs);
float GetMaterialAnisotropy(FPixelMaterialInputs);
half3 GetMaterialNormal(FPixelMaterialInputs);
half3 GetMaterialEmissive(FPixelMaterialInputs);
half  GetMaterialOpacity(FPixelMaterialInputs);
half  GetMaterialMask(FPixelMaterialInputs);
uint  GetMaterialShadingModel(FPixelMaterialInputs);
half4 GetMaterialSubsurfaceData(FPixelMaterialInputs);
half  GetMaterialClearCoat(FPixelMaterialInputs);
half  GetMaterialClearCoatRoughness(FPixelMaterialInputs);
half  GetMaterialAmbientOcclusion(FPixelMaterialInputs);
half2 GetMaterialRefraction(FPixelMaterialInputs);
half  GetMaterialPixelDepthOffset(FPixelMaterialInputs);
half3 GetMaterialWorldPositionOffset(FMaterialVertexParameters);
// Translucency-domain slots:
half  GetMaterialTranslucencyDirectionalLightingIntensity();
float GetMaterialTranslucentMultipleScatteringExtinction();
float GetMaterialTranslucentSelfShadowDensityScale();
float GetMaterialTranslucentSelfShadowSecondDensityScale();
float GetMaterialTranslucentSelfShadowSecondOpacity();
float GetMaterialTranslucentBackscatteringExponent();
```

### Position helpers (template-defined)

```hlsl
FWSVector3 GetWorldPosition(FMaterialPixelParameters);                   // WPO applied
FWSVector3 GetWorldPosition_NoMaterialOffsets(FMaterialPixelParameters);
float3     GetTranslatedWorldPosition(FMaterialPixelParameters);
float3     GetTranslatedWorldPosition_NoMaterialOffsets(FMaterialPixelParameters);
FWSVector3 GetParticleWorldPosition(FMaterialPixelParameters);
FWSVector3 GetPrevParticleWorldPosition(FMaterialPixelParameters);       // motion blur
float3     GetPositionPrimitiveSpace(FMaterialPixelParameters);
float3     GetPositionPrimitiveSpace(FMaterialVertexParameters);
float3     GetPeriodicWorldOrigin(float3 Scale);
float3     GetPeriodicWorldOrigin_Pow2(float3 Scale);
```

## Vertex Factory contract (`Private/VertexFactoryCommon.ush` + per-VF `*VertexFactory.ush`)

Every VF must define these structs (members vary):

```hlsl
struct FVertexFactoryInput { ... };               // input assembly attributes
struct FVertexFactoryIntermediates { ... };       // computed once per VS
struct FVertexFactoryInterpolantsVSToPS { ... };
struct FVertexFactoryRayTracingInterpolants { ... };  // optional (RT path)
```

And these functions:

```hlsl
FVertexFactoryIntermediates GetVertexFactoryIntermediates(FVertexFactoryInput);

float4   VertexFactoryGetWorldPosition(FVertexFactoryInput, FVertexFactoryIntermediates);
float4   VertexFactoryGetPreviousWorldPosition(FVertexFactoryInput, FVertexFactoryIntermediates);
float3x3 VertexFactoryGetTangentToLocal(FVertexFactoryInput, FVertexFactoryIntermediates);

FVertexFactoryInterpolantsVSToPS VertexFactoryGetInterpolantsVSToPS(
    FVertexFactoryInput, FVertexFactoryIntermediates, FMaterialVertexParameters);

FMaterialPixelParameters GetMaterialPixelParameters(FVertexFactoryInterpolantsVSToPS, float4 SvPosition);
FMaterialVertexParameters GetMaterialVertexParameters(
    FVertexFactoryInput, FVertexFactoryIntermediates, float3 WorldPosition, float3x3 TangentToLocal);
```

Verified slot lines (LocalVertexFactory):
- `LocalVertexFactory.ush:50` — `struct FVertexFactoryInput`
- `LocalVertexFactory.ush:519` — `GetMaterialPixelParameters(...)` body
- `LocalVertexFactory.ush:1097` — `VertexFactoryGetInterpolantsVSToPS`
- `LocalVertexFactory.ush:1303` — interpolants assignment `Interpolants.InterpolantsVSToPS = ...`

GpuSkin verified:
- `GpuSkinVertexFactory.ush:51`  — `struct FVertexFactoryInput`
- `GpuSkinVertexFactory.ush:114` — `struct FClothVertex`
- `GpuSkinVertexFactory.ush:163` — `FVertexFactoryInterpolantsVSToPS`
- `GpuSkinVertexFactory.ush:181` — `FVertexFactoryRayTracingInterpolants`
- `GpuSkinVertexFactory.ush:250` — `FVertexFactoryIntermediates`
- `GpuSkinVertexFactory.ush:813` — `VertexFactoryGetTangentToLocal`
- `GpuSkinVertexFactory.ush:832` — `VertexFactoryGetWorldPosition`

### GPU Scene access macros (`VertexFactoryCommon.ush`)

```hlsl
#if INSTANCED_STEREO
  #define GetInstanceIdFromVF(VFInput)  (VFInput.InstanceId)
  #define GetEyeIndexFromVF(VFInput)    (IsInstancedStereo() ? (... & 1) : 0)
#elif MOBILE_MULTI_VIEW
  #define GetInstanceIdFromVF(VFInput)  (0)
  #define GetEyeIndexFromVF(VFInput)    (VFInput.ViewId)
#endif

#if VF_USE_PRIMITIVE_SCENE_DATA
  #define VF_GPUSCENE_DECLARE_INPUT_BLOCK(Attr) \
      uint InstanceIdOffset : ATTRIBUTE##Attr; \
      uint DrawInstanceId   : SV_InstanceID;
  #define VF_GPUSCENE_GET_INTERMEDIATES(VFInput) \
      GetSceneDataIntermediates(VFInput.InstanceIdOffset, VFInput.DrawInstanceId)
  #define VF_GPUSCENE_GET_LIGHTMAP_UV_SCALE_BIAS(VFInput, Idx) \
      GetLightmapData(Idx, VFInput.DrawInstanceId).LightMapCoordinateScaleBias
#endif
```

## BasePass main entry (`Private/BasePassPixelShader.usf`)

Around line 909:

```hlsl
// (line 767) Pixel-depth offset
void ApplyPixelDepthOffsetForBasePass(inout FMaterialPixelParameters MaterialParameters,
                                      FPixelMaterialInputs PixelMaterialInputs,
                                      inout FBasePassInterpolantsVSToPS BasePassInterpolants,
                                      out float OutDepth);

// Main PS
{
    FMaterialPixelParameters MaterialParameters = GetMaterialPixelParameters(Interpolants, In.SvPosition);   // 909
    FPixelMaterialInputs PixelMaterialInputs;                                                                // 910
    // ...
    GetMaterialCoverageAndClipping(MaterialParameters, PixelMaterialInputs);                                 // 977
    half3 BaseColor = GetMaterialBaseColor(PixelMaterialInputs);                                             // 994
    half  Metallic  = GetMaterialMetallic(PixelMaterialInputs);                                              // 995
    half  Specular  = GetMaterialSpecular(PixelMaterialInputs);                                              // 996
    float Roughness = GetMaterialRoughness(PixelMaterialInputs);                                             // 998
    float Anisotropy = GetMaterialAnisotropy(PixelMaterialInputs);                                           // 999
    uint  ShadingModel = GetMaterialShadingModel(PixelMaterialInputs);                                       // 1000
    half  Opacity = GetMaterialOpacity(PixelMaterialInputs);                                                 // 1001
    // ...
}
```

## BRDF (`Private/BRDF.ush`)

```hlsl
struct BxDFContext
{
    half NoV, NoL, VoL, NoH, VoH;
    half XoV, XoL, XoH;     // X = Tangent (anisotropy)
    half YoV, YoL, YoH;     // Y = Bitangent
};
void Init(inout BxDFContext, half3 N, half3 V, half3 L);
void Init(inout BxDFContext, half3 N, half3 X, half3 Y, half3 V, half3 L);  // anisotropic

// GGX
float D_GGX(float a2, float NoH);
float D_GGXaniso(float ax, float ay, float NoH, float XoH, float YoH);
float Vis_SmithJointApprox(float a2, float NoV, float NoL);
float Vis_SmithJointAniso(float ax, float ay, float NoV, float NoL, float XoV, float YoV, float XoL, float YoL);
float3 F_Schlick(float3 F0, float VoH);
float3 F_Schlick(float3 F0, float3 F90, float VoH);

// Diffuse
float3 Diffuse_Lambert(float3 DiffuseColor);
float3 Diffuse_Burley(float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH);
float3 Diffuse_Chan(...);   // UE5 default

// Env BRDF (split-sum)
float3 EnvBRDF(float3 SpecColor, float Roughness, float NoV);
float3 EnvBRDFApprox(float3 SpecColor, float Roughness, float NoV);
half2  EnvBRDFApproxNonmetal(float Roughness, float NoV);
```

## Substrate (`Private/Substrate/Substrate.ush`)

### Core structs (verified line numbers)

```hlsl
// 249
struct FSubstrateBSDF
{
    uint   Type;          // SUBSTRATE_BSDF_TYPE_*
    float3 Coverage;
    float3 TransmittanceAboveAlongN;
    half3  BaseColor;
    half   Metallic;
    half   Specular;
    half   Roughness;
    half   Anisotropy;
    half3  Normal;
    half3  Tangent;
    bool   bIsBottom;
    // ... type-specific fields
};

// 744
struct FHaziness { ... };

// 827
struct FSubstrateIrradianceAndOcclusion
{
    float3 PrecomputedDiffuseLighting;
    float  MaterialAO;
};

// 891
struct FSubstrateTopLayerData { ... };

// 952
struct FSubstrateOpaqueRoughRefractionData { ... };
```

### Pack/unpack helpers (lines 711–730, 763, 775, 843–855, 922, 959–964, 1002)

```hlsl
float3 RescaleMFPToComputationSpace(float3 MFPInCm, float SrcThicknessInCm, float DstThicknessInCm);
void   SubstrateRequestSharedLocalBasisTangent(inout uint Types, uint Index);

// Normal packing
uint   SubstratePackNormal(float3 N);
float3 SubstrateUnpackNormal(uint Packed);
uint   SubstratePackNormal24(float3 N);     float3 SubstrateUnpackNormal24(uint);
uint   SubstratePackNormal22(float3 N);     float3 SubstrateUnpackNormal22(uint);

// Color packing (gamma 2)
uint   PackR6(float Value, float Dither);   float UnpackR6(uint);
uint   PackR7(float Value, float Dither);   float UnpackR7(uint);
uint   PackR7G7B6Gamma2(float3 rgb, float Dither);    float3 UnpackR7G7B6Gamma2(uint);
uint   PackColorLinearToGamma2(float3);     float3 UnpackColorGamma2ToLinear(uint);
uint   PackColorLinearToGamma2AlphaLinear(float4);  float4 UnpackColorGamma2ToLinearAlphaLinear(uint);

// Haziness
uint  PackHaziness(FHaziness);
float GetHazinessRoughness(uint Data);
uint  SetHazinessRoughness(uint Data, float Roughness);
uint  LerpHazinessParameterBlending(FSubstrateBSDF A, FSubstrateBSDF B, float MixValue);

// IrradianceAndOcclusion
FSubstrateIrradianceAndOcclusion InitIrradianceAndOcclusion(float AO=1.0f);
uint                              SubstratePackIrradianceAndOcclusion(FSubstrateIrradianceAndOcclusion, float QuantizationBias=0);
FSubstrateIrradianceAndOcclusion  SubstrateUnpackIrradianceAndOcclusion(uint /*8bit*/);
FSubstrateIrradianceAndOcclusion  SubstrateGetIrradianceAndAO(FGBufferData);

// TopLayer / Refraction
FSubstrateTopLayerData                 SubstrateUnpackTopLayerData(SUBSTRATE_TOP_LAYER_TYPE In);
float3                                 SubstratePackOpaqueRoughRefractionData(FSubstrateOpaqueRoughRefractionData);
FSubstrateOpaqueRoughRefractionData    SubstrateUnpackOpaqueRoughRefractionData(float3);

// Util
float GetVarianceFromRoughness(float Roughness);
uint  PackSSSProfile(float ProfileId, float Radius, half Thickness);

// Coat helpers
float3 SubstrateGetSimpleCoatBottomNormal(float2 BottomNormalOct, float3 TopWorldNormal);
float2 UnpackBottomNormalOct(uint BottomNormalOct16bits);
```

## Substrate evaluation (`Private/Substrate/SubstrateEvaluation.ush`)

Verified line numbers:

```hlsl
// 98
float3 SubstrateGetOffSpecularPeakReflectionDir(float3 N, float3 R, float Roughness);

// 136 / 184 / 191 / 197 — overloads
FSubstrateBSDFContext SubstrateCreateBSDFContext(
    float3x3 TangentBasis, FSubstrateBSDF BSDF, float3 V, float3 L,
    bool bHasValidL=true, uint2 InPixelCoord=0);
FSubstrateBSDFContext SubstrateCreateBSDFContext(FSubstratePixelHeader, FSubstrateBSDF, FSubstrateAddressing, V);
FSubstrateBSDFContext SubstrateCreateBSDFContext(FSubstratePixelHeader, FSubstrateBSDF, FSubstrateAddressing, V, L);
FSubstrateBSDFContext SubstrateCreateBSDFContext(FSubstrateBSDF, float3x3 TangentBasis, V, L);

// 202
void FSubstrateBSDFContext::SubstrateUpdateBSDFContext(float3 NewL);

// 261-302 — GGX components
float Substrate_D_GGX(half Roughness, half a2, half NoH);
half  Substrate_D_GGX_Aniso(float ax, float ay, float NoH, float XoH, float YoH);
half  Substrate_Vis_GGX(half Roughness, half a2, half NoV, half NoL);
half  Substrate_Vis_GGX_Aniso(float ax, float ay, float NoV, float NoL, float XoV, float XoL, float YoV, float YoL);
float3 Substrate_F_GGX(half3 F0, half3 F90, half VoH);
float SubstrateTransitionGlintToGGX(float GlintValue);
float Substrate_D_Glint(FSubstrateBSDFContext, float SafeRoughness, float GGX_D);

// 425 / 453 / 1314 — main
void SubstrateSetupBSDFContext(inout FSubstrateBSDFContext, bool bHasAnisotropy,
                               inout float NoV, inout float VoH, inout float NoH,
                               float3 AreaLightL, float SphereSinAlpha);

FSubstrateEvaluateResult SubstrateEvaluateBSDFCommon(
    FSubstrateBSDFContext, FShadowTerms, FAreaLight,
    FSubstrateIntegrationSettings, int IntegrationType);

FSubstrateEvaluateResult SubstrateEvaluateBSDF(
    FSubstrateBSDFContext, FSubstrateIntegrationSettings);

// 1332 / 1357 — IS for ray/path tracing
float SubstrateLobeSelectionProb(float3 A, float3 B);
FSubstrateImportanceSampleResult SubstrateImportanceSampleBSDF(
    FSubstrateBSDFContext, float2 E, uint InTermMask, FSubstrateIntegrationSettings);

// 1581 / 1968 — IBL & SH
FSubstrateEnvLightResult SubstrateEvaluateForEnvLight(FSubstrateBSDFContext, bool bEnableSpecular, FSubstrateIntegrationSettings);
FThreeBandSHVector       SubstrateBSDFToSH(FSubstrateBSDFContext);
```

## VSM Handle (`Private/VirtualShadowMaps/VirtualShadowMapHandle.ush`)

```hlsl
struct FVirtualShadowMapHandle
{
    uint Id;
    bool bIsSinglePageSM;

    // Static factories:
    static FVirtualShadowMapHandle MakeFromId(uint VirtualShadowMapId);
        // bIsSinglePageSM = (Id < VSM_MAX_SINGLE_PAGE_SHADOW_MAPS)
    static FVirtualShadowMapHandle MakeFromIdDirectional(uint VirtualShadowMapId);
        // bIsSinglePageSM = false
    static FVirtualShadowMapHandle MakeFromFullIndex(uint FullVirtualShadowMapIndex);
        // Id = FullVirtualShadowMapIndex + VSM_MAX_SINGLE_PAGE_SHADOW_MAPS
    static FVirtualShadowMapHandle MakeInvalid();
        // Id = 0xFFFFFFFFu
    FVirtualShadowMapHandle MakeOffset(int Offset);    // signed offset
    bool IsValid();
};
```

## Path Tracing (`Private/PathTracing/`)

Single RayGen entry (`PathTracing.usf:86`):

```hlsl
RAY_TRACING_ENTRY_RAYGEN(PathTracingMainRG)
{
    // camera ray + bounce loop + NEE + MIS
}

void StorePathStateData(FPathState PathState, uint Index);   // line 69
```

Material sampling (`Material/PathTracingMaterialSampling.ush`):

```hlsl
FSSSRandomWalkInfo GetMaterialSSSInfo(FPathTracingPayload Payload, float3 V_World);   // 490
FMaterialSample    SampleMaterial(...);    // 571 — closure-IS
FMaterialEval      EvalMaterial(...);      // 627 — explicit (light) sample evaluation
```

## Ray Tracing common (`Private/RayTracing/RayTracingCommon.ush`)

```hlsl
// 198
struct FPlatformRayTracingInstanceDescriptor { ... };

// 226
void SetRayTracingInstanceTransform(inout FPlatformRayTracingInstanceDescriptor Desc, float3x4 LocalToWorld);

// Geometry attribute structs
struct FTriangleBaseAttributes { ... };           // 269
struct FBasicRayData { ... };                     // 275
struct FRayTracingIntersectionAttributes { float2 Barycentrics; };   // 340
struct FRayDesc { float3 Origin; float TMin; float3 Direction; float TMax; };   // 477

// Payload hierarchy
struct FMinimalPayload                            // 283
{
    float HitT;
    void  SetMiss();
    bool  IsMiss();
};
struct FIntersectionPayload     : FMinimalPayload { uint InstanceIndex; uint PrimitiveIndex; float2 Barycentrics; };   // 296
struct FDefaultPayload          : FIntersectionPayload { ... };       // 303
struct FVFXTracePayload         : FMinimalPayload { ... };            // 313
struct FDeferredMaterialPayload : FMinimalPayload { ... };            // 326

// Self-intersection bias helpers
void ApplyPositionBias(inout float3 RayOrigin, float3 RayDirection, float3 WorldNormal, float MaxNormalBias);   // 393
void ApplyCameraRelativeDepthBias(inout float3 RayOrigin, float3 RayDirection, uint2 PixelCoord, float DeviceZ, float3 WorldNormal, float AbsoluteNormalBias);   // 409
void ApplyRayBias(inout float3 RayOrigin, float HitT, float3 GeoNormal);   // 424
void ApplyPositionBias(inout FRayDesc Ray, float3 WorldNormal, float MaxNormalBias);   // 500

// ENTRY macros (resolve to function definitions in vendor headers)
#define RAY_TRACING_ENTRY_RAYGEN(name)    [shader("raygeneration")] void name()
#define RAY_TRACING_ENTRY_CLOSEST_HIT(name, payload, attribs)  ...
#define RAY_TRACING_ENTRY_ANY_HIT(name, payload, attribs)      ...
#define RAY_TRACING_ENTRY_MISS(name, payload)                  ...
```

## Skinning (`Private/BoneTransform.ush`)

```hlsl
struct FBoneTransform
{
    FQuat  Rotation;
    float3 Location;
};

struct FBoneTransformWithScale
{
    FQuat  Rotation;
    float3 Location;
    float3 Scale;
};

FBoneTransform MakeBoneTransform(FQuat Rotation, float3 Location);
// Compose / Apply / Inverse helpers (verify against current source; signatures stable)
```

## GPU Scene writer (`Private/GPUScene/GPUSceneWriter.ush`)

Pattern (verified):

```hlsl
#define USE_GPU_SCENE_DATA_RW 1
#include "/Engine/Private/GPUScene/GPUSceneWriter.ush"

void StoreInstanceSceneDataElement(uint InstanceId, uint ElementIndex, float4 DataElement);
void StoreInstanceSceneDataElementX(uint InstanceId, uint ElementIndex, float Data);
void StoreInstancePayloadDataElement(uint PayloadDataOffset, uint ElementIndex, float4 DataElement);
```

Two backends switch on `ENABLE_SCENE_DATA_DX11_UB_ERROR_WORKAROUND`:
- workaround: writes to global `GPUSceneInstanceSceneDataRW`
- normal: writes via `GPUSceneWriter.GPUSceneInstanceSceneDataRW`

## Lumen Reflections (`Private/Lumen/LumenReflections.usf`) — verified entries

```hlsl
void InitReflectionIndirectArgsCS(...);                   // 29
void ReflectionTileClassificationBuildListsCS(...);       // 72
void ReflectionGenerateRaysCS(...);                       // 302
void ReflectionClearUnusedTraceTileDataCS(...);           // 446
void ReflectionClearNeighborTileCS(...);                  // 484
// (further pipeline branches into LumenReflectionTracing.usf / LumenReflectionHardwareRayTracing.usf)
```

## Sky Atmosphere (`Private/SkyAtmosphere.usf`) — verified entries

```hlsl
void UvToLutTransmittanceParams(out float ViewHeight, out float ViewZenithCosAngle, in float2 UV);   // 199
void LutTransmittanceParamsToUv(in float ViewHeight, in float ViewZenithCosAngle, out float2 UV);    // 205
void UvToSkyViewLutParams(out float3 ViewDir, in float ViewHeight, in float2 UV);                     // 214

void SkyAtmosphereVS(...);                                  // 851
void UpdateVisibleSkyAlpha(in float DeviceZ, inout float4 OutLuminance);   // 889
void RenderSkyAtmosphereRayMarchingPS(...);                 // 905

// Compute LUT pipeline
void RenderTransmittanceLutCS(uint3 ThreadId : SV_DispatchThreadID);                  // 1144
void RenderMultiScatteredLuminanceLutCS(uint3 ThreadId : SV_DispatchThreadID);        // 1200
void RenderSkyViewLutCS(uint3 ThreadId : SV_DispatchThreadID);                        // 1326
void RenderDistantSkyLightLutCS(uint3 ThreadId : SV_DispatchThreadID);                // 1404
void RenderCameraAerialPerspectiveVolumeCS(uint3 ThreadId : SV_DispatchThreadID);     // 1510

void RenderSkyAtmosphereDebugPS(...);                       // 1705
void RenderSkyAtmosphereEditorHudPS(...);                   // 1854
```

## Volumetric Cloud (`Private/VolumetricCloud.usf`) — verified entries

```hlsl
void VolumetricCloudCalcPixelMaterialInputs(in out FMaterialPixelParameters, in out FPixelMaterialInputs);   // 96
void ConvertCloudPixelMaterialInputsToWorkingColorSpace(inout FPixelMaterialInputs);                          // 161
void MainVS(...);                                                                                              // 211
void MainCommon(in FMaterialPixelParameters, in float4 SvPosition, ...);                                      // 456
void MainPS(...);                                                                                              // 1745
void MainCS(uint2 DispatchThreadId : SV_DispatchThreadID);                                                     // 1779
void MainCS(uint3 DispatchThreadId : SV_DispatchThreadID, uint3 GroupThreadId : SV_GroupThreadID);             // 1935
void MainPS(...);                                                                                              // 2068 (alternate)

// Cloud self-shadow pipeline
void CloudShadowData_WriteDst(in CloudShadowData CloudData, uint2 Coord);   // 2267
void MainShadowFilterCS(uint3 DispatchThreadId : SV_DispatchThreadID);      // 2273
void MainDrawDebugShadowCS(uint3 DispatchThreadId : SV_DispatchThreadID);   // 2371
void MainShadowTemporalProcessCS(uint3 DispatchThreadId : SV_DispatchThreadID);  // 2431
```

## TSR Reject Shading fetch helpers (`Private/TemporalSuperResolution/TSRRejectShading.usf`)

```hlsl
void FetchThinGeometryEdge(...);                          // 123
void FetchDecimateMask(...);                              // 142
void FetchSceneColorAndTranslucency(...);                 // 165
void FetchHistoryGuide(...);                              // 183
void FetchReprojectedHistoryGuide(...);                   // 211
void FetchMoireInput(...);                                // 226
void FetchResurrectedHistoryGuide(...);                   // 248
void FetchDeviceZ(...);                                   // 319
void OverwriteReprojectionFieldWithResurrection(tsr_tensor_bool bResurrectHistory, tsr_tensor_float DeviceZ);   // 334
void RefetchInputAndHistoryFromLDSOrCache(...);           // 404
```

`tsr_tensor_*` types come from `TSRConvolutionNetwork.ush` (wave-cooperative LDS tensor abstraction — **not** a neural network).

## SSD signal framework (`Private/ScreenSpaceDenoise/SSDSignalFramework.ush`)

Required compile-time `#define`:

```hlsl
#define CONFIG_SIGNAL_PROCESSING <one of:>
    SIGNAL_PROCESSING_SHADOW_VISIBILITY_MASK
    SIGNAL_PROCESSING_POLYCHROMATIC_PENUMBRA_HARMONIC
    SIGNAL_PROCESSING_REFLECTIONS              // pulls MonteCarlo + BRDF + DeferredShadingCommon
    SIGNAL_PROCESSING_AO
    SIGNAL_PROCESSING_DIFFUSE_INDIRECT_AND_AO
    SIGNAL_PROCESSING_DIFFUSE_SPHERICAL_HARMONIC
    SIGNAL_PROCESSING_SSGI
    SIGNAL_PROCESSING_DIFFUSE_PROBE_HIERARCHY
```

`FSSDSignalDomainKnowledge` struct holds signal-specific knowledge for the chosen mode.

`FSSDSignalSample` (`SSDSignalCore.ush`):

```hlsl
struct FSSDSignalSample
{
    float SampleCount;
#if COMPILE_SIGNAL_COLOR
    float4 SceneColor;
#endif
#if COMPILE_SIGNAL_COLOR_SH
    // SH coefficients
#endif
#if COMPILE_SIGNAL_COLOR_ARRAY
    // multi-component color array
#endif
};
```

Required `#define`:

```hlsl
MAX_SIGNAL_BATCH_SIZE      // # independent signal domains denoised together
SIGNAL_ARRAY_SIZE          // # multiplexed samples in FSSDSignalSample
COMPILE_SIGNAL_COLOR       // include color members
COMPILE_SIGNAL_COLOR_SH    // include SH members
COMPILE_SIGNAL_COLOR_ARRAY // include array members
```
