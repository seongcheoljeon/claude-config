# UnrealEngine 시각화 / 디버그 뷰 레퍼런스

본 문서는 UE5 (`/mnt/c/Users/admin/source/repos/UnrealEngine`) 소스에서 카탈로그한 시각화/디버그 뷰 명령 모음입니다. 셰이더/머티리얼 작업자가 "지금 화면에 뭘 그리고 있는지" 시각적으로 확인할 때 사용합니다.

---

## Part 1: 시나리오별 명령 추천

### 셰이더 출력 검사 (특정 텍스처/버퍼)
- `vis <RDGResourceName>` — 임의의 RDG 리소스(렌더 타겟, 셰이더 출력) 화면에 띄움
- `vis 0` — 시각화 종료
- `vis pool BYNAME` / `BYSIZE` — 사용 가능한 RDG 리소스 풀 목록 출력
- `r.DumpGPU` — 한 프레임의 모든 RDG 리소스를 디스크에 덤프 (HTML 뷰어로 탐색 가능)

### GBuffer 채널별 보기
- `viewmode VisualizeBuffer` 또는 단축키 `Alt+5` (Editor View 메뉴 → Buffer Visualization)
- 화면 분할 모드: `r.BufferVisualizationOverviewTargets` (콤마 구분 모드 이름)
- 단일 채널: 에디터 메뉴에서 해당 항목 선택 (BaseColor, WorldNormal, Roughness, Metallic, ...)

### 라이팅 디버깅
- `viewmode LightingOnly` — 머티리얼 알베도 제거, 라이팅만
- `viewmode LightComplexity` — 픽셀당 라이트 개수 (오버랩 시각화)
- `viewmode StationaryLightOverlap` — 스태틱 라이트 채널 충돌 검사
- `viewmode ReflectionOverride` — 메탈 100%, Roughness 0 머티리얼로 리플렉션만 검사
- `show DirectLighting` / `show GlobalIllumination` / `show DynamicShadows` 등 ShowFlag 토글
- `viewmode VisualizeShadingModels` — 픽셀별 셰이딩 모델(Default, Subsurface, ClearCoat...) 컬러 표시

### Lumen GI 디버깅
- `viewmode VisualizeLumen` 또는 `show VisualizeLumen` + `r.Lumen.Visualize <mode>`
- `r.Lumen.Visualize 1` (Overview), `2` (PerformanceOverview), `3` (LumenScene), `5` (SurfaceCache), `6` (GeometryNormals)
- `r.Lumen.Visualize.HiResSurface 1` — Card Capture 고해상도 표면
- `r.Lumen.Visualize.CardPlacement 1` — Lumen Card 배치 시각화
- `show LumenScreenTraces`, `show LumenDetailTraces`, `show LumenGlobalTraces` — 트레이스 단계별 토글

### Nanite 메시 분석
- `viewmode VisualizeNanite` 또는 에디터 메뉴 → Nanite Visualization
- 모드: `Overview`, `Triangles`, `Clusters`, `Primitives`, `Instances`, `Overdraw`, `EvaluateWPO`, `Hierarchy`, `RasterMode`, `Tessellation`, `Patches`, `RasterBins`, `ShadingBins`, `LightmapUV`, `PixelProgrammable`, `ShadowCasters`, `Picking`
- `show NaniteMeshes 0` — Nanite 자체를 끄고 폴백 렌더 확인
- `r.Nanite.Visualize.Composite 1` — 시각화 합성

### 셰이더 비용 시각화
- `viewmode ShaderComplexity` — 픽셀 셰이더 명령 수 (녹/노/적)
- `viewmode ShaderComplexityWithQuadOverdraw` — 셰이더 복잡도 + 쿼드 오버드로
- `viewmode QuadOverdraw` — 단일 쿼드(2x2) 내 다중 트라이앵글 충돌
- `viewmode LightmapDensity` / `LitLightmapDensity` — 라이트맵 텍셀 밀도
- `viewmode PrimitiveDistanceAccuracy` / `MeshUVDensityAccuracy` / `MaterialTextureScaleAccuracy` — 텍스처 LOD 적정도

### 메시/지오메트리 분석
- `viewmode Wireframe` / `Lit_Wireframe` (와이어 + 라이트)
- `viewmode LODColoration` / `HLODColoration` / `GroupLODColoration`
- `show Bounds`, `show Bones`, `show Collision`, `show MeshEdges`, `show VertexColors`
- `viewmode VisualizeGPUSkinCache` — 스킨드 메시의 스킨 캐시 사용 여부

### 가상 텍스처 / 그림자 / 기타
- `viewmode VisualizeVirtualTexture` — VT 페이지 시각화
- `show VisualizeVirtualShadowMap` + `r.Shadow.Virtual.Visualize.Layout 1` + `r.Shadow.Virtual.Visualize.LightName <name>`
- `show VisualizeMeshDistanceFields` — 메시 SDF
- `show VisualizeGlobalDistanceField` — 전역 SDF (Lumen/DFAO 기반)

---

## Part 2: VisualizeTexture (vis) 명령

위치: `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RenderCore/Private/VisualizeTexture.cpp`

### 기본 사용법
```text
VisualizeTexture/Vis <RDGResourceNameWildcard>
VisualizeTexture/Vis <RDGResourceName>[@<Version>] [<Mode>] [PIP/UV0/UV1/UV2] [BMP] [FRAC/SAT] [FULL]
VisualizeTexture/Vis 0
VisualizeTexture/Vis pool [BYNAME/BYSIZE]
VisualizeTexture/Vis view=[ID/NAME]
```

### 옵션 플래그

| 플래그 | 의미 |
|---|---|
| `@<Version>` | 한 프레임에 같은 이름이 여러 번 쓰일 때 버전 지정 |
| `PIP` | Picture-in-Picture (한쪽 구석에 표시) |
| `UV0/UV1/UV2` | UV 매핑 모드 |
| `BMP` | BMP로 디스크에 저장 (Screenshots/VisualizeTexture) |
| `FRAC` | 0..1 범위로 시각화 |
| `SAT` | 채도 강조 |
| `FULL` | 전체 화면 |

### 자주 보는 텍스처 이름
- `SceneColor`, `SceneDepthZ`, `GBufferA`/`B`/`C`/`D`/`E`/`F` (Normal, MetallicSpecRough, BaseColorAO, CustomData, PrecomputedShadow, WorldTangent)
- `Velocity`, `ScreenSpaceAO`, `LightAccumulation`
- `ShadowMaskTexture`, `VirtualShadowMap*`
- `Lumen.Reflections.*`, `Lumen.ScreenProbeGather.*`
- `Bloom*`, `EyeAdaptation*`

### 관련 명령
- `r.DumpGPU` — 프레임 전체 RDG 그래프 디스크 덤프 (HTML viewer)
- `r.ShaderPrint 1` — 셰이더에서 `Print()` 호출 출력 (FontSize/MaxLine/MaxCharacters cvar)
- `r.ShaderPrint.Lock 1` — 셰이더 프린트 출력 고정

---

## Part 3: ViewMode 명령

위치: `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Classes/Engine/EngineBaseTypes.h` (`enum EViewModeIndex`), `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/ViewModeNames.cpp`

### 사용 형식
```text
viewmode <ModeName>
```

### 전체 ViewMode 목록 (VMI_*)

| 인덱스 | VMI 이름 | DisplayName | 콘솔 |
|---|---|---|---|
| 0 | VMI_BrushWireframe | Wireframe | `viewmode BrushWireframe` |
| 1 | VMI_Wireframe | CSG Wireframe | `viewmode Wireframe` |
| 2 | VMI_Unlit | Unlit | `viewmode Unlit` |
| 3 | VMI_Lit | Lit | `viewmode Lit` |
| 4 | VMI_Lit_DetailLighting | Detail Lighting | `viewmode Lit_DetailLighting` |
| 5 | VMI_LightingOnly | Lighting Only | `viewmode LightingOnly` |
| 6 | VMI_LightComplexity | Light Complexity | `viewmode LightComplexity` |
| 8 | VMI_ShaderComplexity | Shader Complexity | `viewmode ShaderComplexity` |
| 9 | VMI_LightmapDensity | Lightmap Density | `viewmode LightmapDensity` |
| 10 | VMI_LitLightmapDensity | Lit Lightmap Density | `viewmode LitLightmapDensity` |
| 11 | VMI_ReflectionOverride | Reflections | `viewmode ReflectionOverride` |
| 12 | VMI_VisualizeBuffer | Buffer Visualization | `viewmode VisualizeBuffer` |
| 14 | VMI_StationaryLightOverlap | Stationary Light Overlap | `viewmode StationaryLightOverlap` |
| 15 | VMI_CollisionPawn | Player Collision | `viewmode CollisionPawn` |
| 16 | VMI_CollisionVisibility | Visibility Collision | `viewmode CollisionVisibility` |
| 18 | VMI_LODColoration | Mesh LOD Coloration | `viewmode LODColoration` |
| 19 | VMI_QuadOverdraw | Quad Overdraw | `viewmode QuadOverdraw` |
| 20 | VMI_PrimitiveDistanceAccuracy | Primitive Distance | `viewmode PrimitiveDistanceAccuracy` |
| 21 | VMI_MeshUVDensityAccuracy | Mesh UV Density | `viewmode MeshUVDensityAccuracy` |
| 22 | VMI_ShaderComplexityWithQuadOverdraw | Shader Complexity & Quads | `viewmode ShaderComplexityWithQuadOverdraw` |
| 23 | VMI_HLODColoration | Hierarchical LOD Coloration | `viewmode HLODColoration` |
| 24 | VMI_GroupLODColoration | Group LOD Coloration | `viewmode GroupLODColoration` |
| 25 | VMI_MaterialTextureScaleAccuracy | Material Texture Scales | `viewmode MaterialTextureScaleAccuracy` |
| 26 | VMI_RequiredTextureResolution | Required Texture Resolution | `viewmode RequiredTextureResolution` |
| 27 | VMI_PathTracing | Path Tracing | `viewmode PathTracing` |
| 28 | VMI_RayTracingDebug | Ray Tracing Debug | `viewmode RayTracingDebug` |
| 29 | VMI_VisualizeNanite | Nanite Visualization | `viewmode VisualizeNanite` |
| 30 | VMI_VisualizeVirtualTexture | Virtual Texture Visualization | `viewmode VisualizeVirtualTexture` |
| 31 | VMI_VisualizeLumen | Lumen Visualization | `viewmode VisualizeLumen` |
| 32 | VMI_VisualizeVirtualShadowMap | VSM Visualization | `viewmode VisualizeVirtualShadowMap` |
| 33 | VMI_VisualizeGPUSkinCache | GPU Skin Cache Visualization | `viewmode VisualizeGPUSkinCache` |
| 34 | VMI_VisualizeSubstrate | Substrate Visualization | `viewmode VisualizeSubstrate` |
| 35 | VMI_VisualizeGroom | Groom Visualization | `viewmode VisualizeGroom` |
| 36 | VMI_LWCComplexity | Material LWC Function Usage | `viewmode LWCComplexity` |
| 37 | VMI_Lit_Wireframe | Lit Wireframe | `viewmode Lit_Wireframe` |
| 38 | VMI_VisualizeActorColoration | Actor Coloration | `viewmode VisualizeActorColoration` |
| 39 | VMI_ShadowCasters | Shadow Casters | `viewmode ShadowCasters` |
| 40 | VMI_Clay | Clay | `viewmode Clay` |

### 단축키 (에디터 뷰포트 기본)
- `Alt+1`: Brush Wireframe / Alt+2: Unlit / Alt+3: Lit / Alt+4: Detail Lighting / Alt+5: Lighting Only
- `Alt+6`: Light Complexity / Alt+7: Lightmap Density / Alt+8: Reflections / Alt+0: Shader Complexity

---

## Part 4: ShowFlag 목록 (카테고리별)

위치: `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Public/ShowFlagsValues.inl` 및 `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Public/ShowFlags.h`

### 사용 형식
```text
show <FlagName>          (게임 모드 토글)
showflag.<FlagName> 0/1/2  (cvar - 0:끔, 1:켬, 2:기본)
```

### 그룹 (EShowFlagGroup)
`SFG_Normal`, `SFG_Advanced`, `SFG_PostProcess`, `SFG_CollisionModes`, `SFG_Developer`, `SFG_Visualize`, `SFG_LightTypes`, `SFG_LightingComponents`, `SFG_LightingFeatures`, `SFG_Lumen`, `SFG_Nanite`, `SFG_Hidden`, `SFG_Transient`, `SFG_Custom`

### Rendering Features

#### PostProcess (SFG_PostProcess)
`Bloom`, `LocalExposure`, `Tonemapper`, `AntiAliasing`, `TemporalAA`, `EyeAdaptation`, `LensFlares`, `LensDistortion`, `MotionBlur`, `DepthOfField`, `Grain`, `ColorGrading`, `SceneColorFringe`, `CameraImperfections`, `HMDDistortion`, `AlphaInvert`, `PostProcessMaterial`

#### Lighting Components (SFG_LightingComponents)
`DirectLighting`, `GlobalIllumination`, `DynamicShadows`, `Diffuse`, `Specular`, `AmbientOcclusion`

#### Lighting Features (SFG_LightingFeatures)
`AmbientCubemap`, `CapsuleShadows`, `ContactShadows`, `DistanceFieldAO`, `IndirectLightingCache`, `LightFunctions`, `LightShafts`, `LumenGlobalIllumination`, `LumenReflections`, `MegaLights`, `RayTracedDistanceFieldShadows`, `ReflectionEnvironment`, `ScreenSpaceAO`, `ScreenSpaceReflections`, `VolumetricFog`, `VolumetricLightmap`

#### Light Types (SFG_LightTypes)
`DirectionalLights`, `PointLights`, `SpotLights`, `RectLights`, `SkyLighting`

### Lumen / Nanite / VSM

#### Lumen 관련 (SFG_Lumen)
`LumenDetailTraces`, `LumenFarFieldTraces`, `LumenGlobalTraces`, `LumenScreenTraces`, `LumenSecondaryBounces`, `LumenShortRangeAmbientOcclusion`

#### Nanite (SFG_Nanite)
`NaniteMeshes`, `NaniteStreamingGeometry`

#### Visualize (Hidden ViewMode 전용)
`VisualizeLumen`, `VisualizeNanite`, `VisualizeVirtualShadowMap`, `VisualizeSubstrate`, `VisualizeGroom`, `VisualizeBuffer`, `VisualizeVirtualTexture`, `VisualizeGPUSkinCache`

### Debug 시각화 (SFG_Visualize)
`VisualizeDOF`, `VisualizeDistanceFieldAO`, `VisualizeGlobalDistanceField`, `VisualizeMeshDistanceFields`, `VisualizeHDR`, `VisualizeMotionBlur`, `VisualizeOutOfBoundsPixels`, `VisualizePostProcessStack`, `VisualizeReprojection`, `VisualizeSSR`, `VisualizeSSS`, `VisualizeShadingModels`, `VisualizeSkyAtmosphere`, `VisualizeSkyLightIlluminance`, `VisualizeTSR`, `VisualizeTemporalUpscaler`, `VisualizeLocalExposure`, `VisualizeLocalFogVolumes`, `VisualizeVolumetricCloudConservativeDensity`, `VisualizeVolumetricCloudEmptySpaceSkipping`, `VisualizeVolumetricLightmap`, `VisualizeLightFunctionAtlas`, `VisualizeLightingOnProbes`, `VisualizeLevelInstanceEditing`, `VisualizeInstanceOcclusionQueries`, `OcclusionMeshes`, `PhysicsField`, `PrecomputedVisibilityCells`, `PreviewShadowsIndicator`, `VolumeLightingSamples`

### Developer (SFG_Developer)
`Bones`, `CompositeDebugPrimitives`, `CompositeEditorPrimitives`, `OpaqueCompositeEditorPrimitives`, `DebugAI`, `GameplayDebug`, `GBufferHints`, `HitProxies`, `OnScreenDebug`, `ServerDrawDebug`, `ShaderPrint`, `VisLog`, `VisualizeCalibrationColor`, `VisualizeCalibrationCustom`, `VisualizeCalibrationGrayscale`, `VirtualTexturePersistentData`, `VirtualTexturePrimitives`, `Refraction`, `TestImage`, `VertexColors`

### LOD/Coloration 시각화 (Hidden, ViewMode로 활성)
`LODColoration`, `HLODColoration`, `LightComplexity`, `LightMapDensity`, `MaterialTextureScaleAccuracy`, `MeshUVDensityAccuracy`, `OutputMaterialTextureScales`, `PrimitiveDistanceAccuracy`, `QuadOverdraw`, `RandomColor`, `ShaderComplexity`, `ShaderComplexityWithQuadOverdraw`, `VisualizeLWCComplexity`, `VisualizeLightCulling`, `VisualizeMotionVectors`, `VisualizeShadowCasters`, `Clay`, `FrontBackFace`, `MaterialNormal`, `MaterialAmbientOcclusion`, `Materials`, `Lighting`, `LightingOnlyOverride`, `OverrideDiffuseAndSpecular`, `ReflectionOverride`

### Advanced (SFG_Advanced)
`AllowPrimitiveAlphaHoldout`, `AudioRadius`, `Bounds`, `BSPSplit`, `CameraAspectRatioBars`, `CameraFrustums`, `CameraSafeFrames`, `Constraints`, `DeferredLighting`, `ForceFeedbackRadius`, `HeterogeneousVolumes`, `HISMCClusterTree`, `HISMCOcclusionBounds`, `InstancedFoliage`, `InstancedGrass`, `InstancedStaticMeshes`, `LargeVertices`, `LightInfluences`, `LightRadius`, `LOD`, `MassProperties`, `MeshEdges`, `ModeWidgets`, `Niagara`, `Paper2DSprites`, `PhysicalMaterialMasks`, `PrecomputedVisibility`, `Refraction`, `SeparateTranslucency`, `Selection`, `ShadowFrustums`, `Splines`, `VisualizeInstanceUpdates`, `VisualizeSenses`, `Volumes`, `Billboards`/`BillboardSprites`, `DebugDrawDistantVirtualSMLights`

### Normal (SFG_Normal)
`AntiAliasing`, `Atmosphere`, `BSP`, `Cameras`, `Cloud`, `Collision`, `Decals`, `Fog`, `Grid`, `Hair`, `Landscape`, `MediaPlanes`, `Navigation`, `Particles`, `SkeletalMeshes`, `StaticMeshes`, `WidgetComponents`

---

## Part 5: BufferVisualization 모드

위치: `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/BufferVisualizationData.cpp` (모드는 `Engine/Config/BaseEngine.ini`의 `[Engine.BufferVisualizationMaterials]` 섹션에서 동적 등록)

### 활성화
1. `viewmode VisualizeBuffer`
2. 또는 `show VisualizeBuffer 1`
3. 모드 선택: 에디터 메뉴 (View > Buffer Visualization > ...)
4. 콘솔: `r.BufferVisualizationOverviewTargets <Mode1>,<Mode2>,...` (Overview 모드 4×4 그리드에 표시할 채널)

### 표준 모드 이름 (BaseEngine.ini 기준 BufferVisualizationMaterials 섹션 동적 등록)
- `BaseColor` — 알베도
- `WorldNormal` — 월드 노멀
- `Roughness`, `Metallic`, `Specular`
- `Opacity`
- `SubsurfaceColor`
- `SceneDepth`, `SceneDepthWorldUnits`
- `MaterialAO`, `AmbientOcclusion`
- `ShadingModel`
- `PreTonemapHDRColor`, `PostTonemapHDRColor`
- `LightingOnly`
- `ReflectionsAndAmbientOcclusion`
- `Refraction`
- `LumenSceneFinalLighting` (Lumen 활성 시)
- `Velocity`
- `EditorPrimitives`
- `LWCComplexity`
- `Anisotropy`, `Tangent`

### 관련 cvar
- `r.BufferVisualizationDumpFrames 1` — 매 프레임 디스크 덤프
- `r.BufferVisualizationDumpFramesAsHDR 1` — HDR 포맷으로 덤프
- `r.BufferVisualizationOverviewTargets "BaseColor,WorldNormal,Roughness,Metallic"` — Overview 그리드 커스텀

---

## Part 6: Lumen / Nanite / VSM Visualize

### Lumen 시각화
위치: `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/Lumen/LumenVisualize.h` (모드 정의), `LumenVisualize.cpp` (cvar)

#### 모드 (`r.Lumen.Visualize <N>`)

| 값 | 매크로 | 설명 |
|---|---|---|
| 1 | VISUALIZE_MODE_OVERVIEW | 4분할 Overview |
| 2 | VISUALIZE_MODE_PERFORMANCE_OVERVIEW | 성능 Overview |
| 3 | VISUALIZE_MODE_LUMEN_SCENE | Lumen Scene 표면 |
| 4 | VISUALIZE_MODE_REFLECTION_VIEW | 리플렉션 뷰 |
| 5 | VISUALIZE_MODE_SURFACE_CACHE | Surface Cache |
| 6 | VISUALIZE_MODE_GEOMETRY_NORMALS | 지오메트리 노멀 |
| 7 | VISUALIZE_MODE_DEDICATED_REFLECTION_RAYS | 전용 반사 레이 |
| 8 | VISUALIZE_MODE_ALBEDO | Lumen Card 알베도 |
| 9 | VISUALIZE_MODE_NORMALS | Lumen Card 노멀 |
| 11 | VISUALIZE_MODE_OPACITY | Lumen Card 불투명도 |
| 22 | VISUALIZE_MODE_CARD_SHARING_ID | Card Sharing ID |
| 23 | SCREENPROBEGATHER_FAST_UPDATE_MODE_AMOUNT | Screen Probe Fast Update |
| 24 | SCREENPROBEGATHER_NUM_FRAMES_ACCUMULATED | Screen Probe 누적 프레임 수 |

#### 주요 Lumen Visualize cvar
| cvar | 설명 |
|---|---|
| `r.Lumen.Visualize` | 활성 모드 번호 (또는 `viewmode VisualizeLumen` 사용 시 메뉴 선택) |
| `r.Lumen.Visualize.HiResSurface` | 고해상도 Card 표면 |
| `r.Lumen.Visualize.HardwareRayTracing` | HW RT 사용 |
| `r.Lumen.Visualize.HardwareRayTracing.DeferredMaterial` | Deferred Material |
| `r.Lumen.Visualize.HardwareRayTracing.HitLighting` | Hit Lighting |
| `r.Lumen.Visualize.HardwareRayTracing.FarField` | Far Field |
| `r.Lumen.Visualize.CullingMode` | 컬링 모드 |
| `r.Lumen.Visualize.ToneMap` | 톤맵 적용 |
| `r.Lumen.Visualize.GridPixelSize` | 시각화 그리드 픽셀 크기 |
| `r.Lumen.Visualize.IndirectDiffuse` | 간접광 표시 |
| `r.Lumen.Visualize.TraceMeshSDFs` | Mesh SDF 트레이스 |
| `r.Lumen.Visualize.MaxMeshSDFTraceDistance` | 최대 SDF 트레이스 거리 |
| `r.Lumen.Visualize.SurfaceCacheFeedback` | 피드백 시각화 |
| `r.Lumen.Visualize.TraceRadianceCache` | Radiance Cache 트레이스 |
| `r.Lumen.Visualize.ConeAngle` | 콘 각도 |
| `r.Lumen.Visualize.ConeStepFactor` | 콘 스텝 |
| `r.Lumen.Visualize.MinTraceDistance` / `.MaxTraceDistance` | 트레이스 거리 |
| `r.Lumen.Visualize.CardPlacement` | Card 배치 표시 |
| `r.Lumen.Visualize.CardPlacementDistance` | Card 배치 거리 |
| `r.Lumen.Visualize.CardPlacementLOD` | Card LOD |
| `r.Lumen.Visualize.CardPlacementPrimitives` | 프리미티브별 Card |
| `r.Lumen.Visualize.CardPlacementIndex` | 인덱스별 Card |
| `r.Lumen.Visualize.CardPlacementDirection` | 방향별 Card |
| `r.Lumen.Visualize.CardInterpolateInfluenceRadius` | 보간 영향 반경 |
| `r.Lumen.Visualize.CardGenerationSurfels` | 생성 Surfel |
| `r.Lumen.Visualize.CardGenerationSurfelScale` | Surfel 스케일 |
| `r.Lumen.Visualize.CardGenerationClusterScale` | Cluster 스케일 |
| `r.Lumen.Visualize.CardGenerationCluster` | Cluster |
| `r.Lumen.Visualize.CardGenerationMaxSurfel` | 최대 Surfel |
| `r.Lumen.Visualize.RayTracingGroups` | RT 그룹 |
| `r.Lumen.Visualize.UseShaderPrintForTraces` | ShaderPrint 사용 |

### Nanite 시각화
위치: `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/NaniteVisualizationData.cpp`

#### 모드 (FNaniteVisualizationData::AddVisualizationMode)
| 모드 이름 | 분류 | 설명 |
|---|---|---|
| `Overview` | Overview | 4분할 |
| `Mask` | Standard | Nanite 마스크 |
| `Triangles` | Standard | 트라이앵글 색상 |
| `Patches` | Standard | 패치 |
| `Clusters` | Standard | 클러스터 색상 |
| `Primitives` | Standard | 프리미티브 |
| `Instances` | Standard | 인스턴스 |
| `Overdraw` | Standard | 오버드로 |
| `LightmapUV` | Standard | 라이트맵 UV |
| `EvaluateWPO` | Standard | WPO 평가 |
| `PixelProgrammable` | Standard | 픽셀 프로그래머블 |
| `Tessellation` | Standard | 테셀레이션 |
| `RasterBins` | Standard | Raster Bin |
| `ShadingBins` | Standard | Shading Bin |
| `ShadowCasters` | Advanced | 그림자 캐스터 |
| `Picking` | Advanced | 피킹 정보 |
| `Groups` | Advanced | 그룹 |
| `Pages` | Advanced | 페이지 |
| `Hierarchy` | Advanced | 계층 |
| `RasterMode` | Advanced | Raster Mode (HW/SW) |

#### Nanite Visualize cvar
- `r.Nanite.Visualize.Composite` — 시각화 합성 1/0
- `r.Nanite.Visualize.EdgeDetect` — 엣지 검출
- `r.Nanite.Visualize.DebugShading` — 디버그 셰이딩
- `r.Nanite.Visualize.OverdrawScale` — 오버드로 스케일
- `r.Nanite.Visualize.ComplexityScale` — 복잡도 스케일
- `r.Nanite.Visualize.ComplexityOverhead` — 복잡도 오버헤드
- `r.Nanite.Visualize.PixelProgrammableVisMode` — 픽셀 프로그래머블 시각화 서브모드

### VSM (Virtual Shadow Map) 시각화
위치: `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/VirtualShadowMaps/VirtualShadowMapArray.cpp`

#### 활성화
- `viewmode VisualizeVirtualShadowMap` 또는 `show VisualizeVirtualShadowMap 1`

#### 주요 cvar
- `r.Shadow.Virtual.Visualize.Layout 1` — 캐시 페이지 풀 레이아웃 표시
- `r.Shadow.Virtual.Visualize.LightName <name>` — 특정 라이트 이름의 VSM만 시각화
- `r.Shadow.Virtual.Visualize.DumpLightNames 1` — 사용 가능한 라이트 이름 출력
- `r.Shadow.Virtual.VisualizeDynamicMeshBounds 1` — 다이내믹 메시 바운드 표시

#### 일반 메뉴 모드 (Editor View 메뉴 → VSM Visualization)
- `ProjectionData` — 클립맵/큐브 투영 데이터
- `CachedPagesPool` — 캐시 페이지 풀
- `ShadowDepth` — 그림자 깊이
- `ClipmapVirtualSpace` — 클립맵 가상 공간
- `MipLevel` — Mip 레벨
- `RawMip` — 원시 Mip

---

## Part 7: Shader / Material 디버깅

### Material Editor 통계
- 머티리얼 에디터 툴바 → **Stats / Platform Stats** 토글
- `r.MaterialEditor.PreviewMaterial.QualityLevel` — 미리보기 퀄리티
- 셰이더 인스트럭션 카운트, 텍스처 샘플러 수, VS/PS 비용 표시

### ShaderPrint (셰이더 내부 디버그 출력)
- `r.ShaderPrint 1` — 활성화
- `r.ShaderPrint.FontSize` / `.FontSpacingX` / `.FontSpacingY`
- `r.ShaderPrint.MaxCharacters`, `.MaxWidget`, `.MaxLine`, `.MaxTriangle`
- `r.ShaderPrint.Lock 1` — 출력 고정 (다른 프레임의 결과를 비교)
- `r.ShaderPrint.DrawOccludedLines 1` — 가려진 라인도 그림

### DumpGPU (전체 RDG 그래프 디스크 덤프)
- `DumpGPU` 또는 `r.DumpGPU` 명령 — `Saved/GPUDumps`에 HTML 뷰어 포함 덤프
- `r.DumpGPU.Texture 2` / `r.DumpGPU.Buffer 2` — 텍스처/버퍼 덤프 디테일
- `r.DumpGPU.FrameCount N` — 여러 프레임 캡처
- `r.DumpGPU.ConsoleVariables 1` — 현재 cvar 상태도 함께 덤프
- `r.DumpGPU.Stream 1` — 스트리밍 덤프

### 머티리얼 디버그 ShowFlag
- `show MaterialNormal` / `show MaterialAmbientOcclusion` — 머티리얼 출력 단독 보기 (Hidden 그룹, 콘솔에서)
- `show OverrideDiffuseAndSpecular` — 디퓨즈/스펙큘러를 표준값으로 강제
- `show ReflectionOverride` — 미러 머티리얼로 강제 (= viewmode ReflectionOverride)
- `show Materials 0` — 모든 머티리얼 디퓨즈 회색
- `show Lighting 0` — 라이팅 끔
- `show LightingOnlyOverride` — Detail Lighting 모드와 유사

### Custom UV / 머티리얼 노드 디버그
- 머티리얼 에디터 노드 우클릭 → **"Start Previewing Node"** — 해당 노드 출력만 프리뷰 머티리얼 박스에 표시
- 머티리얼 그래프 → **CustomizedUVs** 노드 출력을 BaseColor 등에 연결해 직접 확인

---

## Part 8: 단축키와 메뉴 위치

### 에디터 뷰포트 메뉴 매핑
| 메뉴 경로 | 동작 |
|---|---|
| **View Mode** ▶ Lit / Unlit / Wireframe / Detail Lighting / Lighting Only / Reflections | `viewmode <X>` |
| **View Mode** ▶ Optimization Viewmodes ▶ Light Complexity / Lightmap Density / Stationary Light Overlap / Shader Complexity / Quad Overdraw / Required Texture Resolution | optimization viewmode |
| **View Mode** ▶ Buffer Visualization ▶ ... | `viewmode VisualizeBuffer` + 모드 선택 |
| **View Mode** ▶ Nanite Visualization ▶ ... | `viewmode VisualizeNanite` + 모드 |
| **View Mode** ▶ Lumen ▶ ... | `viewmode VisualizeLumen` + 모드 |
| **View Mode** ▶ Virtual Shadow Map ▶ ... | `viewmode VisualizeVirtualShadowMap` + 모드 |
| **View Mode** ▶ Substrate Visualizations ▶ ... | `viewmode VisualizeSubstrate` |
| **View Mode** ▶ Groom Visualization ▶ ... | `viewmode VisualizeGroom` |
| **Show** ▶ Show Flags ... ▶ ... | `show <FlagName>` 또는 `showflag.<FlagName>` cvar |

### 단축키
- `Alt+G` — Game View
- `G` — Game Mode (게임 뷰 토글)
- `H` — 선택된 액터 숨김
- `Alt+1~Alt+8` — ViewMode 빠른 전환 (위 표 참조)
- `Ctrl+1~Ctrl+0` — Viewport 레이아웃 프리셋

### 콘솔 명령 vs 에디터 UI

| 작업 | 콘솔 | 에디터 UI |
|---|---|---|
| ShowFlag 토글 | `show X` (게임), `showflag.X 0/1/2` (cvar, 영구) | 뷰포트 메뉴 ▶ Show |
| ViewMode 전환 | `viewmode X` | 뷰포트 메뉴 ▶ View Mode |
| BufferViz 모드 | `r.BufferVisualizationOverviewTargets ...` (그리드만) | View Mode ▶ Buffer Visualization 메뉴 |
| Texture 검사 | `vis <name>` | (없음, 콘솔 전용) |
| GPU 덤프 | `DumpGPU` | (없음, 콘솔 전용) |

`showflag.<Name>`는 `consolevariables.ini`에 적어 영구화 가능 (값 2 = 기본 사용).

---

## Part 9: 참고 파일 위치

### ShowFlag 정의
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Public/ShowFlags.h` — `EShowFlagGroup` enum, 매크로 인터페이스
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Public/ShowFlagsValues.inl` — 모든 ShowFlag 매크로 호출 (전체 목록)
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/ShowFlags.cpp` — `showflag` cvar 등록

### ViewMode 정의
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Classes/Engine/EngineBaseTypes.h` — `enum EViewModeIndex` (VMI_*)
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/ViewModeNames.cpp` — DisplayName 매핑
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/DebugViewModeHelpers.cpp`, `DebugViewModeInterface.cpp`

### VisualizeTexture
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RenderCore/Private/VisualizeTexture.cpp` — `vis` 명령 구현
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/Tools/VisualizeTexture.usf`

### BufferVisualization
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/BufferVisualizationData.cpp`
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/PostProcess/PostProcessBufferInspector.cpp`
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Config/BaseEngine.ini` — `[Engine.BufferVisualizationMaterials]` 섹션 (모드 동적 등록)

### Lumen
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/Lumen/LumenVisualize.h` — `VISUALIZE_MODE_*` 매크로
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/Lumen/LumenVisualize.cpp` — cvar 및 패스
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/Lumen/LumenVisualizeHardwareRayTracing.cpp`
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/Lumen/LumenVisualizeRadianceCache.cpp`

### Nanite
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/NaniteVisualizationData.cpp` — 모드 등록 (`NANITE_VISUALIZE_*`)

### VSM
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/VirtualShadowMaps/VirtualShadowMapArray.cpp` — VSM 시각화 cvar
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/VirtualShadowMaps/VirtualShadowMapVisualize.ush`

### Substrate
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/Substrate/SubstrateVisualize.cpp`

### 기타
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/PostProcess/VisualizeTexture.cpp`
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/PostProcess/PostProcessVisualizeVirtualTexture.cpp`
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/DistanceFieldVisualization.cpp`
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RenderCore/Private/ShaderPrint.cpp`
- `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/GPUSkinCache.cpp` — `FGPUSkinCacheVisualizationData`
