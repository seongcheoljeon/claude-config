# UnrealEngine 렌더링 파이프라인 레퍼런스 (Lumen / Nanite / RT / VSM)

> UE5 메인 라인 소스 기준. 핵심 cvar만 선별 (전체 약 705개 중 약 180개 카탈로그).
>
> 전체 cvar 카운트 (Renderer/Private 폴더 기준 unique 이름):
> - Lumen: **383개**
> - Nanite: **96개**
> - Ray Tracing: **125개**
> - Virtual Shadow Map: **101개**
>
> 본 문서는 디버깅/시각화/토글/품질 트레이드오프 cvar 위주로 정리.

---

## Part 1: 시스템 ON/OFF 빠른 토글

### Lumen 끄기/켜기

Lumen은 단일 토글이 아니라 **GI 메서드 + Reflection 메서드** 두 축을 모두 Lumen으로 설정해야 활성화됩니다.

```ini
; 끄기 (Legacy/SSGI/SSR로 전환)
r.DynamicGlobalIlluminationMethod=0   ; 0=None, 1=Lumen, 2=SSGI, 3=Plugin
r.ReflectionMethod=0                  ; 0=None, 1=Lumen, 2=SSR

; 켜기
r.DynamicGlobalIlluminationMethod=1
r.ReflectionMethod=1

; 세부 토글
r.Lumen.DiffuseIndirect.Allow=1       ; GI 자체 차단 (디버그용 강제 OFF)
r.Lumen.Reflections.Allow=1           ; Reflection 차단
r.Lumen.TranslucencyVolume.Enable=1   ; Translucency Volume GI
r.Lumen.AsyncCompute=1                ; Async Compute로 분산
```

### Nanite 끄기/켜기

```ini
r.Nanite=1                            ; 마스터 토글 (엔진 전역)
r.Nanite.ProgrammableRaster=1         ; WPO/Masked/PDO 지원
r.Nanite.AsyncRasterization=1         ; 라스터를 Async Compute로
r.Nanite.MeshShaderRasterization=1    ; Mesh Shader 경로
r.Nanite.PrimShaderRasterization=1    ; Primitive Shader 경로 (콘솔)
r.Nanite.ComputeRasterization=1       ; Compute Rasterizer
```

### Ray Tracing 끄기/켜기

```ini
r.RayTracing=1                        ; 마스터 (Engine, 셰이더 컴파일 영향)
r.RayTracing.Enable=1                 ; 런타임 토글 (BLAS/TLAS 빌드)
r.RayTracing.EnableMaterials=1        ; Closest Hit Shader 활성화
r.RayTracing.AutoInstance=1
```

### Virtual Shadow Map 끄기/켜기

```ini
r.Shadow.Virtual.Enable=1             ; 마스터 (0이면 SM5 그림자로 폴백)
r.Shadow.Virtual.Cache=1              ; 캐시 사용 (성능 핵심)
r.Shadow.Virtual.MarkPixelPages=1     ; 화면에서 페이지 마킹
```

---

## Part 2: Lumen 핵심 cvar

### 활성화/방법 선택

```ini
r.Lumen.DiffuseIndirect.Allow              ; Lumen GI 자체 차단
r.Lumen.Reflections.Allow                  ; Reflection 차단
r.Lumen.TranslucencyVolume.Enable
r.Lumen.HardwareRayTracing                 ; 0=Software, 1=Hardware RT
r.Lumen.HardwareRayTracing.Inline          ; Inline RT (RayQuery)
r.Lumen.HardwareRayTracing.LightingMode    ; 0=Surface Cache, 1=Hit Lighting (고품질)
r.Lumen.AllowHWRTForAllViewsIfAnyViewHasLumenGI
r.Lumen.IrradianceFieldGather              ; ScreenProbe 대신 Irradiance Field
r.Lumen.AsyncCompute
```

### Quality Settings

```ini
r.Lumen.DiffuseIndirect.MinSampleRadius
r.Lumen.DiffuseIndirect.MinTraceDistance
r.Lumen.DiffuseIndirect.SurfaceBias
r.Lumen.DiffuseIndirect.TraceStepFactor
r.Lumen.ScreenProbeGather.DownsampleFactor          ; 16=낮음, 8=높음
r.Lumen.ScreenProbeGather.AdaptiveProbeAllocationFraction
r.Lumen.ScreenProbeGather.GatherOctahedronResolutionScale
r.Lumen.ScreenProbeGather.ImportanceSample
```

### Surface Cache

```ini
r.Lumen.SurfaceCache.HeightfieldCaptureMargin
r.LumenScene.DirectLighting                 ; Surface Cache 직접 조명
r.LumenScene.DirectLighting.HardwareRayTracing
r.LumenScene.DirectLighting.UpdateFactor
r.LumenScene.DirectLighting.Stochastic      ; 다수 라이트 확률적 샘플링
r.LumenScene.DirectLighting.MaxLightsPerTile
r.LumenScene.DirectLighting.CloudTransmittance
r.LumenScene.GPUDrivenUpdate
r.LumenScene.FastCameraMode                 ; 빠른 카메라 이동 시 갱신 가속
r.LumenScene.GlobalSDF.Resolution
r.LumenScene.GlobalSDF.ClipmapExtent
r.LumenScene.FarField                       ; Far Field 라이팅 (대형 씬)
r.LumenScene.FarField.MaxTraceDistance
r.LumenScene.DumpStats                      ; 디버그용 통계 덤프
```

### Reflections

```ini
r.Lumen.Reflections.Allow
r.Lumen.Reflections.AsyncCompute
r.Lumen.Reflections.HardwareRayTracing
r.Lumen.Reflections.HardwareRayTracing.HitLighting   ; 고품질 (느림)
r.Lumen.Reflections.HardwareRayTracing.FarField
r.Lumen.Reflections.MaxRoughnessToTrace               ; 거칠기 컷오프
r.Lumen.Reflections.MaxRayIntensity                   ; 파이어플라이 클램프
r.Lumen.Reflections.DownsampleFactor                  ; 1/2/4
r.Lumen.Reflections.DownsampleCheckerboard
r.Lumen.Reflections.BilateralFilter
r.Lumen.Reflections.BilateralFilter.KernelRadius
r.Lumen.Reflections.GGXSamplingBias
r.Lumen.Reflections.Contrast
r.Lumen.Reflections.DistantScreenTraces
r.Lumen.Reflections.HiResSurface
r.Lumen.Reflections.Debug
```

### Visualization (`r.Lumen.Visualize.*`)

```ini
r.Lumen.Visualize                          ; 시각화 모드 (1~N)
r.Lumen.Visualize.HardwareRayTracing
r.Lumen.Visualize.HardwareRayTracing.HitLighting
r.Lumen.Visualize.HardwareRayTracing.FarField
r.Lumen.Visualize.HiResSurface             ; 1=High Res, 0=Low Res Card
r.Lumen.Visualize.IndirectDiffuse
r.Lumen.Visualize.TraceMeshSDFs
r.Lumen.Visualize.TraceRadianceCache
r.Lumen.Visualize.SurfaceCacheFeedback
r.Lumen.Visualize.CardPlacement            ; 카드 배치 시각화
r.Lumen.Visualize.CardPlacementDistance
r.Lumen.Visualize.CardPlacementLOD
r.Lumen.Visualize.RayTracingGroups
r.Lumen.Visualize.GridPixelSize
r.Lumen.Visualize.MaxTraceDistance
r.Lumen.Visualize.ConeAngle
r.Lumen.Visualize.UseShaderPrintForTraces  ; ShaderPrint 디버그
r.LumenScene.DirectLighting.Stochastic.Debug
r.Lumen.Reflections.Debug
r.Lumen.ScreenProbeGather.Debug
r.Lumen.ScreenProbeGather.Debug.ProbePlacement
```

### Hardware Ray Tracing 모드

```ini
r.Lumen.HardwareRayTracing.LightingMode         ; 0=SurfaceCache, 1=HitLighting
r.Lumen.HardwareRayTracing.Inline
r.Lumen.HardwareRayTracing.ShaderExecutionReordering   ; SER (Ada GPU)
r.Lumen.HardwareRayTracing.MaxIterations
r.Lumen.HardwareRayTracing.PullbackBias
r.Lumen.HardwareRayTracing.AvoidSelfIntersections
r.Lumen.HardwareRayTracing.HitLighting.DirectLighting
r.Lumen.HardwareRayTracing.HitLighting.Skylight
r.Lumen.HardwareRayTracing.HitLighting.ReflectionCaptures
r.Lumen.HardwareRayTracing.HitLighting.ShadowMode
r.Lumen.HardwareRayTracing.SurfaceCacheAlphaMasking
r.Lumen.HardwareRayTracing.SurfaceCacheSampling.DepthBias
r.Lumen.HardwareRayTracing.MeshSectionVisibilityTest
r.Lumen.HardwareRayTracing.FarFieldBias
```

### Software Ray Tracing 모드

```ini
r.Lumen.DiffuseIndirect.MeshSDF.RadiusThreshold
r.Lumen.DiffuseIndirect.MeshSDF.AverageCulledCount
r.Lumen.DiffuseIndirect.MeshSDF.NotCoveredExpandSurfaceScale
r.Lumen.DiffuseIndirect.MeshSDF.NotCoveredMinStepScale
r.Lumen.DiffuseIndirect.MeshSDF.DitheredTransparencyStepThreshold
r.Lumen.DiffuseIndirect.CullGridPixelSize
r.Lumen.DiffuseIndirect.CardTraceEndDistanceFromCamera
r.LumenScene.GlobalSDF.Resolution
r.LumenScene.GlobalSDF.ClipmapExtent
```

---

## Part 3: Nanite 핵심 cvar

### 활성화/방법 선택

```ini
r.Nanite                                  ; 마스터 토글
r.Nanite.ProgrammableRaster               ; WPO/Masked/PDO 머티리얼 지원
r.Nanite.AsyncRasterization               ; Async Compute 라스터
r.Nanite.AsyncRasterization.ShadowDepths
r.Nanite.AsyncRasterization.LumenMeshCards
r.Nanite.AsyncRasterization.CustomPass
r.Nanite.MeshShaderRasterization
r.Nanite.PrimShaderRasterization
r.Nanite.ComputeRasterization
r.Nanite.Tessellation                     ; Displacement 테셀레이션
```

### Visualization (`r.Nanite.Visualize.*`)

```ini
r.Nanite.Visualize                        ; (NaniteVisualization.cpp 정의)
r.Nanite.Visualize.Composite              ; 비-Nanite 메시와 합성
r.Nanite.Visualize.EdgeDetect
r.Nanite.Visualize.OverdrawScale
r.Nanite.Visualize.ComplexityScale
r.Nanite.Visualize.ComplexityOverhead
r.Nanite.Visualize.DebugShading
r.Nanite.Visualize.PixelProgrammableVisMode
r.Nanite.ShowStats                         ; HUD 통계
r.Nanite.StatsFilter
r.Nanite.Picking.Domain
r.Nanite.Debug.ValidateShadeBinning
r.Nanite.EmitMaterialPerformanceWarnings
r.Nanite.FastTileVis
```

### Streaming

```ini
r.Nanite.MaxCandidateClusters
r.Nanite.MaxCandidatePatches
r.Nanite.MaxNodes
r.Nanite.MaxVisibleClusters
r.Nanite.MaxVisiblePatches
r.Nanite.StreamOut.CacheTraversalData
```

### Programmable Raster

```ini
r.Nanite.ProgrammableRaster
r.Nanite.AllowProgrammableDistances
r.Nanite.MaxPixelsPerEdge                 ; LOD 픽셀 임계
r.Nanite.MinPixelsPerEdgeHW
r.Nanite.PrimaryRaster.PixelsPerEdgeScaling
r.Nanite.PrimaryRaster.TimeBudgetMs       ; 동적 해상도 예산
r.Nanite.ShadowRaster.PixelsPerEdgeScaling
r.Nanite.ShadowRaster.TimeBudgetMs
r.Nanite.DicingRate
r.Nanite.RasterIndirectionMultiplier
r.Nanite.RasterSort
r.Nanite.RasterSetupCache
r.Nanite.SoftwareVRS
```

### Shading

```ini
r.Nanite.ComputeMaterials.Sort
r.Nanite.ShadeBinningMode
r.Nanite.MaterialVisibility
r.Nanite.MaterialVisibility.Async
r.Nanite.MaterialVisibility.Primitives
r.Nanite.MaterialVisibility.Instances
r.Nanite.MaterialVisibility.RasterBins
r.Nanite.MaterialVisibility.ShadingBins
r.Nanite.DepthBucketing
r.Nanite.DepthBucketPixelProgrammable
r.Nanite.CustomDepth.ExportMethod
r.Nanite.ExportDepth
r.Nanite.ParallelBasePassBuild
```

### Culling

```ini
r.Nanite.Culling.Frustum
r.Nanite.Culling.HZB
r.Nanite.Culling.TwoPass
r.Nanite.Culling.DrawDistance
r.Nanite.Culling.GlobalClipPlane
r.Nanite.Culling.MinLOD
r.Nanite.Culling.WPODisableDistance       ; 거리별 WPO 비활성
r.Nanite.PersistentThreadsCulling
r.Nanite.LargePageRectThreshold
```

---

## Part 4: Ray Tracing 핵심 cvar

### Master Toggle

```ini
r.RayTracing                              ; 엔진 마스터 (셰이더 컴파일)
r.RayTracing.Enable                       ; 런타임 토글
r.RayTracing.EnableMaterials              ; CHS/AHS 활성
r.RayTracing.AutoInstance
r.RayTracing.NormalBias
r.RayTracing.NonBlockingPipelineCreation
```

### Per-Effect: Shadows

```ini
r.RayTracing.Shadows                      ; 0/1 (별도 위치 정의)
r.RayTracing.Shadows.AcceptFirstHit
r.RayTracing.Shadows.EnableMaterials
r.RayTracing.Shadows.EnableTwoSidedGeometry
r.RayTracing.Shadows.EnableHairVoxel
r.RayTracing.Shadows.LODTransitionStart
r.RayTracing.Shadows.LODTransitionEnd
r.RayTracing.Shadows.MaxTranslucencyHitCount
r.RayTracing.Shadows.Translucency
r.RayTracing.Shadows.AvoidSelfIntersectionTraceDistance
```

### Per-Effect: Reflections (Standalone, Lumen 외)

```ini
r.RayTracing.Reflections                  ; 별도 정의 (RayTracingReflections.cpp)
r.RayTracing.Reflections.SamplesPerPixel
r.RayTracing.Reflections.MaxRoughness
r.RayTracing.Reflections.MaxBounces
r.RayTracing.Reflections.Shadows
r.RayTracing.Reflections.Translucency
```

### Per-Effect: AO

```ini
r.RayTracing.AmbientOcclusion
r.RayTracing.AmbientOcclusion.SamplesPerPixel
r.RayTracing.AmbientOcclusion.EnableMaterials
r.RayTracing.AmbientOcclusion.EnableTwoSidedGeometry
```

### Per-Effect: GI / SkyLight

```ini
r.RayTracing.SkyLight
r.RayTracing.SkyLight.Denoiser
r.RayTracing.SkyLight.MaxRayDistance
r.RayTracing.SkyLight.SamplesPerPixel
r.RayTracing.SkyLight.EnableMaterials
r.RayTracing.SkyLight.EnableTwoSidedGeometry
r.RayTracing.SkyLight.HairVoxel
r.RayTracing.SkyLight.DecoupleSampleGeneration
```

### Per-Effect: Translucency

```ini
r.RayTracing.Translucency
r.RayTracing.Translucency.SamplesPerPixel
r.RayTracing.Translucency.MaxRoughness
r.RayTracing.Translucency.MaxRefractionRays
r.RayTracing.Translucency.Refraction
r.RayTracing.Translucency.Shadows
r.RayTracing.Translucency.ShadowsTranslucencyType
r.RayTracing.Translucency.MinRayDistance
r.RayTracing.Translucency.MaxRayDistance
r.RayTracing.Translucency.PrimaryRayBias
```

### Performance Tuning

```ini
r.RayTracing.Culling                      ; 0=off, 1+=culling 모드
r.RayTracing.Culling.Radius
r.RayTracing.Culling.Angle
r.RayTracing.Culling.PerInstance
r.RayTracing.Culling.UseGroupIds
r.RayTracing.Culling.UseMinDrawDistance
r.RayTracing.ExcludeDecals
r.RayTracing.ExcludeSky
r.RayTracing.ExcludeTranslucent
r.RayTracing.Geometry.StaticMeshes
r.RayTracing.Geometry.SkeletalMeshes
r.RayTracing.Geometry.InstancedSkeletalMeshes
r.RayTracing.Geometry.HierarchicalInstancedStaticMesh
r.RayTracing.Geometry.LandscapeGrass
r.RayTracing.Geometry.NaniteProxies        ; Nanite를 RT 프록시로
r.RayTracing.Scene.BuildMode
r.RayTracing.Scene.BatchedBuild
r.RayTracing.Scene.CompactInstances
r.RayTracing.DynamicGeometry.MaxUpdatePrimitivesPerFrame
r.RayTracing.DynamicGeometry.SharedVertexBufferSizeInMB
r.RayTracing.InstanceBuffer.ParallelFill
r.RayTracing.InstanceBuffer.RLE
r.RayTracing.PersistentSBT                 ; SBT 캐싱
r.RayTracing.LightGridResolution
r.RayTracing.LightGridMaxCount
r.RayTracing.DecalGrid.Resolution
```

### Visualization / Debug

```ini
r.RayTracing.DebugDisableTriangleCull
r.RayTracing.DebugForceOpaque
r.RayTracing.DebugTimingScale
r.RayTracing.DebugTraversalScale.Box
r.RayTracing.DebugTraversalScale.Cluster
r.RayTracing.DebugTraversalScale.Triangle
r.RayTracing.DebugTriangleHitCount.MaxThreshold
r.RayTracing.DebugTriangleHitCount.TopKMostHits
r.RayTracing.DebugVisualizationMode.OpaqueOnly
r.RayTracing.DebugVisualizationMode.ProceduralPrimitives
r.RayTracing.Debug.PickerDomain
r.RayTracing.Debug.InstanceOverlap.Scale
r.RayTracing.Debug.InstanceOverlap.ShowWireframe
```

---

## Part 5: Virtual Shadow Map 핵심 cvar

### 활성화 상태

```ini
r.Shadow.Virtual.Enable                    ; 마스터
r.Shadow.Virtual.MarkPixelPages
r.Shadow.Virtual.MarkPixelPagesMipModeLocal
r.Shadow.Virtual.MaxPhysicalPages          ; 페이지 풀 크기
r.Shadow.Virtual.AllocatePagePoolAsReservedResource
r.Shadow.Virtual.TranslucentQuality
r.Shadow.Virtual.CullBackfacingPixels
```

### Page Pool / Cache

```ini
r.Shadow.Virtual.Cache                     ; 캐시 마스터
r.Shadow.Virtual.Cache.AllocateViaLRU
r.Shadow.Virtual.Cache.CPUCullInvalidationsOutsideLightRadius
r.Shadow.Virtual.Cache.DeformableMeshesInvalidate
r.Shadow.Virtual.Cache.ForceInvalidateDirectional
r.Shadow.Virtual.Cache.FramesStaticThreshold
r.Shadow.Virtual.Cache.InvalidateUseHZB
r.Shadow.Virtual.Cache.MaxLightAgeSinceLastRequest
r.Shadow.Virtual.Cache.MaxPageAgeSinceLastRequest
r.Shadow.Virtual.CoarsePagePixelThresholdDynamic
r.Shadow.Virtual.CoarsePagePixelThresholdDynamicNanite
r.Shadow.Virtual.CoarsePagePixelThresholdStatic
```

### Resolution / Bias

```ini
r.Shadow.Virtual.ResolutionLodBiasDirectional
r.Shadow.Virtual.ResolutionLodBiasDirectionalMoving
r.Shadow.Virtual.ResolutionLodBiasLocal
r.Shadow.Virtual.Clipmap.FirstLevel
r.Shadow.Virtual.Clipmap.LastLevel
r.Shadow.Virtual.Clipmap.FirstCoarseLevel
r.Shadow.Virtual.Clipmap.LastCoarseLevel
r.Shadow.Virtual.Clipmap.MinCameraViewportWidth
r.Shadow.Virtual.Clipmap.WPODisableDistance
r.Shadow.Virtual.Clipmap.WPODisableDistance.LodBias
r.Shadow.Virtual.Clipmap.WPODisableDistance.InvalidateOnScaleChange
r.Shadow.Virtual.Clipmap.ZRangeScale
r.Shadow.Virtual.Clipmap.CullDynamicTightly
```

### Visualization

```ini
r.Shadow.Virtual.Visualize.Layout          ; 페이지 레이아웃 시각화
r.Shadow.Virtual.Visualize.LightName       ; 특정 라이트 필터
r.Shadow.Virtual.Visualize.ShowCachedPagesOnly
r.Shadow.Virtual.Visualize.DumpLightNames
r.Shadow.Virtual.VisualizeDynamicMeshBounds
r.Shadow.Virtual.DebugDrawFroxels
r.Shadow.Virtual.DebugDrawFroxelRange
```

### Debug

```ini
r.Shadow.Virtual.AccumulateStats
r.Shadow.Virtual.AllowScreenOverflowMessages
r.Shadow.Virtual.Cache.DebugSkipDynamicPageInvalidation
r.Shadow.Virtual.Cache.DebugSkipRevealedPrimitivesInvalidation
r.Shadow.Virtual.DebugSkipMergePhysical
```

---

## Part 6: 시각화 명령 (`Show*` / ShowFlag)

```ini
; ShowFlag 콘솔 명령 형태: ShowFlag.<이름> 0/1
ShowFlag.Lumen 1                          ; (그룹 SFG_Lumen 하위)
ShowFlag.LumenGlobalIllumination 1
ShowFlag.LumenReflections 1
ShowFlag.LumenScreenTraces 1
ShowFlag.LumenDetailTraces 1
ShowFlag.LumenGlobalTraces 1
ShowFlag.LumenFarFieldTraces 1
ShowFlag.LumenSecondaryBounces 1
ShowFlag.LumenShortRangeAmbientOcclusion 1
ShowFlag.VisualizeLumen 1                 ; 시각화 토글

ShowFlag.NaniteMeshes 1
ShowFlag.NaniteStreamingGeometry 1
ShowFlag.VisualizeNanite 1

ShowFlag.VisualizeVirtualShadowMap 1
ShowFlag.VirtualShadowMapPersistentData 1

ShowFlag.GlobalIllumination 1             ; 전역 GI 마스터
ShowFlag.ReflectionEnvironment 1
ShowFlag.ScreenSpaceReflections 1
ShowFlag.RayTracedDistanceFieldShadows 1
ShowFlag.RayTracingDebug 1
ShowFlag.ReflectionOverride 0             ; 디버그 (Mirror)
ShowFlag.VisualizeSSR 1
```

대표적인 `Vis ` / `r.PostProcessing` 콘솔:

```text
Vis SceneColor                            ; 일반 시각화
Vis LumenScene
Vis LumenGlobalDistanceField
Vis LumenSurfaceCache
ProfileGPU                                ; GPU 프로파일링 (Lumen/Nanite/VSM 패스 분리 표시)
```

---

## Part 7: 4개 시스템 간 상호작용

### 의존 관계

| 시스템 | 의존 | 비고 |
|---|---|---|
| **Lumen HW RT** | `r.RayTracing=1` 필요 | `r.Lumen.HardwareRayTracing=1`이라도 RT가 꺼져 있으면 Software 폴백 |
| **Lumen Reflections HW RT** | `r.RayTracing=1` + `r.Lumen.HardwareRayTracing=1` | HitLighting 모드는 추가로 머티리얼 컴파일 필요 |
| **Nanite VSM 그림자** | `r.Shadow.Virtual.Enable=1` + `r.Nanite=1` | Nanite는 VSM과 상호 가속 (페이지 단위 라스터) |
| **VSM Cache 무효화** | Nanite WPO 변경 시 자동 invalidate | `r.Nanite.VSMInvalidateOnLODDelta` 참조 |
| **Lumen Surface Cache + Nanite** | `r.Nanite.AsyncRasterization.LumenMeshCards=1` | Lumen 카드 캡처를 Nanite Async로 |
| **DistanceField → Lumen SW RT** | `r.GenerateMeshDistanceFields=1` 필수 | SW RT 모드는 Mesh SDF + Global SDF 필요 |
| **VSM ↔ Distance Field Shadow** | VSM 활성 시 DFShadow 자동 비활성 | `ShowFlag.RayTracedDistanceFieldShadows`는 VSM 외 라이트에만 작용 |

### 셰이더 작업자가 알아야 할 충돌

1. **`r.Lumen.HardwareRayTracing=1`인데 `r.RayTracing=0`**
   - 자동으로 Software RT로 폴백 → Mesh SDF 필요. 마테리얼이 SDF 없으면 누락됨
2. **`r.Nanite.ProgrammableRaster=0`**
   - Nanite 메시의 WPO/Pixel Depth Offset/Masked 머티리얼이 모두 무시됨
   - Wind 머티리얼의 WPO가 `r.Nanite.Culling.WPODisableDistance` 거리 이상에서 비활성
3. **VSM + 동적 메시**
   - `r.Shadow.Virtual.Cache.DeformableMeshesInvalidate=1`이면 매 프레임 캐시 무효화 → 성능 저하
   - 스켈레탈 메시 위주 씬에서는 0 권장
4. **Lumen HitLighting + Nanite**
   - `r.Lumen.HardwareRayTracing.LightingMode=1`은 Nanite 머티리얼 ClosestHitShader 컴파일 필요
   - 첫 적용 시 셰이더 컴파일 폭증
5. **SER (Shader Execution Reordering)**
   - `r.Lumen.HardwareRayTracing.ShaderExecutionReordering=1`은 NV Ada 이상에서만 효과

---

## Part 8: 참고 파일 위치

UE 메인 라인 소스 기준 (`/mnt/c/Users/admin/source/repos/UnrealEngine/`):

### Lumen
- [Engine/Source/Runtime/Renderer/Private/Lumen/](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/Lumen/)
- 주요 파일:
  - `LumenSceneRendering.cpp` — Surface Cache 갱신
  - `LumenScreenProbeGather.cpp` — GI 메인
  - `LumenReflections.cpp`
  - `LumenHardwareRayTracing.cpp`
  - `LumenVisualize.cpp`
  - `LumenSceneDirectLighting.cpp`

### Nanite
- [Engine/Source/Runtime/Renderer/Private/Nanite/](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/Nanite/)
- 주요 파일:
  - `NaniteCullRaster.cpp` — Culling/Raster cvar 다수
  - `NaniteShading.cpp`
  - `NaniteVisualization.cpp`
  - `NaniteMaterials.cpp`
  - `NaniteStreamingManager.cpp`

### Ray Tracing
- [Engine/Source/Runtime/Renderer/Private/RayTracing/](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/RayTracing/)
- 주요 파일:
  - `RayTracing.cpp` — 마스터 토글
  - `RayTracingShadows.cpp`
  - `RayTracingReflections.cpp`
  - `RayTracingTranslucency.cpp`
  - `RayTracingSkyLight.cpp`
  - `RayTracingAmbientOcclusion.cpp`
  - `RayTracingDebug.cpp`

### Virtual Shadow Map
- [Engine/Source/Runtime/Renderer/Private/VirtualShadowMaps/](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/VirtualShadowMaps/)
- 주요 파일:
  - `VirtualShadowMapArray.cpp` — 페이지 풀
  - `VirtualShadowMapCacheManager.cpp` — Cache cvar 다수
  - `VirtualShadowMapClipmap.cpp` — Directional 라이트 Clipmap
  - `VirtualShadowMapVisualize.cpp`

### ShowFlag
- [Engine/Source/Runtime/Engine/Public/ShowFlagsValues.inl](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Public/ShowFlagsValues.inl)

### 엔진 전역 (Method Selection)
- [Engine/Source/Runtime/Engine/Private/SystemSettings.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/SystemSettings.cpp)
- `r.DynamicGlobalIlluminationMethod`, `r.ReflectionMethod`는 Engine 모듈에 정의
