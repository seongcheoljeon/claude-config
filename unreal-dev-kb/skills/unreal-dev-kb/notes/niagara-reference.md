# UnrealEngine Niagara 개발자 레퍼런스

> UE5 Niagara FX 시스템의 콘솔 변수(cvar) 카탈로그. 총 **327개** cvar.
> 자동 추출 대상: `Engine/Plugins/FX/Niagara/Source/`, `Engine/Source/Runtime/Engine/Private/Particles/`, `Engine/Source/Runtime/Engine/Private/`

---

## Part 1: 시나리오별 cvar 추천

### 이펙트 디버깅 (Solo 모드)

| cvar | 용도 |
|------|------|
| `fx.ForceNiagaraSpawnAttachedSolo 1` | 모든 어태치 시스템을 Solo 모드로 강제 — 디버그 격리 |
| `fx.Niagara.Debug.Hud 1` | Niagara Debug HUD 활성화 (실시간 시스템 상태 오버레이) |
| `fx.Niagara.Debug.GlobalLoopTime <초>` | 시스템을 N초 주기로 자동 재시작 — 짧은 루프 디버깅 |
| `fx.Niagara.Debug.SpawnComponent <AssetPath>` | 콘솔에서 직접 시스템 스폰 |
| `fx.Niagara.Debug.KillSpawned` | Debug HUD로 스폰한 모든 시스템 제거 |
| `fx.Niagara.SystemSimulation.AllowASync 0` | 비동기 시뮬 끄고 게임스레드에서 실행 — 브레이크포인트 디버깅 용이 |
| `fx.Niagara.LeakDetector.Enabled 1` | 컴포넌트 누수 추적 |

### GPU 시뮬레이션 문제

| cvar | 용도 |
|------|------|
| `fx.NiagaraAllowGPUParticles 0` | GPU 파티클 전역 비활성 (CPU로 강제 다운그레이드) |
| `fx.NiagaraAllowComputeShaders 0` | Compute Shader 사용 차단 |
| `fx.Niagara.GpuProfiling.Enabled 1` | GPU 시뮬레이션 프로파일링 활성 |
| `fx.Niagara.GpuComputeDebug.OccludedLineColorScale` | GPU 디버그 시각화 색상 |
| `fx.Niagara.AsyncGpuTrace.HWRayTraceEnabled` | HW Ray Trace 백엔드 토글 |
| `fx.Niagara.AsyncGpuTrace.GlobalSdfEnabled` | Global SDF 트레이스 백엔드 토글 |
| `fx.Niagara.Batcher.TickFlush.Mode <0..2>` | GPU 시뮬 디스패치 플러시 정책 |
| `fx.Niagara.Batcher.TickFlush.MaxPendingTicks` | 누적 가능한 GPU 틱 한계 |
| `fx.Niagara.Batcher.DebugLogging 1` | GPU Dispatcher 상세 로그 |

### 컴파일 속도 향상

| cvar | 용도 |
|------|------|
| `fx.SkipVectorVMBackendOptimizations 1` | VectorVM 최적화 패스 스킵 — 컴파일 시간 대폭 단축 (개발용) |
| `fx.Niagara.Compilation.MaxActiveTaskCount` | 동시 컴파일 작업 수 제한 |
| `fx.Niagara.Compilation.StalledTaskWarningTime` | 컴파일 정체 경고 임계값 |
| `fx.Niagara.CompileDDCWaitTimeout` | DDC 컴파일 대기 타임아웃 |
| `fx.ForceCompileOnLoad 1` | 로드 시마다 강제 재컴파일 (DDC 무시) |
| `fx.InvalidateCachedScripts` | 캐시된 스크립트 전체 무효화 |
| `fx.ForceNiagaraTranslatorSingleThreaded 1` | Translator 단일 스레드 모드 |
| `fx.Niagara.Shader.EnableHLSL2021` | HLSL 2021 컴파일러 사용 토글 |

### 성능 측정 / 프로파일링

| cvar | 용도 |
|------|------|
| `fx.ParticlePerfStats.Enabled 1` | 파티클 성능 통계 수집 |
| `fx.ParticlePerfStats.RunTest <매개변수>` | 자동 성능 측정 테스트 |
| `fx.DetailedCSVStats 1` | CSV 프로파일러 상세 통계 |
| `fx.DetailedCSVStats.MemoryMode` | CSV 메모리 통계 모드 |
| `fx.Budget.Enabled 1` | FX 예산 시스템 활성 |
| `fx.Budget.GameThread / .RenderThread / .GameThreadConcurrent` | 스레드별 예산 ms 설정 |
| `fx.Budget.HistoryFrames` | 예산 평균 계산 프레임 수 |
| `fx.Niagara.GpuProfiling.Enabled` | GPU 프로파일링 활성 |
| `fx.EnableNiagaraRuntimeCycleCounts 1` | 런타임 사이클 카운터 활성 |
| `fx.Niagara.TaskPriorities.PerfCapturePriority` | 퍼포먼스 캡처 시 작업 우선순위 |

### 메모리 누수 추적

| cvar | 용도 |
|------|------|
| `fx.Niagara.LeakDetector.Enabled 1` | NiagaraComponent 누수 감지기 |
| `fx.Niagara.DataChannels.NDCMapBase.InitialSize` | NDC Map 풀 초기 사이즈 |
| `fx.Niagara.DataChannels.NDCMapBase.FreeUnusedTime` | NDC Map 풀 미사용 정리 시간 |
| `fx.DumpParticleData` | 파티클 데이터 덤프 |
| `fx.DumpSystemData` | 시스템 데이터 덤프 |
| `fx.DumpParticleParameterStores` | 파라미터 스토어 덤프 |

### 파티클 카운트 제한

| cvar | 용도 |
|------|------|
| `fx.Niagara.QualityLevel` 관련 | 품질 레벨에 따른 파티클 수 자동 스케일 |
| `fx.QualityLevelSpawnRateScaleReferenceLevel` | 스폰 비율 스케일의 기준 레벨 |
| `fx.Budget.AdjustedUsageMax` | 부하 적응 시스템의 최대 사용량 |
| `fx.PruneEmittersOnCookByDetailMode` | 쿡 시 디테일 모드 기준으로 emitter 가지치기 |

> 참고: UE5 Niagara에는 `fx.MaxCPUParticlesPerEmitter` 같은 명시적 cvar가 **없다**. 대신 emitter 자체의 `MaxParticleCount`(에셋 속성)와 Scalability/Budget 시스템을 통해 제어한다.

---

## Part 2: cvar 전체 카탈로그

### General / Other (100개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.AllowFastPathFunctionLibrary` | `(ref:GAllowFastPathFunctionLibrary)` | Ref | ECVF_Default | If > 0 Allow the graph to insert custom fastpath operations into the graph. | `Niagara/Private/NiagaraFunctionLibrary.cpp:51` |
| `fx.EnableNiagaraCRHandler` | `(ref:GbEnableNiagaraCRHandler)` | Ref | ECVF_Default | If > 0 Niagara will push some state into the crash reporter. This is not free so should... | `Niagara/Private/NiagaraCrashReporterHandler.cpp:14` |
| `fx.EnableNiagaraRuntimeCycleCounts` | `(ref:GEnableNiagaraRuntimeCycleCounts)` | Ref | ECVF_ReadOnly | Toggle for runtime cylce counts tracking Niagara's frame time. | `Niagara/Private/NiagaraSystem.cpp:170` |
| `fx.ExecVMScripts` | `(ref:GbExecVMScripts)` | Ref | ECVF_Default | If > 0 VM scripts will be executed, otherwise they won't, useful for looking at the... | `Niagara/Private/NiagaraScriptExecutionContext.cpp:21` |
| `fx.ForceExecVMPath` | `(ref:GbForceExecVMPath)` | Ref | ECVF_Default | If < 0, the legacy VM path will be used, if > 0 the experimental version will be used,... | `Niagara/Private/NiagaraScriptExecutionContext.cpp:29` |
| `fx.ForceFailIfPreviouslyNotSetOnMerge` | `(ref:GNiagaraForceFailIfPreviouslyNotS...` | Ref | ECVF_Default | If > 0, when merging in from parent emitters swap linked variables in the stack to be... | `NiagaraEditor/Private/NiagaraScriptMergeManager.cpp:49` |
| `fx.ForceMergeOnLoad` | `(ref:GbForceNiagaraMergeOnLoad)` | Ref | ECVF_Default | If > 0 emitters will be forced to merge on load. | `Niagara/Private/NiagaraEmitter.cpp:57` |
| `fx.ForceSafeScriptAttributeTrim` | `(ref:GNiagaraForceSafeScriptAttributeT...` | Ref | ECVF_Default | If > 0 attribute trimming will use a less aggressive algorithm for removing script... | `Niagara/Private/NiagaraScript.cpp:81` |
| `fx.LogNiagaraSystemChanges` | `(ref:GbLogNiagaraSystemChanges)` | Ref | ECVF_Default | If > 0 Niagara Systems will be written to a text format when opened and closed in the... | `Private/Toolkits/NiagaraSystemToolkit.cpp:78` |
| `fx.MaxNiagaraCPUParticlesPerEmitter` | `(ref:GMaxNiagaraCPUParticlesPerEmitter)` | Ref | ECVF_Default | The max number of supported CPU particles per emitter in Niagara. | `Niagara/Private/NiagaraEmitterInstanceImpl.cpp:67` |
| `fx.MaxNiagaraNeighborGridCells` | `(ref:GMaxNiagaraNeighborGridCells)` | Ref | ECVF_Default | The max number of supported grid cells in Niagara. Overflowing this threshold will cause... | `Niagara/Private/NiagaraDataInterfaceNeighborGrid3D.cpp:33` |
| `fx.MaxNiagaraRasterizationGridCells` | `(ref:GMaxNiagaraRasterizationGridCells)` | Ref | ECVF_Default | The max number of supported grid cells in Niagara. Overflowing this threshold will cause... | `Niagara/Private/NiagaraDataInterfaceRasterizationGrid3D.cpp:57` |
| `fx.Niagara.AllowAllDeviceProfiles` | `(ref:GbAllowAllDeviceProfiles)` | Ref | ECVF_Default |  | `Niagara/Private/NiagaraPlatformSet.cpp:130` |
| `fx.Niagara.AllowCullProxies` | `(ref:GNiagaraAllowCullProxies)` | Ref | ECVF_Default | Toggles whether Niagara will use Cull Proxy systems in place of systems culled by... | `Niagara/Private/NiagaraWorldManager.cpp:187` |
| `fx.Niagara.AllowDeferredReset` | `(ref:GNiagaraAllowDeferredReset)` | Ref | ECVF_Default | If we are running async work when a reset is requested we will instead queue for the... | `Niagara/Private/NiagaraSystemInstance.cpp:101` |
| `fx.Niagara.AllowVisibilityCullingForDynamicBounds` | `(ref:GbAllowVisibilityCullingForDynami...` | Ref | ECVF_Default | Allow async work to continue until the end of the frame, if false it will complete within... | `Niagara/Private/NiagaraWorldManager.cpp:122` |
| `fx.Niagara.Analytics.ReportOnCook` | `(ref:GNiagaraReportOnCook)` | Ref | ECVF_Default | If true then basic system info will be gathered and reported as part of the editor... | `Niagara/Private/NiagaraSystem.cpp:224` |
| `fx.Niagara.BaselineGenerationDelay` | `(ref:GBaselineGenerationDelay)` | Ref | ECVF_Default | Time we delay before match start for generating niagara perfoamnce baselines in a cooked... | `Niagara/Private/NiagaraPerfBaseline.cpp:59` |
| `fx.Niagara.CSVSplitTime` | `(ref:GNiagaraCSVSplitTime)` | Ref | ECVF_Default | Length of Niagara's split time events passed to the CSV profiler. There are used to give... | `Niagara/Private/NiagaraWorldManager.cpp:195` |
| `fx.Niagara.CleanStatelessEmitterHandles` | `(ref:GCleanStatelessEmitterHandles)` | Ref | ECVF_Default | When enabled stateless emitter handles will clean the stateful emitter during cook to... | `Niagara/Private/NiagaraSystem.cpp:101` |
| `fx.Niagara.Collision.CPUEnabled` | `(ref:GNiagaraCollisionCPUEnabled)` | Ref | ECVF_Default | Controls if CPU collisions are enabled or not. | `Niagara/Private/NiagaraCollision.cpp:19` |
| `fx.Niagara.Component.DeactivateActive` | `(command)` | Command | - | Iterates all activate components and deactivates them. | `Niagara/Private/NiagaraComponent.cpp:222` |
| `fx.Niagara.Component.ReinitializeActive` | `(command)` | Command | - | Iterates all activate components and reinitializes them. | `Niagara/Private/NiagaraComponent.cpp:211` |
| `fx.Niagara.ComponentWarnAsleepCullReaction` | `(ref:GWarnAsleepCullReaction)` | Ref | ECVF_Default | When enabled we will warn if a NiagaraComponent completes naturally but has Asleep mode... | `Niagara/Private/NiagaraComponent.cpp:84` |
| `fx.Niagara.ComponentWarnNullAsset` | `(ref:GWarnNullAsset)` | Ref | ECVF_Default | When enabled we will warn if a NiagaraComponent is activate with a null asset.  This is... | `Niagara/Private/NiagaraComponent.cpp:76` |
| `fx.Niagara.CompressScriptByteCode` | `(ref:GNiagaraCompressScriptByteCode)` | Ref | ECVF_Default | Should we compress script bytecode to save memory. Will be uncompressed on demand. | `Niagara/Private/NiagaraScript.cpp:89` |
| `fx.Niagara.DeletePythonFilesOnError` | `(ref:GNiagaraDeletePythonFilesOnError)` | Ref | ECVF_Default | This determines whether we keep the intermediate python used by module/emitter versioning... | `NiagaraEditor/Private/NiagaraEditorUtilities.cpp:97` |
| `fx.Niagara.EmitterBounds.DynamicExpandMultiplier` | `(ref:GNiagaraEmitterBoundsDynamicExpan...` | Ref | ECVF_Default | Multiplier used on dynamic bounds gathering, i.e. 1 means no change, 1.1 means increase... | `Niagara/Private/NiagaraSystemInstance.cpp:84` |
| `fx.Niagara.EmitterBounds.DynamicSnapValue` | `(ref:GNiagaraEmitterBoundsDynamicSnapV...` | Ref | ECVF_Default | The value used to snap (round up) dynamic bounds calculations to. | `Niagara/Private/NiagaraSystemInstance.cpp:75` |
| `fx.Niagara.EmitterBounds.FixedExpandMultiplier` | `(ref:GNiagaraEmitterBoundsFixedExpandM...` | Ref | ECVF_Default | Multiplier used on fixed bounds gathering, i.e. 1 means no change, 1.1 means increase by... | `Niagara/Private/NiagaraSystemInstance.cpp:93` |
| `fx.Niagara.EnableCustomInlineDynamicInputFormats` | `(ref:GbEnableCustomInlineDynamicInputF...` | Ref | ECVF_Default | If > 0 and experimental inline editors for dynamic input trees are enabled, custom... | `NiagaraEditor/Private/NiagaraEditorModule.cpp:235` |
| `fx.Niagara.EnableExperimentalInlineDynamicInputs` | `(ref:GbEnableExperimentalInlineDynamic...` | Ref | ECVF_Default | If > 0 experimental inline editors for dynamic input trees will be available via right... | `NiagaraEditor/Private/NiagaraEditorModule.cpp:228` |
| `fx.Niagara.FailIfNotSetSeverity` | `(ref:GNiagaraTranslatorFailIfNotSetSev...` | Ref | ECVF_Default | The severity of messages emitted by Parameters with Default Mode \"Fail If Not Set\". 3 =... | `NiagaraShader/Private/NiagaraShared.cpp:39` |
| `fx.Niagara.Grid2D.CubicInterpMethod` | `(ref:GNiagaraGrid2DCubicInterpMethod)` | Ref | ECVF_Default | 0=Bridson, 1=monotonic/Fedkiw. | `Niagara/Private/NiagaraDataInterfaceGrid2DCollection.cpp:50` |
| `fx.Niagara.Grid2D.OverrideFormat` | `(ref:GNiagaraGrid2DOverrideFormat)` | Ref | ECVF_Default | Optional override for all grids to use this format. | `Niagara/Private/NiagaraDataInterfaceGrid2DCollection.cpp:184` |
| `fx.Niagara.Grid2D.ResolutionMultiplier` | `(ref:GNiagaraGrid2DResolutionMultiplier)` | Ref | ECVF_Default | Optional global modifier to grid resolution | `Niagara/Private/NiagaraDataInterfaceGrid2DCollection.cpp:176` |
| `fx.Niagara.Grid3D.OverrideFormat` | `(ref:GNiagaraGrid3DOverrideFormat)` | Ref | ECVF_Default | Optional override for all grids to use this format. | `Niagara/Private/NiagaraDataInterfaceGrid3DCollection.cpp:59` |
| `fx.Niagara.Grid3D.ResolutionMultiplier` | `(ref:GNiagaraGrid3DResolutionMultiplier)` | Ref | ECVF_Default | Optional global modifier to grid resolution | `Niagara/Private/NiagaraDataInterfaceGrid3DCollection.cpp:51` |
| `fx.Niagara.Grid3D.UseRGBAGrid` | `(ref:GNiagaraGrid3DUseRGBAGrid)` | Ref | ECVF_Default | Use RGBA textures when possible | `Niagara/Private/NiagaraDataInterfaceGrid3DCollectionUtils.cpp:9` |
| `fx.Niagara.LUT.OptimizeThreshold` | `(ref:GNiagaraLUTOptimizeThreshold)` | Ref | ECVF_Default | Error Threshold used when optimizing Curve LUTs, setting to 0.0 or below will result in... | `Niagara/Private/NiagaraDataInterfaceCurveBase.cpp:22` |
| `fx.Niagara.LUT.VerifyPostLoad` | `(ref:GNiagaraLUTVerifyPostLoad)` | Ref | ECVF_Default | Enable to verify LUTs match in PostLoad vs the Loaded Data | `Niagara/Private/NiagaraDataInterfaceCurveBase.cpp:30` |
| `fx.Niagara.Landscape.MaxRegionCaptureCount` | `(ref:GMaxRegionCaptureCount)` | Ref | ECVF_Default | The maximum number of collision components that will be captured by the Landscape DI. | `Niagara/Private/NiagaraDataInterfaceLandscape.cpp:58` |
| `fx.Niagara.Landscape.MaxRegionSearchCount` | `(ref:GMaxRegionSearchCount)` | Ref | ECVF_Default | The maximum number of collision components that will be evaluated for capture by the... | `Niagara/Private/NiagaraDataInterfaceLandscape.cpp:48` |
| `fx.Niagara.LegacyDeviceProfile` | `(ref:GNiagaraLegacyDeviceProfile)` | Ref | ECVF_Scalability | This is a special case CVar that allows us to use CVar conditions to maintain behavior... | `Niagara/Private/NiagaraPlatformSet.cpp:143` |
| `fx.Niagara.LogFoundButNotAllowedAssets` | `(ref:GbShowNiagaraDeveloperWindows)` | Ref | ECVF_Default | If > 0 assets which are found, but not allowed in the current editor context will be... | `NiagaraEditor/Private/NiagaraEditorSettings.cpp:28` |
| `fx.Niagara.LogVerboseWarnings` | `(ref:GNiagaraLogVerboseWarnings)` | Ref | ECVF_Default | Enable to output more verbose warnings to the log file, these are considered dismissable... | `Niagara/Private/NiagaraCommon.cpp:74` |
| `fx.Niagara.MarkPackageDirtyWhenNotSynchronized` | `(ref:GMarkPackageDirtyWhenNotSynchroni...` | Ref | ECVF_Default | When running a commandlet will mark the package dirty if the system or emitter scripts... | `Niagara/Private/NiagaraSystem.cpp:110` |
| `fx.Niagara.MaxStatRecordedFrames` | `(ref:GbMaxStatRecordedFrames)` | Ref | ECVF_Default | The number of frames recorded for the stat performance display of niagara cpu and gpu... | `Niagara/Private/NiagaraCommon.cpp:66` |
| `fx.Niagara.NDISpline.GDisableLUTs` | `(ref:GbNiagaraDISplineDisableLUTs)` | Ref | ECVF_Default | Should we turn off all LUTs on CPU? | `Niagara/Private/NiagaraDataInterfaceSpline.cpp:104` |
| `fx.Niagara.ObjectNeedsLoadMode` | `(ref:GNiagaraObjectNeedsLoadMode)` | Ref | ECVF_Default | How we decide to handle objects that need loading | `Niagara/Private/NiagaraSystem.cpp:213` |
| `fx.Niagara.PSOPrecache.ReverseCulling` | `(ref:GNiagaraPSOPrecacheReverseCulling)` | Ref | ECVF_Default | Also Precache PSOs with with reverse culling set when not 2 sided. (default 1) | `Niagara/Private/NiagaraRendererProperties.cpp:37` |
| `fx.Niagara.ParallelGDME` | `(ref:GParallelGDMEEnabled)` | Ref | ECVF_Default | Allow Niagara to run parallel in GDME. | `Niagara/Private/NiagaraComponent.cpp:60` |
| `fx.Niagara.ParticleRead.IgnoreUnsafeReads` | `(ref:GNiagaraParticleReadIgnoreUnsafeR...` | Ref | ECVF_Default | When enabled we will allow unsafe reads to compile with a warning, however the read... | `Niagara/Private/NiagaraDataInterfaceParticleRead.cpp:108` |
| `fx.Niagara.PerfTestFrames` | `(ref:GPerfTestFrames)` | Ref | ECVF_Default | How many frames to gather in each performance test. | `Niagara/Private/NiagaraPerfBaseline.cpp:67` |
| `fx.Niagara.PreloadSelectablePluginAssetsOnDemand` | `(ref:GbPreloadSelectablePluginAssetsOn...` | Ref | ECVF_Default | If > 0 then niagara system, emitter, and script assets provided by the niagara plugin... | `NiagaraEditor/Private/NiagaraEditorModule.cpp:221` |
| `fx.Niagara.Rollback.NewWorldCleanup` | `(ref:NewWorldCleanup)` | Ref | ECVF_Default | When true we'll use the new World Manager Cleanup flows. False will use old legacy code. | `Niagara/Private/NiagaraWorldManager.cpp:52` |
| `fx.Niagara.Rollback.WorldManagerRespectsWorldCreateFXSystem` | `(ref:WorldManagerRespectsWorldCreateFX...` | Ref | ECVF_Default | When true, Niagara world managers will only be created for worlds with... | `Niagara/Private/NiagaraWorldManager.cpp:62` |
| `fx.Niagara.SetEmitterDenyList` | `(ref:EmitterDenyListString)` | Ref | ECVF_Scalability | ECVF_Default | Set the emitter deny list to use. (i.e. NS_SystemA:EmitterA,NS_SystemB:EmitterA) | `Niagara/Private/NiagaraComponentSettings.cpp:138` |
| `fx.Niagara.SetOverridePlatformName` | `(command)` | Command | - | Sets which platform we should override with, no args means reset to default | `Niagara/Private/NiagaraPlatformSet.cpp:157` |
| `fx.Niagara.SetSystemDenyList` | `(ref:SystemDenyListString)` | Ref | ECVF_Scalability | ECVF_Default | Set the system deny List to use. (i.e. NS_SystemA,NS_SystemB) | `Niagara/Private/NiagaraComponentSettings.cpp:131` |
| `fx.Niagara.Shader.EnableHLSL2021` | `(ref:GNiagaraEnableHLSL2021)` | Ref | - | Enable HLSL 2021 compilation flag. | `NiagaraShader/Private/NiagaraShader.cpp:56` |
| `fx.Niagara.Shader.ForceBindEverything` | `(ref:GNiagaraShaderForceBindEverything)` | Ref | - | Forces Niagara to display errors about missing shader bindings. | `NiagaraShader/Private/NiagaraShader.cpp:49` |
| `fx.Niagara.ShowAllocationWarnings` | `(ref:GbNiagaraShowAllocationWarnings)` | Ref | ECVF_Default | If not 0 then frequent reallocations and over-allocations of particle memory will cause... | `Niagara/Private/NiagaraEmitterInstanceImpl.cpp:55` |
| `fx.Niagara.SocketReaderDI.DisableTransformReadType` | `(ref:GDisableTransformReadType)` | Ref | ECVF_Default | Disables optimization around removing reading transforms that we don't consume. | `Private/DataInterface/NiagaraDataInterfaceSocketReader.cpp:33` |
| `fx.Niagara.StripByteCodeOverride` | `(ref:GNiagaraStripByteCodeOverride)` | Ref | ECVF_Default | Overrides project settings to strip byte code from the script on load.. | `Niagara/Private/NiagaraScript.cpp:124` |
| `fx.Niagara.SystemSimulation.AllowASync` | `(ref:GNiagaraSystemSimulationAllowASync)` | Ref | ECVF_Default | If > 0, system simulation tick is parallelized. | `Niagara/Private/NiagaraSystemSimulation.cpp:79` |
| `fx.Niagara.SystemSimulation.TaskStallTimeout` | `(ref:GNiagaraSystemSimulationTaskStall...` | Ref | ECVF_Default | Timeout in microseconds for Niagara simulation tasks to be considered stalled. | `Niagara/Private/NiagaraSystemSimulation.cpp:95` |
| `fx.Niagara.TaskPriorities.NoneOverlappingPriority` | `(ref:GNoneOverlappingPriority)` | Ref | ECVF_Default | Priority to use when we are not allowed to overlap tick groups. | `Niagara/Private/NiagaraSimulationTaskPriority.cpp:31` |
| `fx.Niagara.TaskPriorities.RunTest` | `(command)` | Command | - | Run a test set of priorites | `Niagara/Private/NiagaraSimulationTaskPriority.cpp:118` |
| `fx.Niagara.UI.Distribution.UseCompactEditor` | `(ref:GUseCompactEditor)` | Ref | - | When enabled we use the compact editor vs the curve editor. | `Private/Widgets/SNiagaraDistributionEditor.cpp:32` |
| `fx.Niagara.VertexFactoryExport.EnabledMode` | `1` | int32 | ECVF_ReadOnly | ECVF_RenderThreadSafe | Determins compilation mode for vertex factory export shader permutations | `NiagaraVertexFactories/Private/NiagaraVertexFactoryExport.cpp:6` |
| `fx.Niagara.WaitOnPreGC` | `(ref:GNiagaraWaitOnPreGC)` | Ref | ECVF_Default | Toggles whether Niagara will wait for all async tasks to complete before any GC calls. | `Niagara/Private/NiagaraWorldManager.cpp:98` |
| `fx.NiagaraComponentsEnabled` | `(ref:GbComponentsEnabled)` | Ref | ECVF_Default | If false Niagara particle components will not be activated. | `Niagara/Private/NiagaraComponent.cpp:68` |
| `fx.NiagaraDataBufferMinSize` | `(ref:GNiagaraDataBufferMinSize)` | Ref | ECVF_Default | Niagara data buffer minimum allocation size in bytes (Default=512). | `Niagara/Private/NiagaraDataSet.cpp:54` |
| `fx.NiagaraDataBufferShrinkFactor` | `(ref:GNiagaraDataBufferShrinkFactor)` | Ref | ECVF_Default | Niagara data buffer size threshold for shrinking. (Default=3) | `Niagara/Private/NiagaraDataSet.cpp:62` |
| `fx.NiagaraEnablePrecompilerNamespaceDatasetCulling` | `(ref:GNiagaraForcePrecompilerCullDatas...` | Ref | ECVF_Default | Force the namespace fixup precompiler process to cull unused Dataset parameters. Only... | `NiagaraEditor/Private/NiagaraParameterMapHistory.cpp:42` |
| `fx.NiagaraEnablePrecompilerNamespaceFixup` | `(ref:GNiagaraEnablePrecompilerNamespac...` | Ref | ECVF_Default | Enable a precompiler stage to discover parameter name matches and convert matched... | `NiagaraEditor/Private/NiagaraCompiler.cpp:84` |
| `fx.NiagaraGlobalSystemCountScale` | `(ref:INiagaraModule::EngineGlobalSyste...` | Ref | ECVF_Scalability | A global scale on system count thresholds for culling in Niagara. | `Niagara/Private/NiagaraModule.cpp:122` |
| `fx.NiagaraLogNamespaceFixup` | `(ref:GNiagaraLogNamespaceFixup)` | Ref | ECVF_Default | Log matched variables and pin name changes in precompile. | `NiagaraEditor/Private/NiagaraParameterMapHistory.cpp:34` |
| `fx.NiagaraMaxStatInstanceReports` | `(ref:GNiagaraMaxStatInstanceReports)` | Ref | ECVF_Default | The max number of different instances from which stat reports are aggregated. | `Niagara/Private/NiagaraCommon.cpp:59` |
| `fx.NiagaraPerfReporting` | `(ref:GbNiagaraPerfReporting)` | Ref | ECVF_Default | 0 = Disabled  1 = Text Perf Report on world Transitions.  2 = Text Report for every test... | `Niagara/Private/NiagaraPerfBaseline.cpp:43` |
| `fx.NiagaraRegenBaselinesOnWorldChange` | `(ref:GbNiagaraRegenerateBaselinesOnWor...` | Ref | ECVF_Default | If > 0 performance baselines for Niagara will be regenerated on every level change. | `Niagara/Private/NiagaraPerfBaseline.cpp:51` |
| `fx.NiagaraReleaseBuffersOnReset` | `(ref:GNiagaraReleaseBuffersOnReset)` | Ref | ECVF_Scalability | Will release all memory associated with data buffers when the dataset is reset. | `Niagara/Private/NiagaraDataSet.cpp:96` |
| `fx.NiagaraRuntimeCycleHistorySize` | `(ref:GNiagaraRuntimeCycleHistorySize)` | Ref | ECVF_ReadOnly | How many frames history to use in Niagara's runtime performance trackers. | `Niagara/Private/NiagaraEffectType.cpp:18` |
| `fx.NiagaraScriptStatTracking` | `(ref:GbNiagaraScriptStatTracking)` | Ref | ECVF_Default | If > 0 stats tracking operations will be compiled into Niagara Scripts. | `NiagaraEditor/Private/NiagaraHlslTranslator.cpp:4775` |
| `fx.NiagaraStateless.AllowTemplateCreation` | `(ref:GbAllowTemplateCreation)` | Ref | ECVF_Default | Allow experimental template creation.  Data may be lost. | `NiagaraEditor/Private/NiagaraStatelessEmitterTemplateFactoryNew.cpp:11` |
| `fx.NiagaraStateless.Distribution.OptimizeLUTs` | `(ref:GOptimizeLUTs)` | Ref | ECVF_Default | When enabled we optimize the LUT generation. | `Private/Stateless/NiagaraStatelessDistribution.cpp:13` |
| `fx.NiagaraStateless.Distribution.ReduceLUTTimeRange` | `(ref:GReduceLUTTimeRange)` | Ref | ECVF_Default | When LUT optimization is enabled we will try to reduce the start / end time if we get... | `Private/Stateless/NiagaraStatelessDistribution.cpp:21` |
| `fx.NiagaraStateless.ExpressionsEnabled` | `(ref:GNiagaraStatelessExpressionsEnabl...` | Ref | ECVF_Default | CVar to enable stateless expressions | `Private/Stateless/NiagaraStatelessExpressionTypeData.cpp:10` |
| `fx.NiagaraStateless.SolveVelocities.Noise.FrequencyLUTNormalize` | `(ref:GFrequencyLUTNormalize)` | Ref | ECVF_Default | Modifier applied when looking up from normalized total travel into the LUT. | `Stateless/Modules/NiagaraStatelessModule_SolveVelocitiesAndForces.cpp:23` |
| `fx.NiagaraStateless.SolveVelocities.Noise.FrequencyNormalize` | `(ref:GFrequencyNormalize)` | Ref | ECVF_Default | Translation from position -> lookup space. | `Stateless/Modules/NiagaraStatelessModule_SolveVelocitiesAndForces.cpp:15` |
| `fx.NiagaraStateless.UI.ShowRawObject` | `(ref:bShowRawObject)` | Ref | ECVF_Default | When enabled we will show the raw object in the stateless emitter UI. | `ViewModels/Stack/NiagaraStackStatelessEmitterGroup.cpp:24` |
| `fx.NiagaraVectorFieldUseIspc` | `(ref:GNiagaraVectorFieldUseIspc)` | Ref | ECVF_Default | When enabled VectorField will use ISPC for sampling if appropriate. | `Niagara/Private/NiagaraDataInterfaceVectorField.cpp:35` |
| `fx.NumFramesBetweenRuntimePerfSamples` | `(ref:GNumFramesBetweenRuntimePerfSampl...` | Ref | ECVF_ReadOnly | How many frames between each sample of Niagara runtime perf. | `Niagara/Private/NiagaraEffectType.cpp:15` |
| `fx.ParticleCollisionIgnoreInvisibleTime` | `(ref:GParticleCollisionIgnoreInvisible...` | Ref | ECVF_Default | The time a particle system component has to be invisible for to have all collision... | `Private/Particles/ParticleModules_Collision.cpp:174` |
| `fx.PerfBaselineThreshold_Bad` | `(ref:GPerfBaselineThreshold_Bad)` | Ref | ECVF_Default | Ratio to the baseline perf that we consider a system to have bad perf and warn strongly... | `Niagara/Private/NiagaraPerfBaseline.cpp:35` |
| `fx.PerfBaselineThreshold_Poor` | `(ref:GPerfBaselineThreshold_Poor)` | Ref | ECVF_Default | Ratio to the baseline perf that we consider a system to have poor perf and warn about it. | `Niagara/Private/NiagaraPerfBaseline.cpp:27` |
| `fx.RebuildDirtyScripts` | `(command)` | Command | - | Go through all loaded assets and force them to recompute their script hash. If dirty,... | `NiagaraEditor/Private/NiagaraEditorModule.cpp:1154` |
| `fx.ShowNiagaraDeveloperWindows` | `(ref:GbShowNiagaraDeveloperWindows)` | Ref | ECVF_Default | If > 0 the niagara system, emitter, and script editors will show additional developer... | `NiagaraEditor/Private/NiagaraEditorModule.cpp:213` |
| `fx.UseNewGraphHash` | `(ref:GNiagaraUseGraphHash)` | Ref | ECVF_Default | If > 0 a hash of the graph node state will be used, otherwise will use the older code... | `NiagaraEditor/Private/NiagaraGraph.cpp:62` |

### Compilation / VectorVM (22개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.ForceCompileOnLoad` | `(ref:GbForceNiagaraCompileOnLoad)` | Ref | ECVF_Default | If > 0 emitters will be forced to compile on load. | `Niagara/Private/NiagaraEmitter.cpp:49` |
| `fx.ForceNiagaraCompileToFail` | `(ref:GbForceNiagaraFailToCompile)` | Ref | ECVF_Default | If > 0 emitters will go through the motions of a compile, but will never set valid... | `Niagara/Private/NiagaraEmitter.cpp:65` |
| `fx.ForceNiagaraTranslatorDump` | `(ref:GbForceNiagaraTranslatorDump)` | Ref | ECVF_Default | If > 0 all translation generated HLSL will be dumped | `NiagaraEditor/Private/NiagaraCompiler.cpp:60` |
| `fx.ForceNiagaraTranslatorSingleThreaded` | `(ref:GbForceNiagaraTranslatorSingleThr...` | Ref | ECVF_Default | If > 0 all translation will occur one at a time, useful for debugging. | `NiagaraEditor/Private/NiagaraCompiler.cpp:51` |
| `fx.ForceNiagaraVMBinaryDump` | `(ref:GbForceNiagaraVMBinaryDump)` | Ref | ECVF_Default | If > 0 all translation generated binary text will be dumped | `NiagaraEditor/Private/NiagaraCompiler.cpp:68` |
| `fx.InvalidateCachedScripts` | `(command)` | Command | - | Invalidate Niagara script cache by making a unique change to NiagaraShaderVersion.ush... | `NiagaraEditor/Private/NiagaraEditorModule.cpp:1134` |
| `fx.LogCompileIdGeneration` | `(ref:FNiagaraCompileHashVisitor::LogCo...` | Ref | ECVF_Default | If > 0 all compile id generation will be logged. If 2 or greater, log detailed info. | `Niagara/Private/NiagaraModule.cpp:59` |
| `fx.LogCompileStaticVars` | `(ref:UNiagaraScript::LogCompileStaticV...` | Ref | ECVF_Default | If > 0 all compile id generation dealing with static variables will be logged. | `Niagara/Private/NiagaraScript.cpp:97` |
| `fx.Niagara.Compilation.MaxActiveTaskCount` | `(ref:GNiagaraCompilationMaxActiveTaskC...` | Ref | ECVF_Default | The maximum number of active Niagara system compilations that can be going concurrantly. | `NiagaraEditor/Private/NiagaraSystemCompilingManager.cpp:21` |
| `fx.Niagara.Compilation.StalledTaskWarningTime` | `(ref:GNiagaraCompilationStalledTaskWar...` | Ref | ECVF_Default | The length of time a task is being processed before warnings are generated. | `NiagaraEditor/Private/NiagaraSystemCompilingManager.cpp:29` |
| `fx.Niagara.CompileDDCWaitTimeout` | `(ref:GNiagaraCompileDDCWaitTimeout)` | Ref | ECVF_Default | During script compilation, how long do we wait for the ddc to answer in seconds before... | `Niagara/Private/NiagaraAsyncCompile.cpp:33` |
| `fx.Niagara.CompileDumpTimings` | `(ref:GNiagaraCompileDumpTimings)` | Ref | ECVF_ReadOnly | If enabled a file containing compile metrics for the different compiled scripts will be... | `Niagara/Private/NiagaraCompilationTypes.cpp:29` |
| `fx.Niagara.CompileHashAllDataInterfaces` | `(ref:GNiagaraCompileHashAllDataInterfa...` | Ref | ECVF_Default | Forces Niagara to include all data interfaces as part of compile hash generation. | `Niagara/Private/NiagaraScript.cpp:113` |
| `fx.Niagara.CompileValidateMode` | `(ref:GNiagaraCompileValidateMode)` | Ref | ECVF_Default | Controls how the validate compile mode will report differences it encounters when... | `Niagara/Private/NiagaraCompilationTypes.cpp:37` |
| `fx.Niagara.CompileWaitLoggingCap` | `(ref:GNiagaraCompileWaitLoggingTermina...` | Ref | ECVF_Default | During automation, how many times do we log before failing compilation? | `Niagara/Private/NiagaraSystem.cpp:189` |
| `fx.Niagara.CompileWaitLoggingThreshold` | `(ref:GNiagaraCompileWaitLoggingThresho...` | Ref | ECVF_Default | During automation, how long do we wait for a compile result before logging. | `Niagara/Private/NiagaraSystem.cpp:181` |
| `fx.Niagara.ForceWaitForCompilationOnActivate` | `(ref:GForceWaitForCompilationOnActivate)` | Ref | ECVF_Default | When a component is activated it will stall waiting for any pending shader compilation. | `Niagara/Private/NiagaraComponent.cpp:92` |
| `fx.Niagara.GpuScriptsCompiledBySystem` | `(ref:GNiagaraGpuScriptsCompiledBySystem)` | Ref | ECVF_Default | If true GPU shaders for Niagara scripts will be compiled along with the NiagaraSystem... | `Niagara/Private/NiagaraScript.cpp:135` |
| `fx.Niagara.MaxCompilePollTimePerFrame` | `(ref:GNiagaraMaxCompilePollTimePerFrame)` | Ref | ECVF_Default | When a lot of system compile tasks queue up, this is the max time per frame that is used... | `Niagara/Private/NiagaraModule.cpp:139` |
| `fx.Niagara.OnDemandCompileEnabled` | `(ref:GNiagaraOnDemandCompileEnabled)` | Ref | ECVF_Default | Compiles Niagara Systems on demand rather than on post load.  1 - Will defer when in... | `Niagara/Private/NiagaraSystem.cpp:205` |
| `fx.Niagara.ParseCompileMetaDataOnGet` | `(ref:GDebugParseCompileMetaDataOnGet)` | Ref | ECVF_Default | When true the compilation metadata from DDC will be parsed on get. | `NiagaraEditor/Private/NiagaraCompilationTasks.cpp:71` |
| `fx.SkipVectorVMBackendOptimizations` | `(ref:GNiagaraSkipVectorVMBackendOptimi...` | Ref | ECVF_Default | If 1, skip HLSLCC's backend optimization passes during VectorVM compilation. | `NiagaraShader/Private/NiagaraShader.cpp:41` |

### Solo Mode (디버깅) (1개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.ForceNiagaraSpawnAttachedSolo` | `(ref:GForceNiagaraSpawnAttachedSolo)` | Ref | ECVF_Default | If > 0 Niagara systems which are spawned attached will be force to spawn in solo mode for... | `Niagara/Private/NiagaraFunctionLibrary.cpp:41` |

### GPU Simulation (39개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.Cascade.GpuSpriteDynamicAllocations` | `(ref:GFXCascadeGpuSpriteAllowDynAllocs)` | Ref | ECVF_Default | Controls if gpu sprite are allocated dynamically | `Private/Particles/ParticleGpuSimulation.cpp:94` |
| `fx.Cascade.GpuSpriteRenderingEnabled` | `(ref:GFXCascadeGpuSpriteRenderingEnabl...` | Ref | ECVF_Default | Controls if gpu sprite rendering is enabled for Cascade | `Private/Particles/ParticleGpuSimulation.cpp:78` |
| `fx.GPUSimulationDynTextureSizeXY` | `(ref:GParticleSimulationDynTextureSize...` | Ref | ECVF_ReadOnly | GPU Particle simulation texture XY dimension when dynamic resizing is enabled (default=16) | `Private/Particles/ParticleGpuSimulation.cpp:86` |
| `fx.GPUSimulationTextureSizeX` | `(ref:GParticleSimulationTextureSizeX)` | Ref | - | (no help text) | `Private/Particles/ParticleGpuSimulation.cpp:62` |
| `fx.GPUSimulationTextureSizeY` | `(ref:GParticleSimulationTextureSizeY)` | Ref | - | (no help text) | `Private/Particles/ParticleGpuSimulation.cpp:70` |
| `fx.GPUSort.BufferSlack` | `(ref:GGPUSortBufferSlack)` | Ref | ECVF_Default | Slack ratio when resizing GPU sort buffers. Must be bigger than 1 (default=2) | `Engine/Private/GPUSortManager.cpp:35` |
| `fx.GPUSort.FrameCountBeforeShrinking` | `(ref:GGPUSortFrameCountBeforeBufferShr...` | Ref | ECVF_Default | Number of consecutive frames where the GPU sort buffer is considered oversized before... | `Engine/Private/GPUSortManager.cpp:19` |
| `fx.GPUSort.MinBufferSize` | `(ref:GGPUSortMinBufferSize)` | Ref | ECVF_Default | Minimum GPU sort buffer size, in particles (default=8192) | `Engine/Private/GPUSortManager.cpp:27` |
| `fx.GPUSort.StressTest` | `(ref:GGPUSortStressTest)` | Ref | ECVF_Cheat | Force a stress test on the GPU sort by release persistent data every frame (default=0) | `Engine/Private/GPUSortManager.cpp:43` |
| `fx.MaxNiagaraGPUParticlesSpawnPerFrame` | `(ref:GMaxNiagaraGPUParticlesSpawnPerFr...` | Ref | ECVF_Default | The max number of GPU particles we expect to spawn in a single frame. | `Niagara/Private/NiagaraEmitterInstanceImpl.cpp:75` |
| `fx.Niagara.AsyncGpuTrace.GlobalSdfEnabled` | `(ref:GNiagaraAsyncGpuTraceGsdfEnabled)` | Ref | ECVF_Default | If disabled AsyncGpuTrace will not be supported against Global SDF. | `NiagaraShader/Private/NiagaraAsyncGpuTraceProviderGsdf.cpp:18` |
| `fx.Niagara.AsyncGpuTrace.HWRayTrace.Inline` | `(ref:GNiagaraAsyncGpuTraceHwrtInline)` | Ref | ECVF_Default | If disabled AsyncGpuTrace will not be supported against the HW ray tracing scene. | `NiagaraShader/Private/NiagaraAsyncGpuTraceProviderHwrt.cpp:32` |
| `fx.Niagara.AsyncGpuTrace.HWRayTraceEnabled` | `(ref:GNiagaraAsyncGpuTraceHwrtEnabled)` | Ref | ECVF_Default | If disabled AsyncGpuTrace will not be supported against the HW ray tracing scene. | `NiagaraShader/Private/NiagaraAsyncGpuTraceProviderHwrt.cpp:24` |
| `fx.Niagara.Batcher.TickFlush.MaxPendingTicks` | `(ref:GTickFlushMaxPendingTicks)` | Ref | ECVF_Default | The maximum number of unprocess ticks before we process them. | `Niagara/Private/NiagaraGpuComputeDispatch.cpp:113` |
| `fx.Niagara.Batcher.TickFlush.MaxQueuedFrames` | `(ref:GTickFlushMaxQueuedFrames)` | Ref | ECVF_Default | The number of unprocessed frames with queued ticks before we process them. | `Niagara/Private/NiagaraGpuComputeDispatch.cpp:104` |
| `fx.Niagara.Batcher.TickFlush.Mode` | `(ref:GTickFlushMode)` | Ref | ECVF_Default | What to do when we go over our max queued frames. | `Niagara/Private/NiagaraGpuComputeDispatch.cpp:122` |
| `fx.Niagara.Emitter.ComputePSOPrecacheMode` | `(ref:GNiagaraEmitterComputePSOPrecache...` | Ref | ECVF_Scalability | Controlls how PSO precaching should be done for Niagara compute shaders | `Niagara/Private/NiagaraEmitter.cpp:81` |
| `fx.Niagara.Emitter.MaxGPUBufferElements` | `(ref:GNiagaraEmitterMaxGPUBufferElemen...` | Ref | - | Maximum elements per GPU buffer, for example 4k elements would restrict a float buffer to... | `Niagara/Private/NiagaraEmitter.cpp:93` |
| `fx.Niagara.GpuEmitterCheckFloat16Support` | `(ref:GGpuEmitterCheckFloat16Support)` | Ref | ECVF_Scalability | ECVF_Default | When enabled we check to see if the RHI has support for Float16 UAV read / write, if it... | `Niagara/Private/NiagaraComponentSettings.cpp:187` |
| `fx.Niagara.GpuProfiling.Enabled` | `(ref:GNiagaraGpuProfilingEnabled)` | Ref | ECVF_Default | Primary control to allow Niagara to use GPU profiling or not. | `Niagara/Private/NiagaraGPUProfiler.cpp:8` |
| `fx.Niagara.NDIExport.GPUMaxReadbackCount` | `(ref:GGPUMaxReadbackCount)` | Ref | ECVF_Default | Maximum buffer instance count for the GPU readback when in PerParticleMode, where <= 0... | `Niagara/Private/NiagaraDataInterfaceExport.cpp:38` |
| `fx.Niagara.SetGpuDataInterfaceDenyList` | `(ref:GpuDataInterfaceDenyListString)` | Ref | ECVF_Scalability | ECVF_Default | Set the Gpu data interface deny list to use.  (i.e. UMyDataInteraceA,UMyDataInteraceB) | `Niagara/Private/NiagaraComponentSettings.cpp:152` |
| `fx.Niagara.SetGpuDenyList` | `(ref:GpuDenyListString)` | Ref | ECVF_Scalability | ECVF_Default | Set Gpu deny list to use, more targetted than to allow comparing OS,OSVersion,CPU,GPU. | `Niagara/Private/NiagaraComponentSettings.cpp:175` |
| `fx.Niagara.SetGpuEmitterDenyList` | `(ref:GpuEmitterDenyListString)` | Ref | ECVF_Scalability | ECVF_Default | Set the Gpu emitter deny list to use. (i.e. NS_SystemA:EmitterA,NS_SystemB:EmitterA) | `Niagara/Private/NiagaraComponentSettings.cpp:145` |
| `fx.Niagara.SetGpuRHIAdapterDenyList` | `(ref:GpuRHIAdapterDenyListString)` | Ref | ECVF_Scalability | ECVF_Default | Set Gpu RHI Adapter deny list to use, comma separated and uses wildcards, i.e. (*MyGpu*)... | `Niagara/Private/NiagaraComponentSettings.cpp:167` |
| `fx.Niagara.SetGpuRHIDenyList` | `(ref:GpuRHIDenyListString)` | Ref | ECVF_Scalability | ECVF_Default | Set Gpu RHI deny list to use, comma separated and uses wildcards, i.e. (*MyRHI*) would... | `Niagara/Private/NiagaraComponentSettings.cpp:159` |
| `fx.Niagara.SystemSimulation.BatchGPUTickSubmit` | `(ref:GNiagaraSystemSimulationBatchGPUT...` | Ref | ECVF_Default | The if non zero we allow GPU Ticks to be submitted to the Render Thread in batches. | `Niagara/Private/NiagaraSystemSimulation.cpp:131` |
| `fx.Niagara.SystemSimulation.ConcurrentGPUTickInit` | `(ref:GNiagaraSystemSimulationConcurren...` | Ref | ECVF_Default | The if non zero we allow GPU Ticks to be initialized in the System's concurrent tick... | `Niagara/Private/NiagaraSystemSimulation.cpp:123` |
| `fx.NiagaraAllowComputeShaders` | `(ref:GNiagaraAllowComputeShaders)` | Ref | ECVF_Default | If true, allow the usage compute shaders within Niagara. | `Niagara/Private/NiagaraCommon.cpp:35` |
| `fx.NiagaraAllowGPUParticles` | `(ref:GNiagaraAllowGPUParticles)` | Ref | ECVF_Scalability | ECVF_Default | If true, allow the usage of GPU particles for Niagara. | `Niagara/Private/NiagaraCommon.cpp:43` |
| `fx.NiagaraBatcher.FreeBufferEarly` | `(ref:GNiagaraBatcherFreeBufferEarly)` | Ref | ECVF_Default | Will take the path to release GPU buffers when possible. | `Niagara/Private/NiagaraGpuComputeDispatch.cpp:81` |
| `fx.NiagaraGPUDataBufferChunkSize` | `(ref:GNiagaraGPUDataBufferChunkSize)` | Ref | ECVF_Default | Niagara GPU data buffer allocation chunk size used to round GPU allocations in bytes,... | `Niagara/Private/NiagaraDataSet.cpp:71` |
| `fx.NiagaraGPUDataBufferShrinkFactor` | `(ref:GNiagaraGPUDataBufferShrinkFactor)` | Ref | ECVF_Default | Niagara GPU data buffer size threshold for shrinking. (Default=2) | `Niagara/Private/NiagaraDataSet.cpp:79` |
| `fx.NiagaraGPUDataWarningSize` | `(ref:GNiagaraGPUDataWarningSize)` | Ref | ECVF_Scalability | Allocation size where we should log a warning. | `Niagara/Private/NiagaraDataSet.cpp:88` |
| `fx.NiagaraGpuLowLatencyTranslucencyEnabled` | `(ref:GNiagaraGpuLowLatencyTranslucency...` | Ref | ECVF_Default | When enabled translucent materials can use the current frames simulation data no matter... | `Niagara/Private/NiagaraGpuComputeDispatch.cpp:72` |
| `fx.NiagaraGpuSubmitCommandHint` | `(ref:GNiagaraGpuSubmitCommandHint)` | Ref | ECVF_Default | If greater than zero, we use this value to submit commands after the number of dispatches... | `Niagara/Private/NiagaraGpuComputeDispatch.cpp:64` |
| `fx.NiagaraOptimizeCrossGPUTransfer` | `(ref:GNiagaraOptimizedCrossGPUTransfer...` | Ref | ECVF_Default | Optimizes fence waits for cross GPU transfers when rendering views on multiple GPUs via... | `Niagara/Private/NiagaraGpuComputeDispatch.cpp:91` |
| `fx.NiagaraStateless.ComputeManager.CPUThreshold` | `(ref:GParticleCountCPUThreshold)` | Ref | ECVF_Default | When lower than this particle count prefer to use the CPU over dispatching a compute... | `Private/Stateless/NiagaraStatelessComputeManager.cpp:49` |
| `fx.NiagaraStateless.ComputeManager.UseCache` | `(ref:GUseDataBufferCache)` | Ref | ECVF_Default | When enabled we will attempt to reuse allocated buffers between frames. | `Private/Stateless/NiagaraStatelessComputeManager.cpp:41` |

### GPU Sort (0개)

(없음)

### DataChannels (NDC) (18개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.Niagara.DataChannels.AllowAsyncLoad` | `(ref:AllowAsyncLoad)` | Ref | ECVF_Default | True if we should attempt to load systems etc asynchronosly. | `Niagara/Private/NiagaraDataChannel_Islands.cpp:24` |
| `fx.Niagara.DataChannels.AllowLazyHandlerInit` | `(ref:GNDCAllowLazyHandlerInit)` | Ref | ECVF_Default | True if we allow lazy initialization of NDC handlers. | `Niagara/Private/NiagaraDataChannelManager.cpp:17` |
| `fx.Niagara.DataChannels.AutoUploadGPUSpawnData` | `(ref:AutoUploadGPUSpawnData)` | Ref | ECVF_Default | When true we will automatically upload any CPU NDC data to the GPU if it has been used to... | `Niagara/Private/NiagaraDataChannelData.cpp:23` |
| `fx.Niagara.DataChannels.BlockAsyncLoadOnUse` | `(ref:BlockAsyncLoadOnUse)` | Ref | ECVF_Default | True if we should block on any pending async loads when those assets are used. | `Niagara/Private/NiagaraDataChannel_Islands.cpp:27` |
| `fx.Niagara.DataChannels.EnableAccumulatedWrites` | `(ref:EnableAccumulatedWrites)` | Ref | ECVF_Default | True if we attempt to accumulate writes into larger shared buffers. | `Niagara/Private/NiagaraDataChannelData.cpp:26` |
| `fx.Niagara.DataChannels.Enabled` | `(ref:INiagaraModule::bDataChannelsEnab...` | Ref | ECVF_Default | If true, Niagara Data Channels will be enabled. | `Niagara/Private/NiagaraModule.cpp:158` |
| `fx.Niagara.DataChannels.ForceReadPrevFrame` | `(ref:GNDCReadForcePrevFrame)` | Ref | ECVF_Default | When true this will force Niagara systems with NDC read DIs to read from the previous... | `Private/DataInterface/NiagaraDataInterfaceDataChannelRead.cpp:59` |
| `fx.Niagara.DataChannels.ForceReadTickGroup` | `(ref:GNDCReadForceTG)` | Ref | ECVF_Default | When >= 0 this will force Niagara systems with NDC read DIs to tick in the given Tick... | `Private/DataInterface/NiagaraDataInterfaceDataChannelRead.cpp:51` |
| `fx.Niagara.DataChannels.FrameDataToCapture` | `(ref:FrameDataToCapture)` | Ref | ECVF_Default | The number of frames the debugger will capture for write requests. | `Niagara/Private/NiagaraDataChannelDebugUtilities.cpp:27` |
| `fx.Niagara.DataChannels.LogWritesToOutputLog` | `(ref:LogWritesToOutputLog)` | Ref | ECVF_Default | 0=Disabled, 1=Log write summary, 2=Also write data; If >0, the NDC debugger will print... | `Niagara/Private/NiagaraDataChannelDebugUtilities.cpp:24` |
| `fx.Niagara.DataChannels.MissingNDCAccessorMode` | `(ref:MissingNDCAccessorMode)` | Ref | ECVF_Default | Controls validation behavior for missing NDC Variabls being accessed from code. 0=Silent,... | `Niagara/Private/NiagaraDataChannelAccessor.cpp:23` |
| `fx.Niagara.DataChannels.NDCMapBase.FreeUnusedTime` | `(ref:EntryPoolUnusedCleanTime)` | Ref | ECVF_Default | Time in seconds we keep unused entires in the pool. | `Niagara/Private/NiagaraDataChannel_Map.cpp:21` |
| `fx.Niagara.DataChannels.NDCMapBase.InitialSize` | `(ref:EntryPoolInitialSize)` | Ref | ECVF_Default | The initial size of the entry pool for NDC Map types. | `Niagara/Private/NiagaraDataChannel_Map.cpp:18` |
| `fx.Niagara.DataChannels.ResetLayoutInfo` | `(command)` | Command | - | Resets all data channel layout info used by data interfaces to access data channels. | `Private/DataInterface/NiagaraDataInterfaceDataChannelCommon.cpp:13` |
| `fx.Niagara.DataChannels.WarnOnLateWrites` | `(ref:bEmitWarningsOnLateNDCWrites)` | Ref | ECVF_Default | If true, late writes to NDCs will generate warnings. Late meaning after their final... | `Niagara/Private/NiagaraDataChannelData.cpp:20` |
| `fx.Niagara.DataChannels.WriteDIZeroCPUBuffersMode` | `(ref:GbNDCWriteDIZeroCPUBufferMode)` | Ref | ECVF_Default | Controls how CPU buffers are zeroed for the NDC Write DI 0 = Do not Zero CPU buffers. 1 =... | `Private/DataInterface/NiagaraDataInterfaceDataChannelWrite.cpp:59` |
| `fx.Niagara.Rollback.DataChannels.RetainGPUDataIfPendingCpuUpdate` | `(ref:bRetainGPUDataIfPendingCpuUpdate)` | Ref | ECVF_Default | ECVF_RenderThreadSafe | If true, NDC data for the GPU will be kept if there has been no update from the CPU.... | `Niagara/Private/NiagaraDataChannelData.cpp:34` |
| `fx.Niagara.Rollback.DelayNDCManagerInitialiation` | `(ref:DelayNDCManagerInitialiation)` | Ref | ECVF_Default | When true, Niagara will not initialize it's NDC managers until the first tick of the... | `Niagara/Private/NiagaraWorldManager.cpp:73` |

### Memory / Pooling (19개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.DetailedCSVStats.MemoryMode` | `(ref:GFXDetailedCSVMemoryMode)` | Ref | ECVF_Default | Gathers approximate memory information depending on the mode. | `Private/Particles/ParticlePerfStats.cpp:1164` |
| `fx.Niagara.AllowPrimedPools` | `(ref:GNigaraAllowPrimedPools)` | Ref | ECVF_Default | Allow Niagara pools to be primed. | `Niagara/Private/NiagaraWorldManager.cpp:114` |
| `fx.Niagara.ComponentRenderPoolInactiveTimeLimit` | `(ref:GNiagaraComponentRenderPoolInacti...` | Ref | ECVF_Default | The time in seconds an inactive component can linger in the pool before being destroyed. | `Niagara/Private/NiagaraRendererComponents.cpp:32` |
| `fx.Niagara.DigestGraphCacheSize` | `(ref:GDigestGraphCacheSize)` | Ref | ECVF_ReadOnly | Defines the size of the cache for digested Niagara graphs. | `NiagaraEditor/Private/NiagaraDigestDatabase.cpp:19` |
| `fx.Niagara.EnableTraversalCache` | `(ref:GbNiagaraEnableTraversalCache)` | Ref | ECVF_Default | If > 0 the new traversal cache will be used to speed up utilities like... | `NiagaraShader/Private/NiagaraShared.cpp:47` |
| `fx.Niagara.GraphDataCacheSize` | `(ref:GNiagaraGraphDataCacheSize)` | Ref | ECVF_ReadOnly | Maximum number of elements to store within the GraphDataCache. | `NiagaraEditor/Private/NiagaraGraphDataCache.cpp:10` |
| `fx.Niagara.GraphDataCacheValidation` | `(ref:GNiagaraGraphDataCacheValidation)` | Ref | ECVF_Default | If true will perform validation on retrieving data from the data FNiagaraGraphDataCache. | `NiagaraEditor/Private/NiagaraGraphDataCache.cpp:18` |
| `fx.Niagara.IndirectArgsPool.AllowShrinking` | `(ref:GNiagaraIndirectArgsPoolAllowShri...` | Ref | ECVF_Default | Allow the indirect args pool to shrink after a number of frames below a low water mark. | `Niagara/Private/NiagaraGPUInstanceCountManager.cpp:65` |
| `fx.Niagara.IndirectArgsPool.BlockSizeFactor` | `(ref:GNiagaraIndirectArgsPoolBlockSize...` | Ref | ECVF_Default | Multiplier on the indirect args pool size when needing to increase it from running out of... | `Niagara/Private/NiagaraGPUInstanceCountManager.cpp:57` |
| `fx.Niagara.IndirectArgsPool.LowWaterAmount` | `(ref:GNiagaraIndirectArgsPoolLowWaterA...` | Ref | ECVF_Default | Percentage (0-1) of the indirect args pool that is considered low and worthy of shrinking | `Niagara/Private/NiagaraGPUInstanceCountManager.cpp:73` |
| `fx.Niagara.IndirectArgsPool.LowWaterFrames` | `(ref:GNiagaraIndirectArgsPoolLowWaterF...` | Ref | ECVF_Default | The number of frames to wait to shrink the indirect args pool for being below the low... | `Niagara/Private/NiagaraGPUInstanceCountManager.cpp:81` |
| `fx.Niagara.IndirectArgsPool.MinSize` | `(ref:GNiagaraIndirectArgsPoolMinSize)` | Ref | ECVF_Default | Minimum number of draw indirect args allocated into the pool. (default=256) | `Niagara/Private/NiagaraGPUInstanceCountManager.cpp:49` |
| `fx.Niagara.RenderTarget2D.SimCacheCompressed` | `(ref:GSimCacheCompressed)` | Ref | ECVF_Default | When enabled compression is used for the sim cache data. | `Niagara/Private/NiagaraDataInterfaceRenderTarget2D.cpp:28` |
| `fx.Niagara.RenderTargetVolume.SimCacheCompressed` | `(ref:GSimCacheCompressed)` | Ref | ECVF_Default | When enabled compression is used for the sim cache data. | `Niagara/Private/NiagaraDataInterfaceRenderTargetVolume.cpp:89` |
| `fx.Niagara.RenderTargetVolume.SimCacheDataStorageMode` | `(ref:GSimCacheDataStorageMode)` | Ref | ECVF_Default | Backing storage type for Volume RT sim cache data.  0 uses raw data, 1 uses OpenVDB, 2... | `Niagara/Private/NiagaraDataInterfaceRenderTargetVolume.cpp:103` |
| `fx.Niagara.RenderTargetVolume.SimCacheEnabled` | `(ref:GSimCacheEnabled)` | Ref | ECVF_Default | When enabled we can write data into the simulation cache. | `Niagara/Private/NiagaraDataInterfaceRenderTargetVolume.cpp:81` |
| `fx.Niagara.RenderTargetVolume.SimCacheUseOpenVDBFloatGrids` | `(ref:GSimCacheUseOpenVDBFloatGrids)` | Ref | ECVF_Default | Use OpenVDB float grids as output. | `Niagara/Private/NiagaraDataInterfaceRenderTargetVolume.cpp:113` |
| `fx.Niagara.SystemSimulation.AllowASyncSimCache` | `(ref:GNiagaraSystemSimulationAllowASyn...` | Ref | ECVF_Default | If > 0, sim cache tick is parallelized. | `Niagara/Private/NiagaraSystemSimulation.cpp:87` |
| `fx.Niagara.WorldManager.ObjectPoolEnabled` | `(ref:GNiagaraWorldManagerObjectPoolEna...` | Ref | ECVF_Default | Should we pool objects, yay or nay. | `Niagara/Private/NiagaraWorldManager.cpp:90` |

### Async Tick / Threading (4개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.Niagara.AsyncTrace.CountsScratchPadBucketSize` | `(ref:GNiagaraAsyncTraceCountsScratchBu...` | Ref | ECVF_Default | Scratch bucket size for the async gpu trace counts buffer. This buffer requires 4. | `Niagara/Private/NiagaraAsyncGpuTraceHelper.cpp:22` |
| `fx.Niagara.AsyncTrace.ScratchPadBucketSize` | `(ref:GNiagaraAsyncTraceScratchBucketSi...` | Ref | ECVF_Default | Size (in elements) for async gpu traces scratch buffer buckets. | `Niagara/Private/NiagaraAsyncGpuTraceHelper.cpp:14` |
| `fx.ParticleManagerAsyncBatchSize` | `(ref:GParticleManagerAsyncBatchSize)` | Ref | ECVF_Scalability | How many PSCs the ParticleWorldManager should tick per async task. | `Private/Particles/ParticleSystemManager.cpp:32` |
| `fx.WaitForAsyncStallWarnThresholdMS` | `(ref:GWaitForAsyncStallWarnThresholdMS)` | Ref | ECVF_Default | If we stall in WaitForAsync for longer than this threshold then we emit a stall warning... | `Niagara/Private/NiagaraSystemInstance.cpp:50` |

### Debug / Logging (51개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.Budget.Debug.GameThreadConcurrentTimeOverride` | `(ref:GFXTimeOverride_GameThreadConcurr...` | Ref | ECVF_Default | When >= 0.0 overrides the reported time for FX on the GameThreadConcurrent. Useful for... | `Private/Particles/FXBudget.cpp:53` |
| `fx.Budget.Debug.GameThreadTimeOverride` | `(ref:GFXTimeOverride_GameThread)` | Ref | ECVF_Default | When >= 0.0 overrides the reported time for FX on the GameThread. Useful for... | `Private/Particles/FXBudget.cpp:45` |
| `fx.Budget.Debug.RenderThreadTimeOverride` | `(ref:GFXTimeOverride_RenderThread)` | Ref | ECVF_Default | When >= 0.0 overrides the reported time for FX on the RenderThread. Useful for... | `Private/Particles/FXBudget.cpp:61` |
| `fx.DumpGraphKeyGen` | `(ref:GNiagaraDumpKeyGen)` | Ref | ECVF_Default | If > 0 the key generation will be dumped to the log. | `Niagara/Private/NiagaraScript.cpp:73` |
| `fx.DumpNiagaraScalabilityState` | `(command)` | Command | - | Dumps state information for all Niagara Scalability Mangers. | `Niagara/Private/NiagaraWorldManager.cpp:2641` |
| `fx.DumpPSCPoolInfo` | `(command)` | Command | - | Dump Particle System Pooling Info | `Private/Particles/WorldPSCPool.cpp:397` |
| `fx.DumpPSCTickStateInfo` | `(command)` | Command | - | Dumps state information for all current Particle System Components. | `Private/Particles/ParticleSystemComponent.cpp:5511` |
| `fx.DumpParticleData` | `(ref:GbDumpParticleData)` | Ref | ECVF_Default | If > 0 current frame particle data will be dumped after simulation. | `Niagara/Private/NiagaraEmitterInstanceImpl.cpp:31` |
| `fx.DumpParticleParameterStores` | `(ref:GbDumpParticleParameterStores)` | Ref | ECVF_Default | If > 0 current frame particle parameter stores will be dumped when updated. | `Niagara/Private/NiagaraParameterStore.cpp:19` |
| `fx.DumpSystemData` | `(ref:GbDumpSystemData)` | Ref | ECVF_Default | If > 0, results of system simulations will be dumped to the log. | `Niagara/Private/NiagaraSystemSimulation.cpp:63` |
| `fx.EnableCircularAnimTrailDump` | `(ref:GbEnableCircularAnimTrailDump)` | Ref | ECVF_Default | Controls logging for when circular links are discovered in anim trails. 0 = No logging. 1... | `Private/Particles/ParticleTrail2EmitterInstance.cpp:4306` |
| `fx.EnableEmitterMergeChangeIdLogging` | `(ref:GbEnableEmitterChangeIdMergeLoggi...` | Ref | ECVF_Default | If > 0 verbose change id information will be logged to help with debuggin merge issues. | `Niagara/Private/NiagaraEmitter.cpp:73` |
| `fx.EnableVerboseNiagaraChangeIdLogging` | `(ref:GEnableVerboseNiagaraChangeIdLogg...` | Ref | ECVF_Default | If > 0 Verbose change id logging info will be printed. | `Niagara/Private/NiagaraModule.cpp:115` |
| `fx.ForceNiagaraCacheDump` | `(ref:GbForceNiagaraCacheDump)` | Ref | ECVF_Default | If > 0 all cached graph traversal data will be dumped | `NiagaraEditor/Private/NiagaraCompiler.cpp:76` |
| `fx.Niagara.Array.PositionDebugRadius` | `(ref:GNDIArrayPositionDebugRadius)` | Ref | ECVF_Default | When using the Niagara Debugger the radius of position array debug display | `Niagara/Private/NiagaraDataInterfaceArrayFloat.cpp:14` |
| `fx.Niagara.Batcher.DebugLogging` | `(ref:GDebugLogging)` | Ref | ECVF_Default | Enables a lot of spew to the log to debug the batcher. | `Niagara/Private/NiagaraGpuComputeDispatch.cpp:136` |
| `fx.Niagara.Batcher.DumpSortedSimulations` | `(ref:GDumpSortedSimulations)` | Ref | ECVF_Default | Will dump sorted simulations to the log for the provided number of frames. | `Niagara/Private/NiagaraGpuComputeDispatch.cpp:146` |
| `fx.Niagara.DataChannels.DebugDumpWriterDI` | `(ref:GbDebugDumpWriter)` | Ref | ECVF_Default |  | `Private/DataInterface/NiagaraDataInterfaceDataChannelWrite.cpp:51` |
| `fx.Niagara.DataChannels.DumpHandlerTick` | `(ref:GbDebugDumpDumpHandlerTick)` | Ref | ECVF_Default |  | `Niagara/Private/NiagaraDataChannel_Global.cpp:12` |
| `fx.Niagara.DataChannels.DumpWriteLog` | `(command)` | Command | - | Dump all the currently stored writes to the log (see... | `Niagara/Private/NiagaraDataChannelDebugUtilities.cpp:30` |
| `fx.Niagara.Debug.GlobalLoopTime` | `(ref:GWorldLoopTime)` | Ref | ECVF_Default | If > 0 all Niagara FX will reset every N seconds. | `Niagara/Private/NiagaraWorldManager.cpp:179` |
| `fx.Niagara.Debug.Hud` | `(command)` | Command | - | Set options for debug hud display | `Niagara/Private/NiagaraDebugHud.cpp:200` |
| `fx.Niagara.Debug.KillSpawned` | `(command)` | Command | - | Kills all spawned compoonents | `Niagara/Private/NiagaraDebugHud.cpp:327` |
| `fx.Niagara.Debug.PlaybackMode` | `(command)` | Command | - | Set playback mode | `Niagara/Private/NiagaraWorldManager.cpp:202` |
| `fx.Niagara.Debug.PlaybackRate` | `(command)` | Command | - | Set playback rate | `Niagara/Private/NiagaraWorldManager.cpp:227` |
| `fx.Niagara.Debug.SpawnComponent` | `(command)` | Command | - | Spawns a NiagaraComponent using the given parameters | `Niagara/Private/NiagaraDebugHud.cpp:239` |
| `fx.Niagara.DebugDraw.Enabled` | `(ref:GNiagaraDebugDrawEnabled)` | Ref | ECVF_Default | Enable or disable the Debug Draw Data Interface, note does not fully disable the overhead. | `Private/DataInterface/NiagaraDataInterfaceDebugDraw.cpp:1470` |
| `fx.Niagara.DumpComponents` | `(command)` | Command | - | Dump Information about all Niagara Components | `Niagara/Private/NiagaraComponent.cpp:121` |
| `fx.Niagara.DumpNans` | `(ref:GbNiagaraDumpNans)` | Ref | ECVF_Default | If not 0 any NaNs will be dumped always. | `Niagara/Private/NiagaraEmitterInstanceImpl.cpp:39` |
| `fx.Niagara.DumpNansOnce` | `(ref:GbNiagaraDumpNansOnce)` | Ref | ECVF_Default | If not 0 any NaNs will be dumped for the first emitter that encounters NaNs. | `Niagara/Private/NiagaraEmitterInstanceImpl.cpp:47` |
| `fx.Niagara.GpuComputeDebug.DrawDebugEnabled` | `(ref:GNiagaraGpuComputeDebug_DrawDebug...` | Ref | ECVF_Default | Should we draw any of the debug information or not. | `Niagara/Private/NiagaraGpuComputeDebug.cpp:40` |
| `fx.Niagara.GpuComputeDebug.FourComponentMode` | `(ref:GNiagaraGpuComputeDebug_FourCompo...` | Ref | ECVF_Default | Adjust how we visualize four component types | `NiagaraShader/Private/NiagaraDebugShaders.cpp:25` |
| `fx.Niagara.GpuComputeDebug.MaxLineInstances` | `(ref:GNiagaraGpuComputeDebug_MaxLineIn...` | Ref | ECVF_Default | Maximum number of line draw we support in a single frame. | `Niagara/Private/NiagaraGpuComputeDebug.cpp:32` |
| `fx.Niagara.GpuComputeDebug.MaxTextureHeight` | `(ref:GNiagaraGpuComputeDebug_MaxTextur...` | Ref | ECVF_Default | The maximum height we will visualize a texture at, this is to avoid things becoming too... | `Niagara/Private/NiagaraGpuComputeDebug.cpp:24` |
| `fx.Niagara.GpuComputeDebug.MinTextureHeight` | `(ref:GNiagaraGpuComputeDebug_MinTextur...` | Ref | ECVF_Default | The minimum height we will visualize a texture at, smaller textures will be scaled up to... | `Niagara/Private/NiagaraGpuComputeDebug.cpp:16` |
| `fx.Niagara.GpuComputeDebug.OccludedLineColorScale` | `(ref:GNiagaraGpuComputeDebug_OccludedL...` | Ref | ECVF_Default | Scalar value to adjust occluded lines, where 0 means transparent and 1 is opaque. ... | `NiagaraShader/Private/NiagaraDebugShaders.cpp:35` |
| `fx.Niagara.GpuComputeDebug.ShowNaNInf` | `(ref:GNiagaraGpuComputeDebug_ShowNaNInf)` | Ref | ECVF_Default | When enabled will show NaNs as flashing colors. | `NiagaraShader/Private/NiagaraDebugShaders.cpp:17` |
| `fx.Niagara.LeakDetector.DebugMessageTime` | `(ref:GDebugMessageTime)` | Ref | ECVF_Default | Time we display the debug message for on screen. | `Niagara/Private/NiagaraComponentLeakDetector.cpp:73` |
| `fx.Niagara.LeakDetector.Enabled` | `(ref:GEnabled)` | Ref | ECVF_Default | Enables or disables the leak detector. | `Niagara/Private/NiagaraComponentLeakDetector.cpp:32` |
| `fx.Niagara.LeakDetector.GrowthCountThreshold` | `(ref:GGrowthCountThreshold)` | Ref | ECVF_Default | We need to see growth this many times without a drop in count before we consider it a... | `Niagara/Private/NiagaraComponentLeakDetector.cpp:46` |
| `fx.Niagara.LeakDetector.ReportActiveLeaks` | `(ref:GReportActiveLeaks)` | Ref | ECVF_Default | How do we report active components leaks? | `Niagara/Private/NiagaraComponentLeakDetector.cpp:53` |
| `fx.Niagara.LeakDetector.ReportTotalLeaks` | `(ref:GReportTotalLeaks)` | Ref | ECVF_Default | How do we report total components leaks? | `Niagara/Private/NiagaraComponentLeakDetector.cpp:63` |
| `fx.Niagara.LeakDetector.TickDeltaSeconds` | `(ref:GTickDeltaSeconds)` | Ref | ECVF_Default | The time in seconds that must pass before we sample the component information. | `Niagara/Private/NiagaraComponentLeakDetector.cpp:39` |
| `fx.Niagara.SystemSimulation.DebugForceDelayConcurrentTask` | `(ref:GDebugForceDelayConcurrentTask)` | Ref | ECVF_Default | Forces a time delay into the concurrent task. | `Niagara/Private/NiagaraSystemSimulation.cpp:198` |
| `fx.Niagara.SystemSimulation.DebugForceDelayInstancesTask` | `(ref:GDebugForceDelayInstancesTask)` | Ref | ECVF_Default | Forces a time delay into the instances task. | `Niagara/Private/NiagaraSystemSimulation.cpp:206` |
| `fx.Niagara.SystemSimulation.DebugKillAllOnSpawn` | `(ref:GDebugKillAllOnSpawn)` | Ref | ECVF_Default | Will randomly kill all spawning instances based on probability of 0-100. | `Niagara/Private/NiagaraSystemSimulation.cpp:174` |
| `fx.Niagara.SystemSimulation.DebugKillAllOnUpdate` | `(ref:GDebugKillAllOnUpdate)` | Ref | ECVF_Default | Will randomly kill all updating instances based on probability of 0-100. | `Niagara/Private/NiagaraSystemSimulation.cpp:182` |
| `fx.Niagara.SystemSimulation.DebugKillInstanceOnTick` | `(ref:GDebugKillInstanceOnTick)` | Ref | ECVF_Default | Will randomly kill an instance on tick based on probability of 0-100. | `Niagara/Private/NiagaraSystemSimulation.cpp:190` |
| `fx.Niagara.TaskPriorities.Dump` | `(command)` | Command | - | Dump currently set priorities | `Niagara/Private/NiagaraSimulationTaskPriority.cpp:89` |
| `fx.PSCMan.Dump` | `(command)` | Command | - | Dumps state information for all current Particle System Managers. | `Private/Particles/ParticleSystemManager.cpp:830` |
| `fx.TriggerDebugCrash` | `(ref:GbTriggerCrash)` | Ref | ECVF_Default | If > 0 we deliberately crash to test Crash Reporter integration. | `Niagara/Private/NiagaraEmitterInstanceImpl.cpp:1196` |

### Performance / Budget (14개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.Budget.AdjustedUsageDecayRate` | `(ref:GFXBudget_AdjustedUsageDecayRate)` | Ref | ECVF_Default | Rate at which the FX budget adjusted usage value is allowed to decay. This helps prevent... | `Private/Particles/FXBudget.cpp:70` |
| `fx.Budget.AdjustedUsageMax` | `(ref:GFXBudget_AdjustedUsageMax)` | Ref | ECVF_Default | Max value for FX Budget adjusted usage. Prevents one very long frame from keeping the... | `Private/Particles/FXBudget.cpp:78` |
| `fx.Budget.Enabled` | `(ref:FFXBudget::bEnabled)` | Ref | ECVF_Default | Controls whether we track global FX budgets. | `Private/Particles/FXBudget.cpp:96` |
| `fx.Budget.EnabledInEditor` | `(ref:GFXBudget_EnabledInEditor)` | Ref | ECVF_Default | Controls whether we track global FX budgets in editor builds. | `Private/Particles/FXBudget.cpp:87` |
| `fx.Budget.GameThread` | `(ref:GFXBudget_GameThread)` | Ref | ECVF_Default | Budget (in ms) for all combined FX work that runs only on the gamethread. As this budget... | `Private/Particles/FXBudget.cpp:11` |
| `fx.Budget.GameThreadConcurrent` | `(ref:GFXBudget_GameThreadConcurrent)` | Ref | ECVF_Default | Budget (in ms) for all combined FX work that runs on the gamethread or on a concurrent... | `Private/Particles/FXBudget.cpp:19` |
| `fx.Budget.HistoryFrames` | `(ref:GFXBudget_HistorySize)` | Ref | ECVF_Default | ECVF_ReadOnly | Number of frames the global FX budget tracking will hold to work out it's average frame... | `Private/Particles/FXBudget.cpp:35` |
| `fx.Budget.RenderThread` | `(ref:GFXBudget_RenderThread)` | Ref | ECVF_Default | Budget (in ms) for all combined FX work that runs on the Render Thread.  As this budget... | `Private/Particles/FXBudget.cpp:27` |
| `fx.InvalidateNiagaraPerfBaselines` | `(command)` | Command | - | Invalidates all Niagara performance baseline data. | `Niagara/Private/NiagaraEffectType.cpp:418` |
| `fx.Niagara.Scalability.GlobalBudgetCulling` | `(ref:GEnableNiagaraGlobalBudgetCulling)` | Ref | ECVF_Default | When non-zero, high level scalability culling based on global time budget is enabled. | `Niagara/Private/NiagaraWorldManager.cpp:171` |
| `fx.Niagara.TaskPriorities.PerfCapturePriority` | `(ref:GPerfCapturePriority)` | Ref | ECVF_Default | Priority to use if performance captures are enabled.  Reduces the amount of context... | `Niagara/Private/NiagaraSimulationTaskPriority.cpp:12` |
| `fx.Niagara.UseGlobalFXBudget` | `(ref:INiagaraModule::bUseGlobalFXBudget)` | Ref | ECVF_Default | If true, Niagara will track performace data into the global FX budget and feed the global... | `Niagara/Private/NiagaraModule.cpp:130` |
| `fx.ParticlePerfStats.Enabled` | `(ref:GbLocalStatsEnabled)` | Ref | - | Used to control if stat gathering is enabled or not. | `Private/Particles/ParticlePerfStats.cpp:67` |
| `fx.ParticlePerfStats.RunTest` | `(command)` | Command | - | Runs for a number of frames then logs out the results. Arg0 = NumFrames. Arg1 = Gather... | `Private/Particles/ParticlePerfStats.cpp:79` |

### Rendering (18개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.EnableNiagaraLightRendering` | `(ref:GbRendererEnabled)` | Ref | ECVF_Default | If false Niagara Light Renderers are disabled. | `Niagara/Private/NiagaraRendererLights.cpp:30` |
| `fx.EnableNiagaraMeshRendering` | `(ref:GbEnableNiagaraMeshRendering)` | Ref | ECVF_Default | If false Niagara Mesh Renderers are disabled. | `Niagara/Private/NiagaraRendererMeshes.cpp:40` |
| `fx.EnableNiagaraRibbonRendering` | `(ref:GbEnableNiagaraRibbonRendering)` | Ref | ECVF_Default | If false Niagara Ribbon Renderers are disabled. | `Niagara/Private/NiagaraRendererRibbons.cpp:110` |
| `fx.EnableNiagaraSpriteRendering` | `(ref:GbEnableNiagaraSpriteRendering)` | Ref | ECVF_Default | If false Niagara Sprite Renderers are disabled. | `Niagara/Private/NiagaraRendererSprites.cpp:27` |
| `fx.FXAllowParticleMeshLODs` | `(ref:GFXAllowParticleMeshLODs)` | Ref | ECVF_Default | If we allow particle meshes to use LODs or not | `Private/Particles/ParticleSystemRender.cpp:83` |
| `fx.LastRenderTimeSafetyBias` | `(ref:GLastRenderTimeSafetyBias)` | Ref | ECVF_Default | The time to bias the LastRenderTime value to allow for the delay from it being written by... | `Niagara/Private/NiagaraSystemInstance.cpp:59` |
| `fx.Niagara.ComponentRenderComponentCountWarning` | `(ref:GNiagaraComponentRenderComponentC...` | Ref | ECVF_Default | The max number of allowed components before a ui warning is shown in the component... | `Niagara/Private/NiagaraComponentRendererProperties.cpp:26` |
| `fx.Niagara.DecalRenderer.Enabled` | `(ref:GRendererEnabled)` | Ref | ECVF_Default | If == 0, Niagara Decal Renderers are disabled. | `Niagara/Private/NiagaraRendererDecals.cpp:20` |
| `fx.Niagara.FailStaticMeshDataInterface` | `(ref:GNiagaraFailStaticMeshDataInterfa...` | Ref | ECVF_Default | When enabled we will fail out using static mesh data interfaces. | `Private/DataInterface/NiagaraDataInterfaceStaticMesh.cpp:105` |
| `fx.Niagara.MeshRenderer.CalcMeshUsedParticleCount` | `(ref:GNiagaraMeshRendererCalcMeshUsedP...` | Ref | ECVF_Default | Optimization which will inspect renderer vis / mesh index to determine which set of... | `Niagara/Private/NiagaraRendererMeshes.cpp:48` |
| `fx.Niagara.NDIStaticMesh.UseInlineLODsOnly` | `(ref:GNDIStaticMesh_UseInlineLODsOnly)` | Ref | ECVF_Default | (no help text) | `Private/DataInterface/NiagaraDataInterfaceStaticMesh.cpp:113` |
| `fx.Niagara.RenderTarget.IgnoreCookedOut` | `(ref:GIgnoreCookedOut)` | Ref | ECVF_Default | Ignores create render targets for cooked out emitter, i.e. ones that are not used by any... | `Niagara/Private/NiagaraDataInterfaceRenderTargetCommon.cpp:13` |
| `fx.Niagara.RenderTarget.OverrideFormat` | `(command)` | Command | - | Optional global format override for all Niagara render targets | `Niagara/Private/NiagaraDataInterfaceRenderTargetCommon.cpp:31` |
| `fx.Niagara.RenderTarget.ResolutionMultiplier` | `(ref:GResolutionMultiplier)` | Ref | ECVF_Default | Optional global modifier to Niagara render target resolution. | `Niagara/Private/NiagaraDataInterfaceRenderTargetCommon.cpp:21` |
| `fx.Niagara.Renderer.CookOutStaticEnabledBinding` | `(ref:GNiagaraRendererCookOutStaticEnab...` | Ref | ECVF_Scalability | If none zero renderers with static variables used for enabled binding will cook out if... | `Niagara/Private/NiagaraRendererProperties.cpp:46` |
| `fx.Niagara.VolumeRenderer.Enabled` | `(ref:GRendererEnabled)` | Ref | ECVF_Default | If == 0, Niagara Volume Renderers are disabled. | `Niagara/Private/NiagaraRendererVolumes.cpp:21` |
| `fx.Niagara.WarnComponentRenderCount` | `(ref:GNiagaraWarnComponentRenderCount)` | Ref | ECVF_Default | The max number of components that a single system can spawn before a log warning is shown. | `Niagara/Private/NiagaraRendererComponents.cpp:24` |
| `fx.ParticleDefaultLightInverseExposureBlend` | `0.0f` | int32 | ECVF_Default | Blend Factor used to blend between Intensity and Intensity / Exposure. | `Private/Particles/ParticleModules.cpp:3085` |

### Scalability (14개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.Niagara.Scalability.ApplyInstanceCountsRigidly` | `(ref:GApplyInstanceCountsRigidly)` | Ref | ECVF_Default | If true we'll apply instance counts more rigidly. Un-culled Systems wil not be able to... | `Niagara/Private/NiagaraScalabilityManager.cpp:24` |
| `fx.Niagara.Scalability.CanPreventCullingOnPlayerFX` | `(ref:GCanPreventScalabilityCullingOnPl...` | Ref | - | When enabled Niagara can optionally prevent scalability culling on FX linked to the... | `Niagara/Private/NiagaraComponent.cpp:110` |
| `fx.Niagara.Scalability.CullingMode` | `(command)` | Command | - | Set scalability culling mode | `Niagara/Private/NiagaraWorldManager.cpp:249` |
| `fx.Niagara.Scalability.DistanceCulling` | `(ref:GEnableNiagaraDistanceCulling)` | Ref | ECVF_Default | When non-zero, high level scalability culling based on distance is enabled. | `Niagara/Private/NiagaraWorldManager.cpp:155` |
| `fx.Niagara.Scalability.InstanceCountCulling` | `(ref:GEnableNiagaraInstanceCountCulling)` | Ref | ECVF_Default | When non-zero, high level scalability culling based on instance count is enabled. | `Niagara/Private/NiagaraWorldManager.cpp:163` |
| `fx.Niagara.Scalability.MinMaxDistance` | `(ref:GNiagaraScalabiltiyMinumumMaxDist...` | Ref | ECVF_Default | Minimum value for Niagara's Max distance value. Primariy to prevent divide by zero issues... | `Niagara/Private/NiagaraSystem.cpp:173` |
| `fx.Niagara.Scalability.VisibilityCulling` | `(ref:GEnableNiagaraVisCulling)` | Ref | ECVF_Default | When non-zero, high level scalability culling based on visibility is enabled. | `Niagara/Private/NiagaraWorldManager.cpp:147` |
| `fx.Niagara.SetOverrideQualityLevel` | `(command)` | Command | - | Sets which quality level we should override with, no args means clear the override and... | `Niagara/Private/NiagaraPlatformSet.cpp:54` |
| `fx.NiagaraScalabilityUpdateTime_High` | `(ref:GScalabilityUpdateTime_High)` | Ref | ECVF_Default | Time in seconds between updates to scalability states for Niagara systems set to update... | `Niagara/Private/NiagaraScalabilityManager.cpp:15` |
| `fx.NiagaraScalabilityUpdateTime_Low` | `(ref:GScalabilityUpdateTime_Low)` | Ref | ECVF_Default | Time in seconds between updates to scalability states for Niagara systems set to update... | `Niagara/Private/NiagaraScalabilityManager.cpp:13` |
| `fx.NiagaraScalabilityUpdateTime_Medium` | `(ref:GScalabilityUpdateTime_Medium)` | Ref | ECVF_Default | Time in seconds between updates to scalability states for Niagara systems set to update... | `Niagara/Private/NiagaraScalabilityManager.cpp:14` |
| `fx.QualityLevelSpawnRateScaleReferenceLevel` | `2` | float | ECVF_Scalability | Controls the reference level for quality level based spawn rate scaling. This is the FX... | `Private/Particles/ParticleEmitter.cpp:37` |
| `fx.ScalabilityManParallelThreshold` | `(ref:GScalabilityManParallelThreshold)` | Ref | ECVF_Default | Number of instances required for a niagara significance manger to go parallel for it's... | `Niagara/Private/NiagaraScalabilityManager.cpp:18` |
| `fx.ScalabilityMaxUpdatesPerFrame` | `(ref:GScalabilityMaxUpdatesPerFrame)` | Ref | ECVF_Default | Number of instances that can be processed per frame when updating scalability state. -1... | `Niagara/Private/NiagaraScalabilityManager.cpp:21` |

### Spawn / Tick (15개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.Niagara.EventSpawnsUpdateAttributeInitialValues` | `(ref:GbNiagaraEventSpawnsUpdateInitial...` | Ref | ECVF_Default | If > 0 Niagara Event Spawn Scripts will update the Initial.* values for particle... | `Niagara/Private/NiagaraScript.cpp:105` |
| `fx.Niagara.ForceLastTickGroup` | `(ref:GNiagaraForceLastTickGroup)` | Ref | ECVF_Default | Force Niagara ticks to be in the last tick group, this mirrors old behavour and can be... | `Niagara/Private/NiagaraSystemInstance.cpp:67` |
| `fx.Niagara.SystemSimulation.MaxTickSubsteps` | `(ref:GNiagaraSystemSimulationMaxTickSu...` | Ref | ECVF_Default | The max number of possible substeps per frame when a system uses a fixed tick delta. | `Niagara/Private/NiagaraSystemSimulation.cpp:147` |
| `fx.Niagara.SystemSimulation.SkipTickDeltaSeconds` | `(ref:GNiagaraSystemSimulationSkipTickD...` | Ref | ECVF_Default | When none zero we skip all ticks with a delta seconds less than equal to this number. | `Niagara/Private/NiagaraSystemSimulation.cpp:139` |
| `fx.Niagara.SystemSimulation.TickBatchMode` | `(ref:GNiagaraSystemSimulationTickBatch...` | Ref | ECVF_Default | Controls what we do with each batch of instances in a simulation | `Niagara/Private/NiagaraSystemSimulation.cpp:112` |
| `fx.Niagara.SystemSimulation.TickBatchSize` | `(ref:GNiagaraSystemSimulationTickBatch...` | Ref | ECVF_Default | The number of system instances to process per async task. | `Niagara/Private/NiagaraSystemSimulation.cpp:104` |
| `fx.Niagara.SystemSimulation.TickTaskAllowFrameOverlap` | `(ref:GTickTaskAllowFrameOverlap)` | Ref | ECVF_Default | When enabled we allow ticks to overlap beyond PostActorTick until either EOF updates or... | `Niagara/Private/NiagaraSystemSimulation.cpp:165` |
| `fx.Niagara.SystemSimulation.TickTaskShouldWait` | `(ref:GTickTaskShouldWait)` | Ref | ECVF_Default | When enabled the tick task will wait for concurrent work to complete, when disabled the... | `Niagara/Private/NiagaraSystemSimulation.cpp:157` |
| `fx.Niagara.SystemSimulation.UpdateOnSpawn` | `(ref:GNiagaraSystemSimulationUpdateOnS...` | Ref | ECVF_Default | If > 0, system simulations are given a small update after spawn. | `Niagara/Private/NiagaraSystemSimulation.cpp:71` |
| `fx.Niagara.TaskPriorities.PostActorTickPriority` | `(ref:GPostActorTickPriority)` | Ref | ECVF_Default | ECVF_Scalability | Any tasks we execute, such as spawning, in post actor tick will run at this priority. | `Niagara/Private/NiagaraSimulationTaskPriority.cpp:22` |
| `fx.Niagara.TaskPriorities.TickGroupPriority` | `(ref:GTickGroupPrioritiesString)` | Ref | ECVF_Scalability | ECVF_Default | Set tick group priories for Niagara. | `Niagara/Private/NiagaraSimulationTaskPriority.cpp:80` |
| `fx.Niagara.WorldManager.FirstHighPriTickGroup` | `(ref:GFirstHighPriTickGroup)` | Ref | - | Defines which tick groups should be set to high priority for the world manager. | `Niagara/Private/NiagaraWorldManager.cpp:327` |
| `fx.Niagara.WorldManager.SpawnPerTickGroup` | `(ref:GNiagaraSpawnPerTickGroup)` | Ref | ECVF_Default | Will attempt to spawn new systems earlier (default enabled). | `Niagara/Private/NiagaraWorldManager.cpp:106` |
| `fx.Niagara.WorldManager.TickParameterCollectionsOncePerFrame` | `(ref:GTickParameterCollectionsOncePerF...` | Ref | ECVF_Default | ECVF_Scalability | When true parameter collection updates will occur once per frame in the first tick group. | `Niagara/Private/NiagaraWorldManager.cpp:351` |
| `fx.Niagara.WorldManager.UseTickPasses` | `(ref:GNiagaraWorldManagerUseTickPasses)` | Ref | ECVF_Default | When enabled we will use the tick passes to avoid blocking overlapping sims at tick... | `Niagara/Private/NiagaraWorldManager.cpp:82` |

### Cascade (legacy) (12개)

| 이름 | 기본값 | 타입 | ECVF | 도움말 (요약) | 위치 |
|------|--------|------|------|--------------|------|
| `fx.Cascade.BeamRenderingEnabled` | `(ref:GFXCascadeBeamRenderingEnabled)` | Ref | ECVF_Default | Controls if beam rendering is enabled for Cascade | `Private/Particles/ParticleSystemRender.cpp:67` |
| `fx.Cascade.MeshRenderingEnabled` | `(ref:GFXCascadeMeshRenderingEnabled)` | Ref | ECVF_Default | Controls if mesh rendering is enabled for Cascade | `Private/Particles/ParticleSystemRender.cpp:59` |
| `fx.Cascade.SetTemplateDenyList` | `(ref:TemplateDenyListString)` | Ref | ECVF_Scalability | ECVF_Default | Set the template deny List to use. (i.e. P_SystemA,P_SystemB) | `Private/Particles/ParticleSystemComponent.cpp:166` |
| `fx.Cascade.SkipZeroDeltaTime` | `(ref:GFXSkipZeroDeltaTime)` | Ref | ECVF_Default | When enabled a delta tick time of nearly 0.0 will cause us to skip the component update. | `Private/Particles/ParticleSystemComponent.cpp:117` |
| `fx.Cascade.SpriteRenderingEnabled` | `(ref:GFXCascadeSpriteRenderingEnabled)` | Ref | ECVF_Default | Controls if sprite rendering is enabled for Cascade | `Private/Particles/ParticleSystemRender.cpp:51` |
| `fx.Cascade.TrailRenderingEnabled` | `(ref:GFXCascadeTrailRenderingEnabled)` | Ref | ECVF_Default | Controls if trail rendering is enabled for Cascade | `Private/Particles/ParticleSystemRender.cpp:75` |
| `fx.Cascade.UseVelocityForMotionBlur` | `true` | bool | - | When enabled velocity will be used to approximate velocity for vertex factories that... | `Private/Particles/ParticleModules.cpp:92` |
| `fx.DeferrPSCDeactivation` | `(ref:GbDeferrPSCDeactivation)` | Ref | ECVF_Scalability | If > 0, all deactivations on Particle System Components is deferred until next tick. | `Private/Particles/ParticleSystemComponent.cpp:3521` |
| `fx.LWCTileRecache` | `(ref:GFXLWCTileRecache)` | Ref | ECVF_Default | When we cross this number of LWC tiles from where we started the FX we need to recache... | `Private/Particles/ParticleSystemComponent.cpp:108` |
| `fx.PSCMan.Enable` | `(ref:GbEnablePSCWorldManager)` | Ref | ECVF_Scalability | If PSC world manager is enabled. | `Private/Particles/ParticleSystemManager.cpp:24` |
| `fx.ParticleManagerFirstHighPriTickGroup` | `(ref:GFirstHighPriTickGroup)` | Ref | - | Defines which tick groups should be set to high priority for the world manager. | `Private/Particles/ParticleSystemManager.cpp:46` |
| `fx.PruneEmittersOnCookByDetailMode` | `0` | float | ECVF_ReadOnly | Whether to eliminate all emitters that don't match the detail mode. | `Private/Particles/ParticleSystemComponent.cpp:100` |

---

## Part 3: Niagara 작업자 필수 명령

### 이펙트 자체 디버깅 워크플로우

```text
# 1. Solo 모드 강제 — 모든 첨부 시스템을 격리해 단일 시뮬로 검사
fx.ForceNiagaraSpawnAttachedSolo 1

# 2. Debug HUD 활성
fx.Niagara.Debug.Hud 1                   # 켜기
fx.Niagara.Debug.Hud 0                   # 끄기

# 3. 시스템 강제 스폰
fx.Niagara.Debug.SpawnComponent /Game/FX/MyFX.MyFX
fx.Niagara.Debug.SpawnSystem /Game/FX/MyFX.MyFX
fx.Niagara.Debug.KillSpawned             # 스폰한 시스템 제거

# 4. 짧은 루프 — N초마다 자동 리셋
fx.Niagara.Debug.GlobalLoopTime 2.0

# 5. 비동기 끄기 — 게임스레드 동기 실행
fx.Niagara.SystemSimulation.AllowASync 0

# 6. 누수 감지
fx.Niagara.LeakDetector.Enabled 1
```

### 성능 측정 / 프로파일링

```text
fx.ParticlePerfStats.Enabled 1
fx.DetailedCSVStats 1
fx.EnableNiagaraRuntimeCycleCounts 1

fx.ParticlePerfStats.RunTest <Asset> <Frames>

fx.Budget.Enabled 1
fx.Budget.GameThread 4.0
fx.Budget.RenderThread 2.0
fx.Budget.HistoryFrames 30

fx.Niagara.GpuProfiling.Enabled 1
```

### DataInterface 디버깅

```text
# DataChannels (NDC) 디버그
fx.Niagara.DataChannels.WarnOnLateWrites 1
fx.Niagara.DataChannels.LogWritesToOutputLog 2  # 0=off, 1=요약, 2=데이터까지
fx.Niagara.DataChannels.FrameDataToCapture 5

# DataInterface 강제 실패 / 변형
fx.Niagara.FailStaticMeshDataInterface 1
fx.Niagara.NDISpline.GDisableLUTs 1

# DebugDraw DI 활성
fx.Niagara.DebugDraw.Enabled 1
```

---

## Part 4: GPU 시뮬레이션 상세

### GPU 강제/금지 토글

| cvar | 효과 |
|------|------|
| `fx.NiagaraAllowGPUParticles 0` | GPU 시뮬 전역 비활성 (CPU로만 동작) |
| `fx.NiagaraAllowComputeShaders 0` | Compute Shader 자체 차단 |
| `fx.NiagaraGPUCulling` | GPU 컬링 패스 토글 |

> CPU 강제 다운그레이드는 보통 **`fx.NiagaraAllowGPUParticles 0`**. 정의 위치: `Niagara/Private/NiagaraCommon.cpp`. ECVF_Scalability로 마크되어 디바이스 프로파일에서도 설정 가능.

### Tier별 동작 / Dispatcher 제어

| cvar | 효과 |
|------|------|
| `fx.Niagara.Batcher.TickFlush.Mode <0..2>` | GPU 디스패치 플러시 정책 |
| `fx.Niagara.Batcher.TickFlush.MaxPendingTicks` | Pending 가능한 GPU 틱 최대 수 |
| `fx.Niagara.Batcher.DebugLogging` | Dispatcher 상세 로그 |
| `fx.Niagara.AsyncGpuTrace.HWRayTraceEnabled` | HW Ray Trace 사용 가능 여부 |
| `fx.Niagara.AsyncGpuTrace.GlobalSdfEnabled` | Global SDF 트레이스 사용 가능 여부 |

### 디버그 시각화

| cvar | 효과 |
|------|------|
| `fx.Niagara.GpuComputeDebug.OccludedLineColorScale` | Compute Debug 가려진 선 색상 |
| `fx.Niagara.Shader.ForceBindEverything` | 모든 셰이더 바인딩 강제 |
| `fx.Niagara.GpuProfiling.Enabled` | GPU 프로파일링 활성 |
| `fx.Niagara.GpuScriptsCompiledBySystem` | 시스템별 GPU 스크립트 컴파일 카운트 |

---

## Part 5: 참고 파일 위치

### 핵심 컴포넌트 / 누수 감지

- [NiagaraComponent.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/NiagaraComponent.cpp)
- [NiagaraComponentLeakDetector.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/NiagaraComponentLeakDetector.cpp)
- [NiagaraCommon.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/NiagaraCommon.cpp)

### GPU 시뮬레이션 / 디스패처

- [NiagaraGpuComputeDispatch.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/NiagaraGpuComputeDispatch.cpp)
- [NiagaraShader.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/NiagaraShader/Private/NiagaraShader.cpp)
- [NiagaraDebugShaders.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/NiagaraShader/Private/NiagaraDebugShaders.cpp)

### Debug HUD / 디버거

- [NiagaraDebugHud.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/NiagaraDebugHud.cpp)
- [NiagaraDebuggerClient.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/NiagaraDebuggerClient.cpp)
- [SNiagaraDebugger.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/NiagaraEditor/Private/Widgets/SNiagaraDebugger.cpp)

### 컴파일 / VectorVM

- [NiagaraAsyncCompile.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/NiagaraAsyncCompile.cpp)
- [NiagaraSystemCompilingManager.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/NiagaraEditor/Private/NiagaraSystemCompilingManager.cpp)
- [NiagaraScript.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/NiagaraScript.cpp)

### DataInterface

- [NiagaraDataInterfaceDebugDraw.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/DataInterface/NiagaraDataInterfaceDebugDraw.cpp)
- [NiagaraDataInterfaceStaticMesh.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/DataInterface/NiagaraDataInterfaceStaticMesh.cpp)
- [NiagaraDataInterfaceAsyncGpuTrace.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/DataInterface/NiagaraDataInterfaceAsyncGpuTrace.cpp)
- [NiagaraDataInterfaceDataChannelRead.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/DataInterface/NiagaraDataInterfaceDataChannelRead.cpp)
- [NiagaraDataInterfaceDataChannelWrite.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/FX/Niagara/Source/Niagara/Private/DataInterface/NiagaraDataInterfaceDataChannelWrite.cpp)

### FX 예산 / 성능 통계 (Engine)

- [FXBudget.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Particles/FXBudget.cpp)
- [ParticlePerfStats.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Particles/ParticlePerfStats.cpp)
- [GPUSortManager.cpp](/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Particles/GPUSortManager.cpp)

---

## 카테고리별 cvar 개수 요약

| 카테고리 | 개수 |
|---------|------|
| General / Other | 100 |
| Compilation / VectorVM | 22 |
| Solo Mode (디버깅) | 1 |
| GPU Simulation | 39 |
| DataChannels (NDC) | 18 |
| Memory / Pooling | 19 |
| Async Tick / Threading | 4 |
| Debug / Logging | 51 |
| Performance / Budget | 14 |
| Rendering | 18 |
| Scalability | 14 |
| Spawn / Tick | 15 |
| Cascade (legacy) | 12 |
| **합계** | **327** |
