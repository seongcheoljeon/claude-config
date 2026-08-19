# UnrealEngine Material 시스템 개발자 레퍼런스

> 대상 엔진: **UE 5.7.4** (`/mnt/c/Users/admin/source/repos/UnrealEngine/`)
> 인덱스 기준: `Engine/Source/Runtime/Engine/Private/Materials/`, `MaterialShared.cpp`, `Renderer/Private/MaterialCache/`, `Core/Private/HAL/ConsoleManager.cpp`, `RenderCore/Private/Shader.cpp`

---

## Part 1: 시나리오별 cvar 추천

### 머티리얼 컴파일 디버깅
| 상황 | cvar | 권장값 |
|---|---|---|
| 컴파일 실패를 워닝이 아닌 에러로 띄우기 | `r.MaterialLogErrorOnFailure` | `1` |
| HLSL 패널 끝에 preshader/파라미터 참조 카운트 표시 | `r.MaterialEditor.PreshaderDumpToHLSL` | `1` (기본) |
| 펜덴틱 에러 체크 활성 | `r.Material.PedanticErrorChecksEnabled` | `1` |
| 머티리얼 별 ShaderMap 텍스트 덤프 (DDC 키 기반) | `r.Material.ShaderMapDump` | `<MaterialPath>` |
| 특정 에셋의 DDC 키 해시 출력 | `r.ShaderCompiler.DebugDDCKeyAsset` | `<AssetName>` |
| 쿡 시 머티리얼 번역 시간 CSV 로그 | `r.Material.EnableTranslationLogFile` | `1` |
| 분석적 미분 활성화 | `r.MaterialEditor.AnalyticDeriv` | `1` (기본) |
| 잘못된 미분에 `$` 토큰 마킹 | `r.MaterialEditor.AnalyticDeriv.DebugEmitInvalidDerivTokens` | `1` |

### 신규 머티리얼 번역기 활용 (UE 5.7~)
| 목적 | cvar | 값 |
|---|---|---|
| **신규 IR 기반 번역기 활성화** | `r.Material.Translator.EnableNew` | `1` |
| 번역기 IR 모듈 덤프 (`Saved/Materials/IRDump.txt`) | `r.Material.Translator.DebugDump` | `1` 또는 `2` |
| 'Uses' 그래프에 `Instruction Next` 엣지 추가 | `r.Material.Translator.DumpUseGraphOpts.EnableSuccessors` | `1` |
| IR Poison 값 만나면 디버거 break | `r.Material.Translator.DebugBreakOnPoison` | `1` |

### 품질 레벨 강제 (테스트)
| 상황 | cvar | 값 |
|---|---|---|
| 글로벌 품질 레벨 (low/high/medium/Epic) | `r.MaterialQualityLevel` | `0~3` |
| 미사용 품질 레벨 셰이더맵 메모리 폐기 | `r.DiscardUnusedQuality` | `0`(유지)/`1`(폐기) |
| 셰이딩 패스(Deferred/Forward/Mobile) 강제 | `r.Material.ShadingPathNodeOverride` | `-1`/`0`/`1`/`2` |

### 머티리얼 에디터 프리뷰 문제
| 상황 | cvar | 값 |
|---|---|---|
| LWC(Large World Coordinates) 사용 | `r.MaterialEditor.LWCEnabled` | `1` (기본) |
| Preshader 코멘트 추가 | `r.MaterialEditor.PreshaderDumpToHLSL` | `1` |
| 분석 미분 코드 제너레이션 | `r.MaterialEditor.AnalyticDeriv` | `1` |

### 머티리얼 캐시 / 무효화
| 상황 | cvar | 값 |
|---|---|---|
| Duplicate 시 StateId 유지 (DDC 키 보존) | `r.MaterialsDuplicateVerbatim` | `1` |
| 텍스처 샘플링 스트리밍 캐시 | `r.Streaming.EnableTexturesSamplingStreamingCache` | `1` |
| Uniform Expression 캐시 갱신 지연 | `r.DeferUniformExpressionCaching` | `1` (기본) |
| Uniform Expression 캐시 비동기 업데이트 | `r.UniformExpressionCacheAsyncUpdates` | `1` (기본) |
| MaterialCache 명령 캐싱 | `r.MaterialCache.CommandCaching` | `1` |

---

## Part 2: cvar 전체 카탈로그

### Translator (HLSL 기존 + 신규 IR)
| cvar | 기본값 | 타입 | ECVF | 위치 | 한 줄 요약 |
|---|---|---|---|---|---|
| `r.Material.EnableTranslationLogFile` | `false` | bool | `ReadOnly` | `Materials/HLSLMaterialTranslator.cpp:89` | 쿡 시 머티리얼 번역 시간 CSV 로그 생성 |
| `r.Material.PedanticErrorChecksEnabled` | `false` | bool | - | `Materials/HLSLMaterialTranslator.cpp:179` | 펜덴틱 에러 검사 활성 |
| `r.Material.CullIntermediateUniformExpressions` | `true` | bool | - | `Materials/HLSLMaterialTranslator.cpp:185` | 중간 유니폼 식 컬링 → preshader 수 감소 |
| `r.Material.PreshaderGapInterval` | `32` | int32 | - | `Materials/HLSLMaterialTranslator.cpp:191` | 셰이더 컴파일러 레지스터 오버플로 워크어라운드 |
| `r.Shaders.SDCE` | `true` | bool | - | `Materials/HLSLMaterialTranslator.cpp:81` | 구조 멤버 스토어 dead-code 제거 |
| `r.Material.Translator.EnableNew` | `false` | bool | `RenderThreadSafe` | `Materials/MaterialShared.cpp:106` | **신규 IR 번역기 프로토타입 활성** |
| `r.Material.Translator.DebugDump` | `0` | int32 | `RenderThreadSafe` | `Materials/MaterialIRModuleBuilder.cpp:36` | IR 덤프 (0 없음 / 1 텍스트 / 2 + Use 그래프) |
| `r.Material.Translator.DebugBreakOnPoison` | `0` | bool | `Default` | `Materials/MaterialIREmitter.cpp:22` | IR Poison 값 시 디버거 break |
| `r.Material.Translator.DumpUseGraphOpts.EnableSuccessors` | `false` | bool | `RenderThreadSafe` | `Materials/MaterialIRDebug.cpp:16` | Use 그래프에 Instruction Next 엣지 표시 |

### Compilation
| cvar | 기본값 | 타입 | ECVF | 위치 | 한 줄 요약 |
|---|---|---|---|---|---|
| `r.MaterialLogErrorOnFailure` | `false` | bool | `RenderThreadSafe` | `Materials/Material.cpp:120` | 컴파일 실패를 Warning이 아닌 Error로 표시 |
| `r.Material.ExcludeNonPipelinedShaders` | `1` | int32 | `ReadOnly\|RenderThreadSafe` | `Materials/MaterialShader.cpp:63` | 파이프라인에 포함된 standalone 셰이더는 컴파일 안 함 |
| `r.Material.ShaderMapDump` | `""` | FString | `ReadOnly` | `Materials/MaterialShader.cpp:70` | 지정 머티리얼의 모든 셰이더맵을 `Saved/MaterialShaderMaps`에 텍스트로 덤프 |
| `r.ShaderCompiler.DebugDDCKeyAsset` | `""` | FString | `Default` | `Materials/MaterialShader.cpp:79` | 지정 이름 포함 에셋의 DDC 키 해시 출력 (Editor) |
| `r.CompileMaterialsForShaderFormat` | `""` | FString | - | `Materials/Material.cpp:2564` | 추가 셰이더 포맷용으로 머티리얼 컴파일 (덤프 후 폐기) |
| `r.MaterialsDuplicateVerbatim` | `false` | bool | `Default` | `Materials/Material.cpp:127` | Duplicate 시 StateId 변경 방지 (DDC 키 영향 ↓) |

### Quality Level
| cvar | 기본값 | 타입 | ECVF | 위치 | 한 줄 요약 |
|---|---|---|---|---|---|
| `r.MaterialQualityLevel` | `1` | int32 | `Scalability\|RenderThreadSafe` | `Core/Private/HAL/ConsoleManager.cpp:4032` | 머티리얼 QualitySwitch (0=Low, 1=High, 2=Medium, 3=Epic) |
| `r.DiscardUnusedQuality` | `0` | int32 | `ReadOnly` | `Materials/Material.cpp:814` | 미사용 품질 레벨 셰이더맵을 로드 시 폐기 |
| `r.Material.ShadingPathNodeOverride` | `-1` | int32 | `ReadOnly\|Preview\|RenderThreadSafe` | `Core/Private/HAL/ConsoleManager.cpp:4038` | 셰이딩 패스 override (-1 없음, 0 deferred, 1 forward, 2 mobile) |

### Material Editor
| cvar | 기본값 | 타입 | ECVF | 위치 | 한 줄 요약 |
|---|---|---|---|---|---|
| `r.MaterialEditor.PreshaderDumpToHLSL` | `true` | bool | `RenderThreadSafe` | `Materials/MaterialShared.cpp:98` | HLSL 패널 끝에 preshader/파라미터 참조 카운트 코멘트 추가 |
| `r.MaterialEditor.LWCEnabled` | `1` | int32 | - | `Materials/HLSLMaterialTranslator.cpp:172` | 머티리얼 LWC 값 생성 활성 (꺼지면 float 정밀도) |
| `r.MaterialEditor.LWCTruncateMode` | int32 | - | - | (참조: `Materials/MaterialShader.cpp:657`, 정의는 `MaterialTranslatorUtils`) | LWC truncate 모드 (1, 2 = 자동/조건부 허용) |
| `r.MaterialEditor.AnalyticDeriv` | `1` | int32 | - | `Materials/HLSLMaterialTranslator.cpp:150` | 분석 미분 코드 제너레이션 활성 (Editor only) |
| `r.MaterialEditor.AnalyticDeriv.DebugTextureSample` | `0` | int32 | - | `Materials/HLSLMaterialTranslator.cpp:158` | 텍스처 샘플링 디버그 인스트루먼트 (`r.GeneralPurposeTweak`로 제어) |
| `r.MaterialEditor.AnalyticDeriv.DebugEmitInvalidDerivTokens` | `0` | int32 | - | `Materials/HLSLMaterialTranslator.cpp:165` | 잘못된 미분 표현식에 `$` 토큰 마킹 |
| `r.MaterialEditor.AnalyticDeriv.DebugGenerateAllFunctions` | `0` | int32 | - | `Materials/HLSLMaterialDerivativeAutogen.cpp:10` | 모든 미분 함수 강제 생성 (디버그) |

### Caching / DDC
| cvar | 기본값 | 타입 | ECVF | 위치 | 한 줄 요약 |
|---|---|---|---|---|---|
| `r.DeferUniformExpressionCaching` | `1` | int32 | `RenderThreadSafe` | `Materials/MaterialRenderProxy.cpp:26` | 유니폼 식 캐싱을 렌더 명령 시점까지 지연 (다중 SetParam 합치기) |
| `r.UniformExpressionCacheAsyncUpdates` | `1` | int32 | `RenderThreadSafe` | `Materials/MaterialRenderProxy.cpp:34` | 유니폼 식 캐시 비동기 업데이트 허용 |
| `r.Streaming.EnableTexturesSamplingStreamingCache` | `false` | bool | `Default` | `Materials/MaterialInterface.cpp:2223` | 머티리얼 텍스처 샘플링 캐싱 (cooked + 텍스처 스트리밍 전용) |

### MaterialCache (Renderer 5.7)
| cvar | 기본값 | 타입 | ECVF | 위치 | 한 줄 요약 |
|---|---|---|---|---|---|
| `r.MaterialCache.StaticMesh.EnableViewportFromVS` | `true` | bool | `RenderThreadSafe\|Scalability` | `Renderer/Private/MaterialCache/MaterialCacheRenderer.cpp:35` | VS의 RT array index 지원 시 정적 unwrap 슬라이스 렌더 |
| `r.MaterialCache.VertexInvariant.Enable` | `true` | bool | `RenderThreadSafe\|Scalability` | `Renderer/Private/MaterialCache/MaterialCacheRenderer.cpp:44` | UV 파생/vertex-invariant 머티리얼만 compute-shading |
| `r.MaterialCache.CommandCaching` | `false` | bool | `RenderThreadSafe\|Scalability` | `Renderer/Private/MaterialCache/MaterialCacheRenderer.cpp:53` | 메시 명령 + 레이어 셰이딩 명령 캐싱 |

### Shader Pipelines (관련)
| cvar | 기본값 | 타입 | ECVF | 위치 | 한 줄 요약 |
|---|---|---|---|---|---|
| `r.ShaderPipelines` | `1` | int32 | - | `RenderCore/Private/Shader.cpp:87` | 셰이더 파이프라인 사용 활성 |

### Other (관련 영역)
| cvar | 기본값 | 타입 | ECVF | 위치 | 한 줄 요약 |
|---|---|---|---|---|---|
| `r.MaterialQualityLevel` (별도 헬퍼) | - | - | - | `LevelEditor/Private/LevelEditorActions.cpp:768` | Editor에서 Feature Level Preview 우선순위 처리 |

> 참고: `r.PreviewShaderCompile*` 패밀리는 UE 5.7.4 본 트리에서 정의를 찾을 수 없었습니다 (도큐먼트/플러그인/커스텀 빌드에 한정 존재 가능). UMaterial 프리뷰 셰이더 흐름은 `MaterialShader`/`MaterialShared` 경로를 사용합니다.

---

## Part 3: 머티리얼 작성 시 알아둘 것

### Custom Expression의 cvar 영향
- `r.Material.PedanticErrorChecksEnabled = 1`은 Custom 노드의 HLSL 검증을 더 엄격히 만듭니다.
- `r.MaterialEditor.PreshaderDumpToHLSL = 1`로 HLSL 패널 끝에 expression 참조 카운트가 표시되어 Custom 식이 어떻게 inline되는지 검증 가능.
- `r.Material.CullIntermediateUniformExpressions`이 켜져 있으면 Custom 노드에서 사용하지 않는 입력의 preshader 비용이 자동 제거됩니다.

### 동적 분기 (Static Switch vs Dynamic Branch) cvar
- **Static Switch**는 컴파일 시점 분기 → `r.MaterialQualityLevel` 변경 시 셰이더맵을 재컴파일 (DDC 키 변화).
- **Dynamic Branch**는 런타임 분기 → 셰이더맵 단일, `r.DiscardUnusedQuality = 1` 사용 시 메모리 절약 효과 ↓.
- `r.Material.ShadingPathNodeOverride`는 ShadingPath 노드를 조건 강제 (디버그용, ECVF_ReadOnly).

### Material Function cvar
- Material Function 자체에 직접 영향을 주는 cvar는 없으나, `r.MaterialsDuplicateVerbatim = 1`은 함수 복제 시 StateId 변경을 막아 DDC를 보존합니다 — 라이브러리화 시 유용.
- `r.MaterialEditor.AnalyticDeriv` 계열은 함수 내부의 미분 코드 생성에도 영향.

---

## Part 4: 신규 Translator (UE 5.7~) 상세

### `r.Material.Translator.EnableNew = 1` 켰을 때의 차이
정의: `Materials/MaterialShared.cpp:106` (`CVarUsingUseNewMaterialTranslatorPrototype`).
참조: `Materials/MaterialExpressions.cpp:14277`, `Materials/MaterialInterface.cpp:300`.

```cpp
bool IsUsingNewMaterialTranslatorPrototype()
{
    return CVarUsingUseNewMaterialTranslatorPrototype.GetValueOnAnyThread();
}
```

- **기존(HLSL 기반)**: `HLSLMaterialTranslator`가 직접 HLSL 텍스트를 emit. 검증·최적화 한계.
- **신규(IR 기반)**: `MaterialIREmitter` → `MaterialIRModuleBuilder` 경로로 IR을 먼저 만들고, IR을 통해 SSA 형태로 분석/덤프 가능. `MaterialExpressionsIR.cpp`에 IR 전용 표현식 구현이 분리됨.
- 결과적으로 `r.Material.Translator.DebugDump`로 SSA-스타일 IR을 텍스트(`IRDump.txt`)와 그래프(`IRDumpUseGraph.dot`)로 받을 수 있습니다.

### `DebugDump`, `DebugBreakOnPoison` 사용법

**IRDump 추출**
```text
r.Material.Translator.EnableNew 1
r.Material.Translator.DebugDump 2
```
머티리얼 컴파일 후 `<Project>/Saved/Materials/`에 다음 두 파일 생성:
- `IRDump.txt` — IR 인스트럭션의 사람이 읽을 수 있는 표현
- `IRDumpUseGraph.dot` — Graphviz 'Uses' 그래프 (Graphviz로 PNG/SVG 변환 가능)

추가:
```text
r.Material.Translator.DumpUseGraphOpts.EnableSuccessors 1
```
→ 그래프에 `Instruction Next` 엣지 표시.

**Poison 값 디버깅**
```text
r.Material.Translator.DebugBreakOnPoison 1
```
IR Emitter가 poison(미정의/오류) 값을 만나면 즉시 디버거 break — 어떤 표현식이 잘못 번역되었는지 콜스택으로 추적.

---

## Part 5: 참고 파일 위치

### 핵심 cpp (절대 경로)
- [Materials/HLSLMaterialTranslator.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/HLSLMaterialTranslator.cpp) — 기존 HLSL 번역기, SDCE / Translator log / LWC / AnalyticDeriv / Pedantic / Cull / PreshaderGap cvar
- [Materials/MaterialShared.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/MaterialShared.cpp) — `r.Material.Translator.EnableNew`, `r.MaterialEditor.PreshaderDumpToHLSL`
- [Materials/MaterialIRModuleBuilder.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/MaterialIRModuleBuilder.cpp) — `r.Material.Translator.DebugDump`
- [Materials/MaterialIREmitter.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/MaterialIREmitter.cpp) — `r.Material.Translator.DebugBreakOnPoison`
- [Materials/MaterialIRDebug.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/MaterialIRDebug.cpp) — `r.Material.Translator.DumpUseGraphOpts.EnableSuccessors`
- [Materials/Material.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/Material.cpp) — `r.MaterialLogErrorOnFailure`, `r.MaterialsDuplicateVerbatim`, `r.DiscardUnusedQuality`, `r.CompileMaterialsForShaderFormat`
- [Materials/MaterialShader.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/MaterialShader.cpp) — `r.Material.ExcludeNonPipelinedShaders`, `r.Material.ShaderMapDump`, `r.ShaderCompiler.DebugDDCKeyAsset`
- [Materials/MaterialRenderProxy.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/MaterialRenderProxy.cpp) — `r.DeferUniformExpressionCaching`, `r.UniformExpressionCacheAsyncUpdates`
- [Materials/MaterialInterface.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/MaterialInterface.cpp) — `r.Streaming.EnableTexturesSamplingStreamingCache`
- [Materials/HLSLMaterialDerivativeAutogen.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/HLSLMaterialDerivativeAutogen.cpp) — `r.MaterialEditor.AnalyticDeriv.DebugGenerateAllFunctions`
- [Core/Private/HAL/ConsoleManager.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Core/Private/HAL/ConsoleManager.cpp) — `r.MaterialQualityLevel`, `r.Material.ShadingPathNodeOverride` (~L4032)
- [Renderer/Private/MaterialCache/MaterialCacheRenderer.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Renderer/Private/MaterialCache/MaterialCacheRenderer.cpp) — `r.MaterialCache.*`
- [RenderCore/Private/Shader.cpp](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/RenderCore/Private/Shader.cpp) — `r.ShaderPipelines`

### 엔진 버전
```text
ENGINE_MAJOR_VERSION 5
ENGINE_MINOR_VERSION 7
ENGINE_PATCH_VERSION 4
```

### 검색 명령 (재현용)
```bash
# 머티리얼 디렉토리 전체
grep -rn -E 'TAutoConsoleVariable|FAutoConsoleVariable' \
  /mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/

# r.Material* / r.Materials* 명명
grep -rn -E '"r\.Material[s.]?[A-Za-z]+' \
  /mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Source/Runtime/Engine/Private/Materials/
```
