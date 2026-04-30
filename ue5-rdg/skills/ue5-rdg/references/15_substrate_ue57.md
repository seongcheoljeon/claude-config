# Substrate GBuffer (UE5.7 기본값)

> **⚠️ Breaking Change**: UE5.7부터 Substrate가 기본 활성화.
> GBuffer 접근 방식이 달라짐 — 기존 `GBufferATexture` 직접 바인딩 패턴 검토 필요.
>
> 출처: [UE5.7 Release Notes](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-7-release-notes),
> [Programming with Substrate GBuffer Formats](https://dev.epicgames.com/documentation/en-us/unreal-engine/programming-with-substrate-gbuffer-formats)

---

## Substrate의 두 가지 GBuffer 모드

| 모드 | 특징 | 활성 조건 |
|------|------|-----------|
| **Blendable GBuffer** | 기존 GBuffer와 유사한 고정 레이아웃 | 하위 호환, 저사양 플랫폼 |
| **Adaptive GBuffer** | 픽셀마다 가변 Bitstream 레이아웃 | 최신 하드웨어, 고품질 |

현재 모드 확인: `r.Substrate.UsesComplexSpecialRenderPath`

---

## Global Shader에서 Substrate GBuffer 접근

### ✅ UE5.7+ 올바른 방법

```cpp
// 1. Parameters 구조체에 Substrate UB 선언
BEGIN_SHADER_PARAMETER_STRUCT(FParameters, )
    // ... 기타 파라미터 ...
    SHADER_PARAMETER_RDG_UNIFORM_BUFFER(FSubstrateGlobalUniformParameters, Substrate)
END_SHADER_PARAMETER_STRUCT()

// 2. 바인딩 (C++)
FMyCS::FParameters* Params = GraphBuilder.AllocParameters<FMyCS::FParameters>();
Params->Substrate = Substrate::BindSubstrateGlobalUniformParameters(View);
```

### USF에서 접근

```hlsl
#include "/Engine/Private/Substrate/SubstrateEvaluation.ush"

void MyShader(uint2 PixelPos)
{
#if SUBSTRATE_LOAD_FROM_MATERIALCONTAINER
    // Adaptive GBuffer (UE5.7 기본)
    FSubstrateAddressing Addressing = GetSubstratePixelDataByteOffset(
        PixelPos,
        uint2(View.BufferSizeAndInvSize.xy),
        Substrate.MaxBytesPerPixel
    );
    FSubstratePixelHeader Header = UnpackSubstrateHeaderIn(
        Substrate.MaterialTextureArray,
        Addressing,
        Substrate.TopLayerTexture
    );
    // Header에서 클로저 데이터 접근
#else
    // Blendable GBuffer
    FSubstrateGBufferBSDF Data = SubstrateReadGBufferBSDF(
        GetScreenSpaceDataUint(PixelPos));
#endif
}
```

### SceneTextureLookup() — 호환 유지

```hlsl
// 두 모드 모두 동작하지만, Adaptive GBuffer에서는 첫 번째 클로저만 반환
float4 GBufferData = SceneTextureLookup(UV, PPI_WorldNormal, false);
// 단순 법선/거칠기 등 단일 값 접근 시 여전히 사용 가능
```

---

## 기존 GBuffer 텍스처 직접 바인딩 (주의)

```cpp
// ❌ UE5.7 이전 패턴 — Adaptive GBuffer에서 GBufferA가 없을 수 있음
SHADER_PARAMETER_RDG_TEXTURE(Texture2D, GBufferATexture)  // 위험

// ✅ Blendable GBuffer 전용 플래그를 확인하고 사용
// r.Substrate.BlendableGBuffer 1 강제 시에만 안전
```

---

## FSceneTextures 접근 (PostProcess / SVE)

```cpp
// PrePostProcessPass_RenderThread에서
const FSceneTextures& SceneTextures = FSceneTextures::Get(GraphBuilder);

// UE5.7: Substrate 활성화 시 일부 GBuffer 텍스처 레이아웃 변경
// SceneTextures.GBufferA/B/C 대신 Substrate 전용 텍스처 참조
FRDGTextureRef SubstrateTopLayer   = SceneTextures.SubstrateTopLayerTexture;
FRDGTextureRef SubstrateMaterial   = SceneTextures.SubstrateMaterialTextureArray; // Adaptive
```

---

## 버전 분기 패턴

```cpp
// C++ 조건부 컴파일
#if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 7
    // UE5.7+ Substrate 기본 활성화
    Params->Substrate = Substrate::BindSubstrateGlobalUniformParameters(View);
#else
    // UE5.6 이하 — 기존 GBuffer 직접 바인딩
    Params->GBufferATexture = SceneTextures.GBufferA;
#endif
```

```hlsl
// USF 조건부 분기
#if SUBSTRATE_LOAD_FROM_MATERIALCONTAINER
    // Adaptive GBuffer 경로
#elif SUBSTRATE_ENABLED
    // Blendable GBuffer 경로
#else
    // 레거시 GBuffer 경로 (UE5.6 이하)
#endif
```

---

## Substrate 비활성화 (레거시 프로젝트 마이그레이션)

```
r.Substrate 0
```
> **주의**: UE5.7에서는 Substrate가 기본값. `0`으로 끄면 일부 기능(MegaLights 등)이 제한될 수 있음.

---

## MegaLights (Beta, UE5.7)

RDG Custom Pass에서 MegaLights 데이터 접근 시:
- Directional Light / Niagara Particle Lights / Translucency / Hair Strands 지원 추가
- 커스텀 Lighting Pass에서 MegaLights와 충돌 방지: `PrePostProcessPass` 이후 삽입 권장

---

## UE5.7 버전 체크 매크로

```cpp
#if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 7
    // UE5.7+ 전용 코드
#endif

// 또는 Substrate 활성화 여부 런타임 확인
bool bSubstrateEnabled = Substrate::IsSubstrateEnabled();
```

---

## 엔진 소스 참조

| 주제 | 경로 |
|------|------|
| Substrate 바인딩 | `Engine/Source/Runtime/Renderer/Private/Substrate/Substrate.h` |
| SubstrateEvaluation | `Engine/Shaders/Private/Substrate/SubstrateEvaluation.ush` |
| FSubstrateGlobalUniformParameters | `Engine/Source/Runtime/Renderer/Public/SubstrateDefinitions.h` |
| FSceneTextures (5.7) | `Engine/Source/Runtime/Renderer/Public/SceneTextures.h` |
