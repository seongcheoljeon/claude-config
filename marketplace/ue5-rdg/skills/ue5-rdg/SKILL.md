---
name: ue5-rdg
description: UE5 Render Dependency Graph (RDG) C++ API 작성 패턴 레퍼런스. FRDGBuilder/AddPass 사용법, Compute/Raster/Copy Pass 구현, Scene View Extension 연동, Resource 생명주기, Transient Resource, UAV/SRV/RTV 바인딩, Buffer Readback, Uniform Buffer, Substrate UE5.7 연동. 트리거: "RDG 패스 작성", FRDGBuilder, AddPass, FRDGTexture, FRDGBuffer, "Custom Render Pass", IMPLEMENT_GLOBAL_SHADER, "Compute Shader RDG", "Scene View Extension". 다루지 않음: RDG cvar/디버그 옵션 (→ unreal-dev-kb), 엔진 HLSL 코드 (→ ue5-shaders).
---

# UE5 RDG (Render Dependency Graph) Reference Skill

> **대상**: UE5.7.4+ / C++ / Graphics Programmer
> **원칙**: First Principle — RDG는 *deferred execution* 기반의 의존성 그래프다.
>   Pass를 즉시 실행하지 않고, 그래프를 구성한 뒤 `Execute()`에서 한 번에 최적화 실행한다.

---

## 빠른 참조 (Quick Reference)

| 목적 | 참조 파일 |
|------|-----------|
| GraphBuilder 생명주기·핵심 API | [references/01_graphbuilder.md](references/01_graphbuilder.md) |
| FRDGTexture / FRDGBuffer 리소스 | [references/02_resources.md](references/02_resources.md) |
| Shader Parameters 바인딩 | [references/03_shader_parameters.md](references/03_shader_parameters.md) |
| Compute Pass 패턴 | [references/04_compute_pass.md](references/04_compute_pass.md) |
| Raster Pass 패턴 | [references/05_raster_pass.md](references/05_raster_pass.md) |
| Scene View Extension 연동 | [references/06_scene_view_extension.md](references/06_scene_view_extension.md) |
| 디버깅 & Profiling | [references/07_debugging.md](references/07_debugging.md) |
| Substrate GBuffer (UE5.7 기본값) | [references/15_substrate_ue57.md](references/15_substrate_ue57.md) |
| UE5.6+ 변경사항 | [references/08_ue56_changes.md](references/08_ue56_changes.md) |
| Copy Pass 패턴 | [references/09_copy_pass.md](references/09_copy_pass.md) |
| Buffer Readback (GPU→CPU) | [references/10_buffer_readback.md](references/10_buffer_readback.md) |
| Temporal / Multi-GPU | [references/11_temporal_multigpu.md](references/11_temporal_multigpu.md) |
| Uniform Buffer 패턴 | [references/12_uniform_buffer.md](references/12_uniform_buffer.md) |
| 조건부 Pass & 리소스 패턴 | [references/13_conditional_resource.md](references/13_conditional_resource.md) |
| 스레드 안전성 (GT↔RT) | [references/14_thread_safety.md](references/14_thread_safety.md) |
| RDG 내부 동작 원리 (First Principle) | [references/18_rdg_internals_first_principle.md](references/18_rdg_internals_first_principle.md) |
| 공식 문서 — 누락 패턴 완전 보완 | [references/16_official_patterns.md](references/16_official_patterns.md) |
| 디버깅 완전 가이드 (공식 문서 기반) | [references/17_debugging_official.md](references/17_debugging_official.md) |

---

## RDG 핵심 원칙 (First Principle)

```
[Game Thread]        [Render Thread]
SetupPass()    →    GraphBuilder.AddPass()   →  (그래프 구성)
                    GraphBuilder.Execute()    →  (실제 GPU 커맨드 발행)
```

1. **Deferred Execution**: `AddPass()` 시점에 GPU 커맨드를 발행하지 않는다.
2. **Dependency Tracking**: Pass의 `Parameters`에 선언된 리소스로 자동 의존성 추론.
3. **Pass Culling**: 최종 출력에 기여하지 않는 Pass는 자동으로 제거됨.
4. **Transient Resources**: `CreateTexture()` / `CreateBuffer()`로 만든 리소스는 필요한 기간에만 메모리 할당.
5. **Barrier 자동 관리**: 리소스 상태 전환(UAV→SRV 등)을 RDG가 자동 삽입.

---

## 가장 흔한 패턴 (30초 치트시트)

### Compute Pass (최소 골격)
```cpp
// 1. Shader 선언
class FMyCS : public FGlobalShader {
    DECLARE_GLOBAL_SHADER(FMyCS);
    SHADER_USE_PARAMETER_STRUCT(FMyCS, FGlobalShader);
    BEGIN_SHADER_PARAMETER_STRUCT(FParameters, )
        SHADER_PARAMETER_RDG_TEXTURE_UAV(RWTexture2D<float4>, OutputTexture)
        SHADER_PARAMETER_RDG_TEXTURE_SRV(Texture2D,           InputTexture)
    END_SHADER_PARAMETER_STRUCT()
};
IMPLEMENT_GLOBAL_SHADER(FMyCS, "/MyPlugin/MyShader.usf", "MainCS", SF_Compute);

// 2. Pass 추가
void AddMyComputePass(FRDGBuilder& GraphBuilder, FRDGTextureRef Input, FRDGTextureRef Output)
{
    TShaderMapRef<FMyCS> ComputeShader(GetGlobalShaderMap(GMaxRHIFeatureLevel));

    FMyCS::FParameters* Parameters = GraphBuilder.AllocParameters<FMyCS::FParameters>();
    Parameters->InputTexture  = GraphBuilder.CreateSRV(Input);
    Parameters->OutputTexture = GraphBuilder.CreateUAV(Output);

    FIntVector GroupCount = FComputeShaderUtils::GetGroupCount(
        FIntPoint(Output->Desc.Extent), FIntPoint(8, 8));

    FComputeShaderUtils::AddPass(
        GraphBuilder,
        RDG_EVENT_NAME("MyComputePass"),
        ComputeShader,
        Parameters,
        GroupCount
    );
}
```

### Texture 생성
```cpp
FRDGTextureDesc Desc = FRDGTextureDesc::Create2D(
    FIntPoint(Width, Height),
    PF_FloatRGBA,
    FClearValueBinding::Black,
    TexCreate_ShaderResource | TexCreate_UAV
);
FRDGTextureRef MyTexture = GraphBuilder.CreateTexture(Desc, TEXT("MyTexture"));
```

### 외부 리소스 등록 (Pooled → RDG)
```cpp
// PooledRenderTarget → RDG
FRDGTextureRef RDGTex = GraphBuilder.RegisterExternalTexture(MyPooledRT);

// RHI Texture → RDG
FRDGTextureRef RDGTex = GraphBuilder.RegisterExternalTexture(
    CreateRenderTarget(MyRHITexture, TEXT("MyExt")));
```

### 리소스 Extract (RDG → 외부 유지)
```cpp
TRefCountPtr<IPooledRenderTarget> OutPooled;
GraphBuilder.QueueTextureExtraction(MyRDGTexture, &OutPooled);
// Execute() 후 OutPooled 사용 가능
```

---

## 자주 하는 실수

| 실수 | 올바른 방법 |
|------|------------|
| **[UE5.7]** GBuffer 직접 접근 (GBufferATexture 등) | Substrate UB 바인딩 패턴 사용 (`15_substrate_ue57.md`) |
| Parameters에 미선언 리소스에서 `GetRHI()` 호출 | Parameters에 선언된 리소스만 lambda 내에서 GetRHI() 가능 |
| 스택 변수를 lambda에 레퍼런스(`&`) 캡처 | `GraphBuilder.AllocPOD<T>()` 또는 `AllocObject<T>()` 사용 |
| `Execute()` 전에 Extracted 리소스 접근 | `QueueTextureExtraction` + Execute 후 사용. 즉시 필요하면 `ConvertToExternalTexture` |
| Permutation으로 미사용 리소스가 파라미터에 포함 | `AddPass` 전에 `ClearUnusedGraphResources` 호출 |
| `FRHICommandListImmediate`를 lambda 인자로 사용 | `FRHIComputeCommandList`(Compute) / `FRHICommandList`(Raster) 사용 |
| UAV/SRV 생성 시 Mip 미지정 | `FRDGTextureUAVDesc(Tex, MipIndex)` 명시 |
| Pass Culling으로 패스가 사라짐 | `ERDGPassFlags::NeverCull` 추가 또는 리소스 Extract 확인 |
| Texture Flag에 `TexCreate_UAV` 누락 | Desc 생성 시 반드시 명시 |
| GraphBuilder 인스턴스 중복 | 단일 스레드, 한 번에 하나의 인스턴스만 허용 |

---

## 세부 내용이 필요하면?

위 Quick Reference 표의 파일을 읽어서 답변하세요.
예) Compute Pass 심화 → `references/04_compute_pass.md` 읽기

---

## 함께 활성화되면 좋은 plugin

본 plugin은 **RDG C++ API 작성 패턴**에 특화. 다음 plugin과 동시 활성화 시 시너지:

| 시나리오 | 협력 plugin | 본 plugin 역할 | 협력 plugin 역할 |
|---|---|---|---|
| RDG 패스 작성 + 디버깅 | `unreal-dev-kb` | C++ API 패턴 | RDG 디버그 cvar (`r.RDG.*`) |
| 패스가 호출하는 HLSL 셰이더 | `ue5-shaders` | C++ 패스 코드 | 호출 대상 .usf/.ush 코드 |
| RDG 패스의 C++ 코드 스타일 | `ue5-coding-convention` | RDG 코드 패턴 | UE5 C++ 명명/포맷 규칙 |

**검색 흐름 권장**: 본 plugin으로 패스 작성 → `ue5-shaders`로 셰이더 코드 확인 → `unreal-dev-kb`의 cvar로 런타임 디버깅.
