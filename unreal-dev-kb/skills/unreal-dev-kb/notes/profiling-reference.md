# UnrealEngine Profiling & Stats 레퍼런스

UE5 소스(`/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/`) 기반.
프로파일링/통계 시스템에서 자주 쓰는 cvar, 콘솔 명령, `stat` 명령을 정리합니다.

---

## Part 1: 시나리오별 명령 추천

### 1-1. 프레임 시간 측정 (CPU/GPU)

| 단계 | 명령 | 비고 |
|---|---|---|
| 1 | `stat unit` | 프레임/Game/Draw/GPU 시간 표시 |
| 2 | `stat unitgraph` | 시간 그래프 오버레이 |
| 3 | `stat fps` | FPS 카운터 |
| 4 | `stat gpu` | GPU 패스별 ms 표시 (`r.GPUStatsEnabled 1` 필요) |
| 5 | `stat scenerendering` | 씬 렌더링 카운터 (메시, 라이트, 드로우콜) |

### 1-2. GPU 패스 비용 측정

```text
r.GPUStatsEnabled 1            // realtime GPU stats on
stat gpu                       // GPU 타이머 표시
profilegpu                     // 한 프레임 캡처 → GPU Visualizer
r.ProfileGPU.ShowUI 1          // 결과를 UI 트리로 표시
r.ProfileGPU.ShowLeafEvents 1  // leaf 이벤트만 표시
r.ProfileGPU.Sort time         // 정렬: time/num/alpha/depth
```

### 1-3. 메모리 누수 추적

```text
memreport -full                // 전체 메모리 덤프 → Saved/Profiling/MemReports/
memreport -full -log           // 로그에도 출력
stat memory                    // 카테고리별 메모리
stat memoryallocator           // 할당자 통계
stat llm                       // Low-Level Memory Tracker (-llm 옵션 필요)
stat llmfull                   // LLM 상세
```

### 1-4. 셰이더 컴파일 비용

```text
stat shadercompiling           // 컴파일 큐 상황
stat shaders                   // 셰이더 압축/통계
ShaderCompileStats             // 누적 컴파일 통계
r.ShaderCompiler.PrintStats 1  // 컴파일 자동 출력
```

### 1-5. CSV 자동 캡처

```text
csv.Start <name>               // (cvar 아닌 콘솔 명령)
csv.Stop                       // 결과: Saved/Profiling/CSV/<name>.csv
csv.ContinuousWrites 1         // 캡처 동안 디스크 스트리밍
csv.statCounts 1               // STAT 카운트 포함
csv.NamedEventsTiming 1        // CSV에 named events 포함
```

명령행 예: `-csvCaptureFrames=300 -csvGpuStats`

### 1-6. Insights 트레이스 캡처

```text
Trace.Start cpu,gpu,frame,bookmark      // 채널 시작
Trace.File <path>                       // 파일로 저장
Trace.Send <ip>                         // Insights 서버로 송출
Trace.Stop
Trace.Status                            // 현재 상태 / 채널 목록
Trace.Bookmark MyMarker                 // 북마크 삽입
Trace.RegionBegin / Trace.RegionEnd     // 영역 마킹
```

명령행 예: `-trace=cpu,gpu,frame,counters,stats -tracefile=run.utrace`

---

## Part 2: stat 명령 카탈로그

`stat <name>` 형식으로 호출. `stat none`으로 모두 끔. 각 그룹은 `DECLARE_STATS_GROUP`로 정의됨 (`Engine/Public/Stats/Stats2.h` 등).

### 2-1. 일반 (가장 많이 씀)

| 명령 | 출력 |
|---|---|
| `stat unit` | Frame/Game/Draw/GPU/RHIT 시간 |
| `stat unitgraph` | Unit 그래프 오버레이 |
| `stat unitmax` | 최대값 표시 추가 |
| `stat fps` | FPS와 ms |
| `stat raw` | 원시 카운터 출력 |
| `stat detailed` | 상세 그래프 |
| `stat hier -group=X` | 호출 트리 표시 |
| `stat groupname` | 사용 가능한 그룹 나열 |
| `stat slow` | 느린 통계만 표시 |
| `stat startfile` / `stat stopfile` | 통계 파일 캡처 (.ue4stats) |
| `stat namedevents` | Insights/외부 프로파일러용 named events |
| `stat dumphitches` | 히치 발생 시 콜스택 덤프 |
| `stat dumpframe` | 다음 프레임 모든 stat 덤프 |
| `stat dumpcpu` | CPU 통계 덤프 |
| `stat dumpave` / `stat dumpmax` | 평균/최대 덤프 |
| `stat dumpnonframe` | 비프레임 통계 덤프 |
| `stat resetstats` | 누적값 리셋 |
| `stat none` | 표시 끔 |
| `stat display` | 토글 |

### 2-2. GPU / 렌더링

| 명령 | 그룹 매크로 | 내용 |
|---|---|---|
| `stat gpu` | `STATGROUP_GPU` | 패스별 GPU 시간 |
| `stat scenerendering` | `STATGROUP_SceneRendering` | 메시/라이트/드로우콜 |
| `stat initviews` | `STATGROUP_InitViews` | 컬링/뷰 셋업 |
| `stat lightrendering` | `STATGROUP_LightRendering` | 라이트별 비용 |
| `stat shadowrendering` | `STATGROUP_ShadowRendering` | 그림자 패스 |
| `stat rhi` | `STATGROUP_RHI` | RHI 호출/리소스 |
| `stat rhicmdlist` | `STATGROUP_RHICMDLIST` | 커맨드 리스트 |
| `stat renderthreadcommands` | `STATGROUP_RenderThreadCommands` | RT 큐 |
| `stat rendertargetpool` | `STATGROUP_RenderTargetPool` | RT 풀 사용 |
| `stat rdg` | `STATGROUP_RDG` | Render Graph |
| `stat nanite` | `STATGROUP_Nanite` | Nanite 메시 |
| `stat nanitestreaming` | `STATGROUP_NaniteStreaming` | Nanite 스트리밍 |
| `stat naniteraytracing` | `STATGROUP_NaniteRayTracing` | Nanite RT |
| `stat virtualtexturing` | `STATGROUP_VirtualTexturing` | VT 페이지 |
| `stat virtualtexturememory` | `STATGROUP_VirtualTextureMemory` | VT 메모리 |
| `stat scenememory` | `STATGROUP_SceneMemory` | 씬 메모리 |
| `stat sceneculling` | `STATGROUP_SceneCulling` | 컬링 패스 |
| `stat sceneupdate` | `STATGROUP_SceneUpdate` | 씬 업데이트 |
| `stat gpuparticles` | `STATGROUP_GPUParticles` | GPU 파티클 |
| `stat gpuskincache` | `STATGROUP_GPUSkinCache` | 스킨 캐시 |
| `stat heterogeneousvolumesrt` | `STATGROUP_HeterogeneousVolumesRT` | 볼륨 RT |
| `stat instancedata` | `STATGROUP_InstanceData` | 인스턴싱 |

### 2-3. 메모리

| 명령 | 그룹 | 내용 |
|---|---|---|
| `stat memory` | `STATGROUP_Memory` | 카테고리별 사용량 |
| `stat memoryallocator` | `STATGROUP_MemoryAllocator` | 할당자 (TBB/Mimalloc) |
| `stat memoryplatform` | `STATGROUP_MemoryPlatform` | 플랫폼 OS 메모리 |
| `stat memorystaticmesh` | `STATGROUP_MemoryStaticMesh` | 스태틱 메시 |
| `stat scenememory` | `STATGROUP_SceneMemory` | 씬 |
| `stat slatememory` | `STATGROUP_SlateMemory` | UI |
| `stat texturepool` | `STATGROUP_TexturePool` | 텍스처 풀 |
| `stat texturegroup` | `STATGROUP_TextureGroup` | 그룹별 텍스처 |
| `stat sparsevolumetexturememory` | `STATGROUP_SparseVolumeTextureMemory` | SVT |
| `stat rhitransientmemory` | `STATGROUP_RHITransientMemory` | RDG transient |
| `stat llm` / `stat llmfull` / `stat llmplatform` | LLM 그룹들 | Low-Level Memory Tracker (`-llm` 필수) |
| `stat llmassets` / `stat llmuobjects` / `stat llmoverhead` | LLM 그룹 | LLM 분류 |
| `stat particlemem` | `STATGROUP_ParticleMem` | 파티클 메모리 |

### 2-4. 셰이더

| 명령 | 그룹 | 내용 |
|---|---|---|
| `stat shadercompiling` | `STATGROUP_ShaderCompiling` | 컴파일 큐/시간 |
| `stat shaders` | `STATGROUP_Shaders` | 셰이더 압축 |
| `stat pipelinestatecache` | `STATGROUP_PipelineStateCache` | PSO 캐시 |
| `stat psoprecache` | `STATGROUP_PSOPrecache` | PSO 프리캐시 |

### 2-5. 게임플레이 / 엔진

| 명령 | 그룹 | 내용 |
|---|---|---|
| `stat game` | `STATGROUP_Game` | 게임 스레드 카운터 |
| `stat engine` | `STATGROUP_Engine` | 엔진 일반 |
| `stat tickgroups` | `STATGROUP_TickGroups` | Tick 그룹별 비용 |
| `stat tickables` | `STATGROUP_Tickables` | FTickableGameObject |
| `stat ai` | `STATGROUP_AI` | AI |
| `stat aibehaviortree` | `STATGROUP_AIBehaviorTree` | BT |
| `stat aicrowd` | `STATGROUP_AICrowd` | 크라우드 |
| `stat ai_eqs` | `STATGROUP_AI_EQS` | EQS |
| `stat anim` | `STATGROUP_Anim` | 애니메이션 |
| `stat character` | `STATGROUP_Character` | 캐릭터 무브먼트 |
| `stat collision` | `STATGROUP_Collision` | 콜리전 |
| `stat physics` | `STATGROUP_Physics` | 피직스 |
| `stat chaos` | `STATGROUP_Chaos` | Chaos 솔버 |
| `stat chaossolver` / `stat chaoscollision` / `stat chaosjoint` | Chaos 그룹 | Chaos 세부 |
| `stat navigation` | `STATGROUP_Navigation` | 네비메시 |
| `stat object` | `STATGROUP_Object` | UObject |
| `stat uobjects` | `STATGROUP_UObjects` | UObject 카운트 |
| `stat uobjecthash` | `STATGROUP_UObjectHash` | 해시 테이블 |
| `stat gc` | `STATGROUP_GC` | 가비지 컬렉터 |
| `stat loadtime` | `STATGROUP_LoadTime` | 로드 시간 |
| `stat asyncload` | `STATGROUP_AsyncLoad` | 비동기 로드 |
| `stat asyncio` | `STATGROUP_AsyncIO` | I/O |
| `stat streaming` | `STATGROUP_Streaming` | 스트리밍 |
| `stat streamingdetails` | `STATGROUP_StreamingDetails` | 스트리밍 상세 |
| `stat streamingoverview` | `STATGROUP_StreamingOverview` | 스트리밍 요약 |
| `stat worldpartition` | `STATGROUP_WorldPartition` | World Partition |
| `stat mass` | `STATGROUP_Mass` | Mass ECS |
| `stat moviesceneeval` / `stat moviesceneecs` | MovieScene | 시퀀서 |
| `stat fpschart` | `STATGROUP_FPSChart` | FPS 차트 |

### 2-6. 오디오 / 네트워크 / UI

| 명령 | 그룹 |
|---|---|
| `stat audio` | `STATGROUP_Audio` |
| `stat audiomixer` | `STATGROUP_AudioMixer` |
| `stat audiothreadcommands` | `STATGROUP_AudioThreadCommands` |
| `stat net` | `STATGROUP_Net` |
| `stat packet` | `STATGROUP_Packet` |
| `stat ping` | `STATGROUP_Ping` |
| `stat voice` | `STATGROUP_Voice` |
| `stat httpthread` | `STATGROUP_HTTPThread` |
| `stat httpreplay` | `STATGROUP_HttpReplay` |
| `stat localreplay` | `STATGROUP_LocalReplay` |
| `stat slate` | `STATGROUP_Slate` |
| `stat slateverbose` | `STATGROUP_SlateVerbose` |
| `stat ui` | `STATGROUP_UI` |
| `stat canvas` | `STATGROUP_Canvas` |

### 2-7. 기타

| 명령 | 그룹 |
|---|---|
| `stat threading` / `stat threads` / `stat threadpoolasynctasks` | 스레딩 |
| `stat taskgraphtasks` | `STATGROUP_TaskGraphTasks` |
| `stat cpustalls` | `STATGROUP_CPUStalls` |
| `stat trace` | `STATGROUP_Trace` |
| `stat ddc` | `STATGROUP_DDC` |
| `stat compression` | `STATGROUP_Compression` |
| `stat pakfile` | `STATGROUP_PakFile` |
| `stat bulkdata` | `STATGROUP_BulkData` |
| `stat linkerload` / `stat linkercount` | 링커 |
| `stat profiler` | `STATGROUP_Profiler` |
| `stat statsystem` | `STATGROUP_StatSystem` |
| `stat foliage` | `STATGROUP_Foliage` |
| `stat landscape` | `STATGROUP_Landscape` |
| `stat geometrycollection` | `STATGROUP_GeometryCollection` |
| `stat raytracinggeometry` | `STATGROUP_RayTracingGeometry` |
| `stat drivermonitornvidia` / `...amd` / `...intel` | GPU 드라이버 (벤더별) |
| `stat vulkanrhi` / `stat d3d11rhi` / `stat metalrhi` / `stat openglrhi` | RHI 백엔드별 |
| `stat vulkanmemory` / `stat vulkanpso` / `stat vulkanraytracing` | Vulkan 세부 |
| `stat scriptvm` / `stat script` / `stat kismetcompiler` | 블루프린트 |
| `stat gameplaytags` / `stat gameplaytasks` | 태그/태스크 |

---

## Part 3: cvar 카탈로그

### 3-1. GPU Profiling (`r.ProfileGPU.*`, `r.GPU*`)

| cvar | 설명 |
|---|---|
| `r.GPUStatsEnabled` | `stat gpu` 활성화 (기본 1, RHI 지원 시) |
| `r.GPUTracingStatsEnabled` | GPU 트레이싱 통계 |
| `r.GPUStatsChildTimesIncluded` | 자식 시간 포함 여부 |
| `r.GPUCsvStatsEnabled` | GPU stats를 CSV에 기록 |
| `r.ProfileGPU.Pattern` | `profilegpu`에서 매칭할 이벤트 패턴 |
| `r.ProfileGPU.Root` | 루트 이벤트 필터 |
| `r.ProfileGPU.Sort` | `time` / `num` / `alpha` / `depth` 정렬 |
| `r.ProfileGPU.ThresholdPercent` | 표시 임계 % |
| `r.ProfileGPU.ShowUI` | 결과를 UI 트리로 표시 |
| `r.ProfileGPU.ShowLeafEvents` | 리프 이벤트만 |
| `r.ProfileGPU.ShowInclusive` / `ShowExclusive` | 포함/배타 시간 표시 |
| `r.ProfileGPU.ShowHeader` | 헤더 표시 |
| `r.ProfileGPU.ShowStats` | 통계 행 표시 |
| `r.ProfileGPU.ShowEventHistogram` | 히스토그램 |
| `r.ProfileGPU.ShowEmptyQueues` | 빈 큐 표시 |
| `r.ProfileGPU.ShowTransitions` | 리소스 전환 표시 |
| `r.ProfileGPU.ShowPercentColumn` | % 열 표시 |
| `r.ProfileGPU.Screenshot` | 캡처 시 스크린샷 |
| `r.ProfileGPU.UnicodeOutput` | 트리 라인 유니코드 |
| `r.ProfileGPU.PrintAssetSummary` | 에셋 요약 |
| `r.ProfileGPU.AssetSummaryCallOuts` | 요약 콜아웃 |
| `r.GPUCrashDebugging` | GPU 크래시 디버깅 |
| `r.GPUCrashDebugging.Breadcrumbs` | breadcrumb 표시 |
| `r.GPUCrashOnOutOfMemory` | OOM 시 크래시 |

### 3-2. CSV Profiler (`csv.*`)

`Engine/Source/Runtime/Core/Private/ProfilingDebugging/CsvProfiler.cpp` 정의.

| cvar | 설명 |
|---|---|
| `csv.BlockOnCaptureEnd` | 캡처 종료 시 블록 |
| `csv.AggregateTaskWorkerStats` | 태스크 워커 집계 |
| `csv.ContinuousWrites` | 연속 디스크 기록 |
| `csv.Shipping.ContinuousWrites` | shipping 빌드 연속 기록 |
| `csv.ForceExit` | 캡처 종료 후 종료 |
| `csv.Benchmark` / `csv.Benchmark.IterationCount` | 벤치 모드 |
| `csv.TargetFrameRateOverride` | 타겟 FPS 오버라이드 |
| `csv.CompressionMode` | 압축 모드 |
| `csv.statCounts` | stat 카운트 포함 |
| `csv.WriteBufferSize` | 쓰기 버퍼 |
| `csv.FramesToBuffer` | 프레임 버퍼 수 |
| `csv.PauseProcessingThread` | 프로세스 스레드 일시정지 |
| `csv.ProcessingThread.TimeBetweenUpdates` | 업데이트 간격 |
| `csv.ProcessingThread.GtStallUpdateTimeThresholdMs` | GT 스톨 임계 |
| `csv.ProcessingThread.GtStallUpdateEscalationThreshold` | 이스컬레이션 |
| `csv.MaxPerThreadStatDataSlackKB` | 스레드당 슬랙 |
| `csv.NumberedFNamesStatsAreFatal` | 번호 FName fatal |
| `csv.StatNameValidation` | 이름 검증 |
| `csv.trackWaitsAllThreads` | 모든 스레드 wait 추적 |
| `csv.trackWaitsGT` / `csv.trackWaitsRT` | GT/RT wait 추적 |
| `csv.NamedEventsExclusive` | 배타 stat에 named event |
| `csv.NamedEventsTiming` | 타이밍 stat에 named event |

### 3-3. Insights / Trace (`Trace.*`)

`Engine/Source/Runtime/Core/Private/ProfilingDebugging/TraceAuxiliary.cpp` 정의.
모두 `FAutoConsoleCommand` (cvar 아닌 콘솔 명령).

| 명령 | 설명 |
|---|---|
| `Trace.Start <channels>` | 트레이싱 시작 (예: `cpu,gpu,frame`) |
| `Trace.Stop` | 종료 |
| `Trace.Pause` / `Trace.Resume` | 일시정지/재개 |
| `Trace.Send <host> [channels]` | Insights 서버로 송출 |
| `Trace.File [path] [channels]` | 파일로 저장 |
| `Trace.SnapshotSend <host>` | 스냅샷 송출 |
| `Trace.SnapshotFile [path]` | 스냅샷 저장 |
| `Trace.Status` | 현재 상태/채널 |
| `Trace.Enable <channel>` | 채널 활성 |
| `Trace.Disable <channel>` | 채널 비활성 |
| `Trace.Bookmark <name>` | 북마크 |
| `Trace.RegionBegin <name>` / `Trace.RegionEnd <name>` | 영역 마킹 |
| `Trace.SlowTaskMaxRegionDepth` | (cvar) 느린 작업 영역 깊이 |

채널 프리셋: `[Trace.ChannelPresets]` 섹션 (`DefaultEngine.ini`).

### 3-4. Memory (`r.MemReport.*`, `r.DumpGPU.*`)

| cvar / 명령 | 설명 |
|---|---|
| `memreport` | 메모리 덤프 (콘솔 명령, `UEngine::HandleMemReportCommand`) |
| `memreport -full` | 풀 덤프 → `Saved/Profiling/MemReports/` |
| `memreport -log` | 로그에도 출력 |
| `MemReportDeferred <type>` | 다음 프레임 비차단 덤프 (config의 `MemReport<Type>Commands` 섹션) |
| `r.DumpGPU.Root` | DumpGPU 출력 루트 |
| `r.DumpGPU.Texture` | 텍스처 덤프 모드 |
| `r.DumpGPU.Buffer` | 버퍼 덤프 모드 |
| `r.DumpGPU.MaxStagingSize` | 스테이징 크기(MB) |
| `r.DumpGPU.PassParameters` | 패스 파라미터 |
| `r.DumpGPU.Delay` / `r.DumpGPU.FrameDelay` / `r.DumpGPU.FrameCount` | 캡처 타이밍 |
| `r.DumpGPU.CameraCut` | 카메라 컷 시 |
| `r.DumpGPU.FixedTickRate` | 고정 틱 |
| `r.DumpGPU.Stream` | 스트리밍 |
| `r.DumpGPU.Draws` | 드로우 단위 |
| `r.DumpGPU.Mask` | 마스크 |
| `r.DumpGPU.Explore` | 결과 자동 열기 |
| `r.DumpGPU.ConsoleVariables` | cvar 덤프 |
| `r.DumpGPU.Directory` | 출력 폴더 |
| `r.DumpGPU.Upload` / `r.DumpGPU.Upload.CompressResources` | 업로드 |
| `r.DumpGPU.Viewer.Visualize` | 뷰어 시각화 |
| `r.DumpGPU.Screenshot` | 스크린샷 |

### 3-5. Stats / 기타 (Core/Private/Stats/)

| cvar | 설명 |
|---|---|
| `DumpHitchesAllThreads` | 히치 시 전 스레드 덤프 |
| `SpewStatsSpam` | 스팸 통계 출력 |
| `EnableLeakTest` | 누수 테스트 |
| `DumpStatPackets` | stat 패킷 덤프 |
| `ABTest.History` / `ABTest.ReportNum` / `ABTest.CoolDown` / `ABTest.MinFramesPerTrial` / `ABTest.NumResamples` | A/B 테스트 |

---

## Part 4: 콘솔 명령 (cvar 아님)

### 4-1. MemReport

`Engine/Source/Runtime/Engine/Private/UnrealEngine.cpp:5576+`

```text
memreport [-full] [-log] [-fast]
MemReportDeferred [-full] [<typename>]
```

출력: `<Project>/Saved/Profiling/MemReports/<MapName>-<Date>.memreport`
설정: `DefaultEngine.ini`의 `[MemReportFullCommands]`/`[MemReportCommands]`/`[MemReport<Type>Commands]` 섹션.

### 4-2. ProfileGPU

`Engine/Source/Runtime/RHI/Private/GPUProfiler.cpp:2651`. `GTriggerGPUProfile = true` 토글.

```text
profilegpu                     // 다음 프레임 캡처 → GPU Visualizer 창
profilegpuhitches              // 히치 자동 캡처 모드 토글
```

### 4-3. CSV Profiler

```text
csvProfile start [<filename>]
csvProfile stop
csvProfile <event>             // 이벤트 마커
```

명령행: `-csvCaptureFrames=<N>`, `-csvNoProcessingThread`, `-csvGpuStats`, `-csvDeviceProfile=<name>`, `-csvForceExit`.

### 4-4. Trace

위 3-3 표 참조 (모두 콘솔 명령).
명령행: `-trace=<channels>`, `-tracehost=<ip>`, `-tracefile[=<path>]`, `-statnamedevents`.

### 4-5. ShaderCompileStats / Shader Debug

```text
ShaderCompileStats             // 누적 컴파일 통계 출력
DumpShaderStats                // 셰이더 통계 덤프
recompileshaders <type>        // 일부/전체 셰이더 재컴파일
DumpShaderPipelineStats        // 파이프라인 통계
```

### 4-6. 기타 덤프

```text
DumpTicks                      // 틱 함수 덤프 (Engine/Private/UnrealEngine.cpp)
DumpGPU                        // GPU 캡처 (RDG, r.DumpGPU.* 사용)
DumpDrawList                   // 드로우 리스트
DumpRHIResources               // RHI 리소스 덤프
DumpRenderTargets              // RT 덤프
ListTextures                   // 텍스처 목록
ListPSOs                       // PSO 목록
ListAnimations                 // 애님 목록
obj list                       // UObject 목록
gc.dumpgcsubsteps              // GC 서브스텝
listspawnedactors              // 액터 스폰 |

---

## Part 5: 출력물 분석 가이드

### 5-1. ProfileGPU 출력 읽는 법

- 헤더: 캡처된 프레임 정보, 총 GPU ms.
- 트리: RDG 패스 → 자식 이벤트. `Excl` = 자체 시간, `Incl` = 자식 포함.
- `r.ProfileGPU.Sort time` 권장 (병목 위로).
- `r.ProfileGPU.ShowLeafEvents 1`이면 SetRenderTarget/Draw 단위까지.
- UI 모드(`r.ProfileGPU.ShowUI 1`)는 GPU Visualizer 창에서 인터랙티브 탐색.
- 화면에 안 뜨면 RHI가 GPU 타이머를 지원하는지(`GSupportsTimestampRenderQueries`) 확인.

### 5-2. MemReport 결과 해석

위치: `<Project>/Saved/Profiling/MemReports/<Map>-<Date>.memreport`
포함 명령:
- `Mem detailed` — 카테고리 사용량
- `obj list -resourcesizesort` — UObject 메모리 큰 순
- `ListTextures -alphasort` — 텍스처 목록
- `ListSounds`, `ListParticleSystems`, `Stat Streaming` 등.
설정: `[MemReportFullCommands]` 섹션에서 실행할 명령 목록 편집.

LLM 사용 시 (`-llm` 명령행 옵션) `stat llm`과 결합하면 모듈/카테고리별 정확한 분류.

### 5-3. CSV 파일 위치 / 분석 도구

- 위치: `<Project>/Saved/Profiling/CSV/`
- 분석: `Engine/Source/Programs/CSVTools/` (CSVToSVG.exe, PerfReportTool.exe).
- 컬럼: 프레임당 `RenderThreadTime`, `GameThreadTime`, `GPU/...` 등.
- `csv.statCounts 1`로 stat 카운터 컬럼 추가, `csv.NamedEventsTiming 1`로 timing 컬럼.

### 5-4. Insights (.utrace) 분석

- `UnrealInsights.exe`로 열기.
- Timing Insights 탭: CPU/GPU 타임라인, 프레임 단위 호출 트리.
- Memory Insights 탭: LLM 채널 (`-trace=memory` 필요).
- Loading Insights / Networking Insights: 별도 탭.
- 채널 묶음: `default,counters,stats,frame,bookmark,cpu,gpu,memory,loadtime,assetloadtime,net`.

---

## Part 6: 셰이더 작업자 필수 명령

셰이더/머티리얼 작업 중 가장 많이 쓰는 8개:

```text
1. stat unit                   // 큰 그림: GPU vs CPU
2. stat gpu                    // GPU 패스별 ms (실시간)
3. profilegpu                  // 한 프레임 정밀 캡처
4. r.ProfileGPU.Sort time      // 결과 정렬
5. stat scenerendering         // 메시/라이트/드로우콜 카운트
6. stat shadercompiling        // 컴파일 큐 / DDC 미스
7. ShaderCompileStats          // 누적 컴파일 시간/잡
8. r.ShaderCompiler.PrintStats 1  // 자동 출력
```

추가 권장:
- `recompileshaders changed` — 변경된 셰이더만 재컴파일.
- `r.GPUStatsEnabled 1` — `stat gpu` 안 보이면 확인.
- `Trace.Start cpu,gpu,frame` + UnrealInsights — 멀티프레임 분석.
- `csvProfile start` + `csv.NamedEventsTiming 1` — 자동화 회귀용.

---

## Part 7: 참고 파일 위치

| 시스템 | 경로 |
|---|---|
| Stats 코어 | `Engine/Source/Runtime/Core/Public/Stats/Stats.h`, `Stats2.h` |
| Stats 명령 핸들러 | `Engine/Source/Runtime/Core/Private/Stats/StatsCommand.cpp` |
| Stats 데이터 / 시스템 | `Engine/Source/Runtime/Core/Private/Stats/StatsData.cpp`, `StatsSystemTypes.cpp` |
| CSV Profiler | `Engine/Source/Runtime/Core/Private/ProfilingDebugging/CsvProfiler.cpp` |
| CSV Profiler 헤더 | `Engine/Source/Runtime/Core/Public/ProfilingDebugging/CsvProfiler.h` |
| Trace / Insights | `Engine/Source/Runtime/Core/Private/ProfilingDebugging/TraceAuxiliary.cpp` |
| Trace 매크로 | `Engine/Source/Runtime/Core/Public/ProfilingDebugging/CpuProfilerTrace.h`, `MiscTrace.h` |
| GPU Profiler (ProfileGPU) | `Engine/Source/Runtime/RHI/Private/GPUProfiler.cpp` |
| GPU Profiler 헤더 | `Engine/Source/Runtime/RHI/Public/GPUProfiler.h` |
| Realtime GPU Profiler (`stat gpu`) | `Engine/Source/Runtime/RenderCore/Private/ProfilingDebugging/RealtimeGPUProfiler.cpp` |
| DumpGPU | `Engine/Source/Runtime/RenderCore/Private/DumpGPU.cpp` |
| MemReport | `Engine/Source/Runtime/Engine/Private/UnrealEngine.cpp` (`HandleMemReportCommand`, `HandleMemReportDeferredCommand`) |
| LLM | `Engine/Source/Runtime/Core/Public/HAL/LowLevelMemTracker.h`, `Private/HAL/LowLevelMemTracker.cpp` |
| FPS Chart | `Engine/Source/Runtime/Engine/Private/Performance/EnginePerformanceTargets.cpp` |
| ABTesting | `Engine/Source/Runtime/Core/Private/ProfilingDebugging/ABTesting.cpp` |
| 스탯 그룹 정의 | 각 모듈의 `*Stats.h` (예: `EngineStats.h`, `RenderCoreStats.h`, `RHIStats.h`) |

### 명령행 플래그 요약

| 플래그 | 효과 |
|---|---|
| `-trace=<channels>` | Insights 트레이싱 시작 |
| `-tracehost=<ip>` | Insights 서버 호스트 |
| `-tracefile[=<path>]` | utrace 파일로 저장 |
| `-statnamedevents` | named events 송출 |
| `-csvCaptureFrames=<N>` | 부팅 후 N 프레임 CSV 캡처 |
| `-csvGpuStats` | CSV에 GPU stats 포함 |
| `-csvNoProcessingThread` | CSV 단일 스레드 |
| `-llm` | Low-Level Memory Tracker 활성 |
| `-llmtagsets=Assets,AssetClasses` | LLM 태그셋 |
| `-llmcsv` | LLM CSV 기록 |
| `-statfile=<path>` | 부팅 직후 stat 파일 캡처 |
| `-deepprofile` | 깊이 프로파일링 |
| `-cpuprofilertrace` | CPU 프로파일러 트레이스만 |
