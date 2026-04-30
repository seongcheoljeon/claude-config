# UnrealEngine GPU 디버깅 도구 레퍼런스

UnrealEngine 5.x 소스를 기반으로 RenderDoc / PIX / RGP / DumpGPU / GPU Crash Debugging 관련 콘솔 변수(cvar)와 명령을 카탈로그화한다. 모든 인용은 `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine` 트리 기준이다.

---

## Part 1: 도구별 시작 가이드

### RenderDoc 캡처 워크플로우

전제: **RenderDoc**(https://renderdoc.org/) 설치. 플러그인은 `Plugins/Developer/RenderDocPlugin`에 포함되어 있으며 에디터 빌드(`!UE_BUILD_SHIPPING`)에서만 활성화된다.

1. 에디터에서 **Edit > Plugins**에서 **RenderDoc** 플러그인을 활성화 (또는 `-AttachRenderDoc` 커맨드라인).
2. `renderdoc.BinaryPath` 또는 환경 변수에 RenderDoc 실행 파일 경로 지정.
3. 프레임 캡처 트리거:
   - 콘솔: `renderdoc.CaptureFrame`
   - PIE 캡처: `renderdoc.CapturePIE [FrameCount]`
   - 또는 메인 툴바의 RenderDoc 아이콘 클릭.
4. 캡처가 끝나면 자동으로 RenderDoc UI가 열린다(`renderdoc.dll` / Linux는 `librenderdoc.so` 로드).

자주 쓰는 옵션 조합:

```ini
renderdoc.AutoAttach=1               ; 부팅 시 자동 attach
renderdoc.CaptureCallstacks=1        ; API 호출 콜스택 기록
renderdoc.CaptureAllActivity=1       ; 모든 뷰포트/에디터 윈도우 캡처
renderdoc.CaptureDelayInSeconds=1
renderdoc.CaptureDelay=2
renderdoc.CaptureFrameCount=3        ; >1이면 자동으로 CaptureAllActivity로 처리
renderdoc.ReferenceAllResources=0    ; 캡처 크기 폭증 주의
renderdoc.SaveAllInitials=0          ; 동상
```

### PIX 캡처 워크플로우

전제: **Microsoft PIX on Windows**(https://devblogs.microsoft.com/pix/) 설치, D3D12 RHI(`-d3d12`).

1. 에디터/게임을 D3D12로 실행.
2. 자동 attach 사용 시 `-attachPIX` 커맨드라인 또는 `r.D3D12.AutoAttachPIX=1` (read-only, 부팅 시점에만 적용).
3. `WinPixGpuCapturer.dll`이 PIX 설치 경로에서 자동 로드된다 (`PIXLoadLatestWinPixGpuCapturerLibrary`).
4. PIX UI에서 **Take GPU Capture** 또는 게임 창 위에서 PrintScreen 단축키.

UE 빌드에는 `r.PIX.*` cvar가 별도 등록되어 있지 않다. PIX 통합은 사실상 `r.D3D12.AutoAttachPIX` + DLL 로드 + 이벤트 마커(공통 `SCOPED_DRAW_EVENT*`)로 구성된다. 셰이딩 빌드 옵션은 `D3D12RHI_SUPPORTS_WIN_PIX` 매크로로 게이트된다 (Shipping 빌드에서는 비활성).

### RGP (Radeon GPU Profiler) 셋업

전제: **AMD Radeon Developer Panel + RGP**(https://gpuopen.com/rgp/) 설치, AMD GPU 사용.

1. **Radeon Developer Panel**에서 프로파일링 활성화 후 게임 연결 대기.
2. UE 측에서는 RGP 마커가 **read-only** cvar로 비활성 기본값:

```ini
[/Script/Engine.RendererSettings]
D3D12.EmitRgpFrameMarkers=1   ; 디바이스 생성 전에 설정해야 함
```

   `DefaultEngine.ini` 또는 커맨드라인 `-D3D12.EmitRgpFrameMarkers=1` 으로 부팅 시 지정.
3. Radeon Developer Panel에서 캡처 트리거 → RGP 자동 실행.

주석에 따르면 RDP가 켜진 상태를 자동 감지할 방법이 없어 수동으로 토글해야 한다.

### DumpGPU 명령 활용

전제: 외부 도구 불필요(엔진 내장). RDG_DUMP_RESOURCES 매크로가 켜진 빌드에서만 사용 가능.

콘솔에서:

```text
DumpGPU                                  ; 다음 프레임 통째로 덤프
DumpGPU -upload                          ; 업로드 서비스로 송신 (r.DumpGPU.Upload=1 필요)
DumpGPU -oneframe                        ; FrameCount 1로 강제 (씬 캡처 등)
DumpGPU -Bar=Foo                         ; 임의 키=값 파라미터 전달
```

런타임 조정 cvar:

- `r.DumpGPU.Root=*` 패턴으로 RDG 패스 필터(case-sensitive 와일드카드).
- `r.DumpGPU.FrameCount=1`, `r.DumpGPU.Delay=0`, `r.DumpGPU.FrameDelay=0`.
- `r.DumpGPU.Texture=2` / `r.DumpGPU.Buffer=2` 0/1/2(설명/디스크립터/디스크립터+바이너리).
- 출력 경로: `r.DumpGPU.Directory=...`, 미지정 시 환경변수 `UE-DumpGPUPath`, 둘 다 없으면 `Saved/GPUDumps/`.

뷰어는 `RenderCore.Build.cs`가 빌드 시 GPUDumpViewer 소스를 출력에 복사한다.

### GPU Crash 디버깅

전제: 외부 SDK 필요(NVIDIA Aftermath: 자동 다운로드, AMD: 미지원, MS DRED: Windows 10 1903+).

1. 마스터 스위치 활성:

```text
-gpucrashdebugging
또는 r.GPUCrashDebugging=1 (read-only)
```

   세부 기능을 끄려면 `-nogpucrashdebugging` 또는 `-feature=0` (예: `-aftermath=0`, `-dred=0`, `-lightdred=0`, `-gpubreadcrumbs=0`).

2. RHI 레벨 RHI 브레드크럼이 기본 켜짐(`r.GPUCrashDebugging.Breadcrumbs=1`).
3. Aftermath 사용 시(NVIDIA GPU) — `r.GPUCrashDebugging.Aftermath.Markers / Callstack / ResourceTracking / TrackAll` 조합.
4. DRED(D3D12) — `r.D3D12.DRED=1`(Full) 또는 `r.D3D12.LightweightDRED=1`(Intel은 무거우므로 자동 Disabled).
5. OOM 시 크래시 — `r.GPUCrashOnOutOfMemory=1`.

크래시 시 로그/콜스택과 함께 `Saved/Crashes/`에 dump가 떨어진다.

---

## Part 2: cvar 카탈로그

총 **42** 개. 모두 read-only는 부팅/디바이스 생성 전에 INI 또는 커맨드라인으로 설정.

### RenderDoc (10)

| 이름 | 기본 | ECVF | 설명 / 위치 |
|---|---|---|---|
| `renderdoc.AutoAttach` | 0 | - | RenderDoc will attach on startup. (`Plugins/Developer/RenderDocPlugin/Source/RenderDocPlugin/Private/RenderDocPluginLoader.cpp:25`) |
| `renderdoc.EnableCrashHandler` | 0 | - | 0=engine handles, 1=RenderDoc handles. RenderDoc 개발자에게 신고용. (`RenderDocPluginLoader.cpp:30`) |
| `renderdoc.BinaryPath` | "" | - | RenderDoc 실행 파일이 들어 있는 디렉터리. (`RenderDocPluginLoader.cpp:40`) |
| `renderdoc.CaptureAllActivity` | 0 | - | 0=현재 뷰포트만, 1=모든 뷰포트/에디터 윈도우. (`RenderDocPluginModule.cpp:38`) |
| `renderdoc.CaptureCallstacks` | 1 | - | API 호출 콜스택 기록 여부. (`RenderDocPluginModule.cpp:43`) |
| `renderdoc.ReferenceAllResources` | 0 | - | 1이면 미사용 리소스도 포함(캡처 크기 급증). (`RenderDocPluginModule.cpp:48`) |
| `renderdoc.SaveAllInitials` | 0 | - | 1이면 모든 리소스의 초기 상태를 저장. (`RenderDocPluginModule.cpp:54`) |
| `renderdoc.CaptureDelayInSeconds` | 1 | - | 0=프레임 단위, 1=초 단위. (`RenderDocPluginModule.cpp:60`) |
| `renderdoc.CaptureDelay` | 0 | - | >0이면 지연 후 캡처(단위는 위 cvar). (`RenderDocPluginModule.cpp:65`) |
| `renderdoc.CaptureFrameCount` | 0 | - | >0이면 다중 프레임. CaptureAllActivity가 강제됨. (`RenderDocPluginModule.cpp:69`) |
| `renderdoc.ShowHelpOnStartup` | 0 | - | 첫 실행 시 환영 다이얼로그. (`SRenderDocPluginHelpWindow.cpp:23`) |

### PIX (1)

| 이름 | 기본 | ECVF | 설명 / 위치 |
|---|---|---|---|
| `r.D3D12.AutoAttachPIX` | 0 | ReadOnly, RenderThreadSafe | Automatically attach PIX on startup. `D3D12RHI_SUPPORTS_WIN_PIX` 가드. (`Source/Runtime/D3D12RHI/Private/Windows/WindowsD3D12Device.cpp:91`) |

> 참고: 별도 `r.PIX.*` 네임스페이스 cvar는 엔진 본체에 존재하지 않는다. PIX 캡처는 외부 PIX UI/DLL이 주도하고, UE는 DLL 자동 로드 + 공통 이벤트 마커만 제공한다.

### RGP / Radeon (1)

| 이름 | 기본 | ECVF | 설명 / 위치 |
|---|---|---|---|
| `D3D12.EmitRgpFrameMarkers` | 0 | ReadOnly, RenderThreadSafe | Enables/Disables frame markers for AMD's RGP tool. **디바이스 생성 전에 설정 필요**. (`Source/Runtime/D3D12RHI/Private/D3D12CommandContext.cpp:20`) |

### DumpGPU (16)

`Source/Runtime/RenderCore/Private/DumpGPU.cpp`에 모두 등록.

| 이름 | 기본 | ECVF | 설명 |
|---|---|---|---|
| `r.DumpGPU.Root` | `"*"` | Default | 와일드카드로 RDG 패스 필터(케이스 민감). |
| `r.DumpGPU.Texture` | 2 | RenderThreadSafe | 0=무시, 1=디스크립터만, 2=디스크립터+바이너리. |
| `r.DumpGPU.Buffer` | 2 | RenderThreadSafe | 0/1/2 동일 의미. |
| `r.DumpGPU.MaxStagingSize` | 64 | RenderThreadSafe | 스테이징 리소스 최대 MB. |
| `r.DumpGPU.PassParameters` | 1 | RenderThreadSafe | 패스 파라미터 덤프 여부. |
| `r.DumpGPU.Delay` | 0.0 | RenderThreadSafe | 덤프 시작까지 지연(초). |
| `r.DumpGPU.FrameDelay` | 0 | RenderThreadSafe | 덤프 시작까지 지연(프레임). |
| `r.DumpGPU.FrameCount` | 1 | Default | 연속 덤프 프레임 수. |
| `r.DumpGPU.CameraCut` | 0 | Default | 첫 프레임에 카메라 컷 발생. |
| `r.DumpGPU.FixedTickRate` | 0.0 | Default | 덤프 동안 고정 틱 레이트로 오버라이드. |
| `r.DumpGPU.Stream` | 0 | Default | 0=동기 복사(OOM 안전), 1=비동기 풀. |
| `r.DumpGPU.Draws` | 0 | Default | 각 드로우 후 리소스도 덤프. |
| `r.DumpGPU.Mask` | 1 | Default | (멀티 GPU 마스크) |
| `r.DumpGPU.Explore` | 1 | Default | 덤프 종료 후 GPUDumpViewer 자동 오픈. |
| `r.DumpGPU.ConsoleVariables` | 1 | Default | 렌더링 cvar 스냅샷 함께 덤프. |
| `r.DumpGPU.Test.EnableDiskWrite` | 1 | Default | 자동화 테스트용. 디스크에 실제로 쓸지. |
| `r.DumpGPU.Test.PrettifyResourceFileNames` | 0 | Default | 자동화용 파일명 정리. |
| `r.DumpGPU.Directory` | "" | Default | 출력 디렉터리. 미지정 시 env `UE-DumpGPUPath` → `Saved/GPUDumps/`. |
| `r.DumpGPU.Upload` | 1 | Default | 업로드 서비스 사용. |
| `r.DumpGPU.Upload.CompressResources` | 1 | Default | 0=raw, 1=Zlib, 2=…. |
| `r.DumpGPU.Viewer.Visualize` | "" | Default | GPUDumpViewer 기본 시각화 모드. |

### GPU Crash Debugging (15)

`Source/Runtime/RHI/Private/RHI.cpp` (마스터), `Source/Runtime/D3D12RHI/Private/D3D12Adapter.cpp` (DRED), `Source/Runtime/RHICore/Private/RHICoreNvidiaAftermath.cpp` (Aftermath).

| 이름 | 기본 | ECVF | 설명 |
|---|---|---|---|
| `r.GPUCrashDebugging` | 0 | ReadOnly | 마스터 스위치. 모든 벤더별 분석 도구 일괄 활성. (`RHI.cpp:2204`) |
| `r.GPUCrashDebugging.Breadcrumbs` | 1 | ReadOnly | 벤더 무관 RHI 브레드크럼. (`RHI.cpp:2272`) |
| `r.GPUCrashOnOutOfMemory` | 0 | ReadOnly | GPU OOM 발생 시 크래시 보고. (`RHI.cpp:1100`) |
| `r.D3D12.EnableD3DDebug` | 0 | ReadOnly, RenderThreadSafe | 0=disable, 1~4=다양한 D3D 디버그 레이어 모드. (`D3D12Adapter.cpp:57`) |
| `r.D3D12.DRED` | 0 | ReadOnly, RenderThreadSafe | Full DRED. GPU 마지막 명령 추적, 오버헤드 큼. (`D3D12Adapter.cpp:137`) |
| `r.D3D12.LightweightDRED` | 0 | ReadOnly, RenderThreadSafe | Lightweight DRED. PC 전 H/W 동작. Intel은 자동 비활성. (`D3D12Adapter.cpp:144`) |
| `r.GPUCrashDebugging.Aftermath` | 1 | ReadOnly | NVIDIA Aftermath 마스터 토글. (`RHICoreNvidiaAftermath.cpp:56`) |
| `r.GPUCrashDebugging.Aftermath.Markers` | 0 | ReadOnly | Aftermath 덤프에 draw 마커 포함. (`RHICoreNvidiaAftermath.cpp:63`) |
| `r.GPUCrashDebugging.Aftermath.Callstack` | 0 | ReadOnly | 콜스택 캡처. (`RHICoreNvidiaAftermath.cpp:70`) |
| `r.GPUCrashDebugging.Aftermath.ResourceTracking` | 1 | ReadOnly | 리소스 추적. (`RHICoreNvidiaAftermath.cpp:77`) |
| `r.GPUCrashDebugging.Aftermath.ShaderErrorReporting` | 0 | ReadOnly | 셰이더 오류 보고. (`RHICoreNvidiaAftermath.cpp:84`) |
| `r.GPUCrashDebugging.Aftermath.TrackAll` | 0 | ReadOnly | 최대 추적(상기 항목 모두 on). (`RHICoreNvidiaAftermath.cpp:91`) |
| `r.GPUCrashDebugging.Aftermath.ShaderRegistration` | 1 | ReadOnly | 셰이더/PSO 등록. |
| `r.GPUCrashDebugging.Aftermath.DumpShaderDebugInfo` | 0 | ReadOnly | `.nvdbg` 셰이더 디버그 정보 덤프(=> RenderDoc/Aftermath 셰이더 디버깅 핵심). |
| `r.GPUCrashDebugging.Aftermath.LateShaderAssociations.TimeLimit` | 7.5 | Default | 후행 셰이더 연관 분석 시간 제한(s). |
| `r.GPUCrashDebugging.Aftermath.LateShaderAssociations.FrameLimit` | 10 | Default | 동상, 프레임 제한. |
| `r.GPUCrashDebugging.Aftermath.DumpProcessWaitTime` | 10.0 | Default | Aftermath 덤프 처리 대기(s). |
| `r.GPUCrashDebugging.Aftermath.DumpStartWaitTime` | 3.0 | Default | Aftermath 덤프 시작 대기(s). |

### Frame Capture / 일반 (5)

| 이름 | 기본 | ECVF | 설명 / 위치 |
|---|---|---|---|
| `r.RHICmdBypass` | 0 | - | 1이면 RHI 커맨드 리스트 우회 → 즉시 실행. 멀티스레드 렌더링과 호환 안 됨. **로우레벨 그래픽스 API 호출 디버깅에 핵심**. (`Source/Runtime/RHI/Private/RHICommandList.cpp:53`) |
| `r.RHICmdWidth` | 8 | - | 병렬 렌더러 태스크 그래뉼래리티. (`RHICommandList.cpp:60`) |
| `r.RHICmd.ParallelTranslate.Enable` | true | - | RHI CmdList 병렬 변환. false면 RHI 스레드에서 직렬 변환(디버깅 용이). |
| `r.GPUCsvStatsEnabled` | 0 | - | CSV 통계 활성. (`Source/Runtime/RHI/Private/GPUProfiler.cpp:112`) |
| `r.D3D12.PreferredBarrierImplementation` | 1 | ReadOnly | 0=Default, 1=Legacy, 2=Enhanced 배리어. 디버깅 시 호환성 문제 회피용. |

> `r.GPUCapture.*` 네임스페이스의 cvar는 5.x 엔진 본체에 등록되어 있지 않다. 프로그램매틱 캡처는 `RenderCaptureInterface` (RenderCore) — RenderDoc/플랫폼 캡처를 추상화한 C++ API로, cvar 없이 코드에서 직접 호출한다.

---

## Part 3: 콘솔 명령 (cvar 아님)

총 **3** 개.

### 캡처 트리거

| 이름 | 인자 | 동작 / 위치 |
|---|---|---|
| `renderdoc.CaptureFrame` | (없음) | 다음 프레임을 캡처하고 RenderDoc UI를 띄운다. (`RenderDocPluginModule.cpp:309`, `FAutoConsoleCommand`) |
| `renderdoc.CapturePIE` | `[FrameCount]` | PIE 세션을 시작하면서 시작 프레임부터 N프레임을 캡처. WITH_EDITOR 한정. (`RenderDocPluginModule.cpp:316`, `FAutoConsoleCommandWithArgsDelegate`) |
| `DumpGPU` | `[-switch] [-key=value]` | 프레임 덤프. RDG의 `FRDGBuilder::BeginResourceDump`로 라우팅(StaticExec 경로). 인식 스위치: `-upload`, `-oneframe`. 임의의 `-Bar=Value`는 파라미터 맵에 들어간다. (`Source/Runtime/RenderCore/Private/DumpGPU.cpp:1979` 부근) |

> `PIXBeginCapture` / `PIXEndCapture` 같은 콘솔 명령은 UE 본체에 등록되어 있지 않다. PIX 캡처 시작은 PIX UI 또는 자체 단축키로 트리거하고, UE는 `WinPixGpuCapturer.dll` 로드 + 이벤트 마커만 제공한다.

### 디버그 출력

위 캡처 명령 외에 별도 등록된 GPU 디버깅 콘솔 명령은 발견되지 않음. 일반 `stat` / `Vis` / `ProfileGPU` 등은 RHI/RenderCore 공통이며 본 카탈로그 범위 밖.

### Crash 재현

전용 명령 없음. 재현은 `r.GPUCrashDebugging`을 켠 채 게임을 돌리며 자연스럽게 hang/crash 시점에 dump가 자동 생성된다. 강제 재현은 `r.RHICmdBypass=1` + 의심 패스만 실행 + 의도적 OOM(텍스처 풀 축소)으로 유도.

---

## Part 4: 셰이더 디버깅 연동

RenderDoc/Aftermath/PIX에서 HLSL 소스/심볼이 보이려면 **셰이더 디버그 정보**가 빌드 산출물에 포함되어야 한다. 본 카탈로그가 다루는 모듈에서 직접 등록하는 셰이더 디버그용 cvar는 다음과 같다.

| 이름 | 권장값 | 효과 |
|---|---|---|
| `r.GPUCrashDebugging.Aftermath.DumpShaderDebugInfo` | 1 | Aftermath 덤프 옆에 `.nvdbg` 동시 저장 → Nsight Graphics에서 셰이더 단계 추적. |
| `r.GPUCrashDebugging.Aftermath.ShaderRegistration` | 1 (기본) | 셰이더/PSO 등록. 비활성 시 마커가 셰이더 이름 없이 표기. |
| `r.GPUCrashDebugging.Aftermath.ShaderErrorReporting` | 1 | 셰이더 단계에서 발생한 에러를 Aftermath dump에 포함. |
| `r.D3D12.EnableD3DDebug` | 1~3 | D3D 디버그 레이어. RenderDoc/PIX 옆에서 켜면 Live Object 누수, 잘못된 상태 전이 검출. |

추가로 셰이더 디버그 정보를 빌드 산출물에 넣으려면 `Engine/Config/ConsoleVariables.ini` 또는 프로젝트 ini에서 `r.Shaders.SymbolPathOverride`, `r.Shaders.GenerateSymbols`, `r.Shaders.ExtraData`(엔진 공용, 본 모듈 외)를 활성화한다(범위 외).

RenderDoc에서 HLSL 디버깅 절차:
1. 위 셰이더 심볼 cvar들을 켠 빌드로 게임/에디터 실행.
2. `renderdoc.CaptureFrame`으로 캡처.
3. RenderDoc Texture Viewer/Pipeline에서 픽셀 → **Debug Pixel** 클릭. 빌드에 PDB가 있으면 자동 매칭.

---

## Part 5: 외부 도구 다운로드/연결

| 도구 | 다운로드 | UE 측 연결 지점 | 주요 cvar / 명령 |
|---|---|---|---|
| RenderDoc | https://renderdoc.org/ | `RenderDocPlugin` (DLL: `renderdoc.dll` / `librenderdoc.so`) | `renderdoc.AutoAttach`, `renderdoc.CaptureFrame`, `renderdoc.BinaryPath` |
| PIX on Windows | https://devblogs.microsoft.com/pix/ | `WindowsD3D12Device.cpp` (DLL: `WinPixGpuCapturer.dll`, `D3D12RHI_SUPPORTS_WIN_PIX`) | `r.D3D12.AutoAttachPIX`, 커맨드라인 `-attachPIX` |
| RGP (Radeon GPU Profiler) | https://gpuopen.com/rgp/ | `D3D12CommandContext.cpp`의 `D3D12.EmitRgpFrameMarkers` + Radeon Developer Panel | `D3D12.EmitRgpFrameMarkers=1` (디바이스 생성 전) |
| NVIDIA Aftermath / Nsight | https://developer.nvidia.com/nvidia-aftermath, Nsight Graphics | `RHICoreNvidiaAftermath.cpp`, `D3D12NvidiaExtensions.cpp` (`GFSDK_Aftermath_*`) | `r.GPUCrashDebugging=1`, `r.GPUCrashDebugging.Aftermath.*` |
| Microsoft DRED | Windows 10 1903+ 내장(설치 불필요) | `D3D12Adapter.cpp` (`r.D3D12.DRED`, `r.D3D12.LightweightDRED`) | `r.D3D12.DRED=1` |
| GPUDumpViewer (DumpGPU) | 엔진 내장. 빌드 시 `RenderCore.Build.cs`가 산출물에 복사 | `RenderCore/Private/DumpGPU.cpp` | `DumpGPU` 명령, `r.DumpGPU.*` |

매칭 매트릭스:

| 시나리오 | 도구 / cvar 조합 |
|---|---|
| 일반 프레임 분석 | RenderDoc + `renderdoc.CaptureFrame` |
| D3D12 저수준 분석 | PIX + `r.D3D12.AutoAttachPIX=1` |
| AMD 프로파일링 | RGP + `D3D12.EmitRgpFrameMarkers=1` |
| GPU Hang/Crash | `r.GPUCrashDebugging=1` (+ Aftermath/DRED) |
| Hang 직전 패스 식별만 필요 | `r.GPUCrashDebugging.Breadcrumbs=1` (벤더 무관, 기본 on) |
| RDG 리소스 시각화 | `DumpGPU` + GPUDumpViewer |
| 멀티스레드 RHI 의심 아티팩트 | `r.RHICmdBypass=1` |
| D3D 호출 검증 | `r.D3D12.EnableD3DDebug=2` 이상 |

---

## Part 6: 참고 파일 위치

베이스: `/mnt/c/Users/admin/source/repos/UnrealEngine/Engine/`

- [Plugins/Developer/RenderDocPlugin/Source/RenderDocPlugin/Private/RenderDocPluginLoader.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/Developer/RenderDocPlugin/Source/RenderDocPlugin/Private/RenderDocPluginLoader.cpp) — `renderdoc.AutoAttach/EnableCrashHandler/BinaryPath`, DLL 로드.
- [Plugins/Developer/RenderDocPlugin/Source/RenderDocPlugin/Private/RenderDocPluginModule.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/Developer/RenderDocPlugin/Source/RenderDocPlugin/Private/RenderDocPluginModule.cpp) — 캡처 옵션 cvar들, `renderdoc.CaptureFrame/CapturePIE` 콘솔 명령.
- [Plugins/Developer/RenderDocPlugin/Source/RenderDocPlugin/Private/SRenderDocPluginHelpWindow.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Plugins/Developer/RenderDocPlugin/Source/RenderDocPlugin/Private/SRenderDocPluginHelpWindow.cpp) — `renderdoc.ShowHelpOnStartup`.
- [Source/Runtime/RHI/Private/RHI.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RHI/Private/RHI.cpp) — `r.GPUCrashDebugging`, `r.GPUCrashDebugging.Breadcrumbs`, `r.GPUCrashOnOutOfMemory`, `UseGPUCrashDebugging`/`ShouldEnableGPUCrashFeature`.
- [Source/Runtime/RHI/Private/RHICommandList.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RHI/Private/RHICommandList.cpp) — `r.RHICmdBypass`, `r.RHICmdWidth`, `r.RHICmd.ParallelTranslate.*`.
- [Source/Runtime/RHI/Private/GPUProfiler.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RHI/Private/GPUProfiler.cpp) — `r.GPUCsvStatsEnabled`.
- [Source/Runtime/RHI/Private/Windows/WindowsDynamicRHI.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RHI/Private/Windows/WindowsDynamicRHI.cpp) — `r.GPUCrashDebugging` 적용 시점.
- [Source/Runtime/RHICore/Private/RHICoreNvidiaAftermath.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RHICore/Private/RHICoreNvidiaAftermath.cpp) — Aftermath cvar 13종.
- [Source/Runtime/D3D12RHI/Private/D3D12Adapter.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/D3D12RHI/Private/D3D12Adapter.cpp) — `r.D3D12.EnableD3DDebug`, `r.D3D12.DRED`, `r.D3D12.LightweightDRED`, `r.D3D12.PreferredBarrierImplementation`.
- [Source/Runtime/D3D12RHI/Private/D3D12CommandContext.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/D3D12RHI/Private/D3D12CommandContext.cpp) — `D3D12.EmitRgpFrameMarkers`, `D3D12.UnsafeCrossGPUTransfers`.
- [Source/Runtime/D3D12RHI/Private/D3D12NvidiaExtensions.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/D3D12RHI/Private/D3D12NvidiaExtensions.cpp) — Aftermath D3D12 핸들/마커.
- [Source/Runtime/D3D12RHI/Private/Windows/WindowsD3D12Device.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/D3D12RHI/Private/Windows/WindowsD3D12Device.cpp) — `r.D3D12.AutoAttachPIX`, `PIXLoadLatestWinPixGpuCapturerLibrary`.
- [Source/Runtime/RenderCore/Private/DumpGPU.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RenderCore/Private/DumpGPU.cpp) — 모든 `r.DumpGPU.*` cvar와 `DumpGPU` 명령 파서(`FRDGBuilder::BeginResourceDump`).
- [Source/Runtime/RenderCore/Private/RenderCaptureInterface.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RenderCore/Private/RenderCaptureInterface.cpp) — 코드용 캡처 트리거 API.
- [Source/Runtime/RenderCore/RenderCore.Build.cs](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RenderCore/RenderCore.Build.cs) — GPUDumpViewer 소스 복사.
