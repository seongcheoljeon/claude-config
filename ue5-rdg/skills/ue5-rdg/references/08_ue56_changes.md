# UE5.6+ RDG 변경사항

> **참고**: UE5.6은 2025년 기준 최신 버전. 아래 항목은 확인된 변경사항 기반.
> 불확실한 항목은 별도 표시.

---

## UE5.3+ 주요 변경

### FRDGBuilder 병렬 실행 안정화
```cpp
// ERDGBuilderFlags::AllowParallelExecute 실용화
FRDGBuilder GraphBuilder(RHICmdList, RDG_EVENT_NAME(""), ERDGBuilderFlags::AllowParallelExecute);
```

### FSceneTextures 통합
```cpp
// UE5.3+: FSceneTextures::Get() 패턴
const FSceneTextures& SceneTextures = FSceneTextures::Get(GraphBuilder);
FRDGTextureRef SceneColor = SceneTextures.Color.Resolve;
FRDGTextureRef SceneDepth = SceneTextures.Depth.Resolve;
```

### RDG Buffer Upload
```cpp
// UE5.3+: QueueBufferUpload 정식화
GraphBuilder.QueueBufferUpload(Buffer, Data, DataSize, ERDGInitialDataFlags::NoCopy);
```

---

## UE5.4+ 주요 변경

### Nanite Rasterization Pass 변경
- Nanite Visibility Buffer 접근 방식 변경.
- `FNaniteVisibilityResults` → `GetNaniteVisibility()` API 변경.

### FRDGTextureDesc 생성자 변경
```cpp
// UE5.4+: NumMips 기본값 변경에 주의
FRDGTextureDesc Desc = FRDGTextureDesc::Create2D(
    Extent, Format, ClearValue, Flags,
    1,   // NumMips — 명시 권장
    1    // NumSamples
);
```

---

## UE5.5+ 주요 변경

### Substrate (이전 Strata) 머티리얼 시스템
- GBuffer 레이아웃 변경 가능성.
- `r.Substrate 1` 활성화 시 GBuffer 접근 방식 달라짐.
- `FSubstrateGBufferData` 관련 API 확인 필요.

### FRHIBatchedShaderParameters (UE5.5)
```cpp
// UE5.5+: SetShaderParameters 내부 배칭 방식 변경
// FComputeShaderUtils::AddPass는 자동 처리 — 직접 SetShaderParameters 사용 시 확인
```

---

## UE5.7 확정 변경사항 (2025년 11월 출시)

> 출처: [UE5.7 Release Notes](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-7-release-notes)

### ★ Substrate Production-Ready + 기본 활성화
**RDG 프로그래머에게 가장 큰 변경사항.**
- Substrate가 기본값(ON)으로 변경됨 → GBuffer 접근 패턴 변경 필수
- Adaptive GBuffer: 픽셀마다 가변 Bitstream 레이아웃
- Blendable GBuffer: 기존 레이아웃 유사 (하위 호환)
- 자세한 바인딩 패턴 → `references/15_substrate_ue57.md`

### MegaLights (Beta)
- Directional Light, Niagara Particle Lights, Translucency, Hair Strands 지원 추가
- 커스텀 PostProcess Pass와 충돌 여부 주의

### Nanite Foliage / Nanite Voxels (Experimental)
- Nanite Voxels: 원거리 식생을 픽셀 크기 Voxel로 렌더링
- 커스텀 렌더 패스에서 Nanite Visibility Buffer 접근 방식 확인 필요

### SMAA Anti-Aliasing (Experimental)
- `r.AntiAliasingMethod=5` 로 활성화
- 커스텀 PostProcess 체인과 순서 충돌 가능성 확인 필요

### PCG Framework Production-Ready
- RDG와 직접 관련 없음, 성철님 PCG 작업에 참고

---

## UE5.6 확정 변경사항 (2025년 중반)

## 버전별 체크 매크로

```cpp
#if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 7
    // UE5.7+ (Substrate 기본 활성화)
#elif ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 5
    // UE5.5+ 코드
#elif ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 3
    // UE5.3+ 코드
#endif

// Substrate 런타임 확인
bool bSubstrate = Substrate::IsSubstrateEnabled();
```

---

## 항상 확인해야 할 소스 위치

| 주제 | 경로 |
|------|------|
| RDGBuilder API | `Engine/Source/Runtime/RenderCore/Public/RenderGraphBuilder.h` |
| RDGResources | `Engine/Source/Runtime/RenderCore/Public/RenderGraphResources.h` |
| SceneTextures | `Engine/Source/Runtime/Renderer/Public/SceneTextures.h` |
| SVE Interface | `Engine/Source/Runtime/Engine/Public/SceneViewExtension.h` |
| ComputeShaderUtils | `Engine/Source/Runtime/RenderCore/Public/RenderGraphUtils.h` |
| ScreenPass | `Engine/Source/Runtime/Renderer/Public/ScreenPass.h` |
| ShaderParameterMacros | `Engine/Source/Runtime/RenderCore/Public/ShaderParameterMacros.h` |
