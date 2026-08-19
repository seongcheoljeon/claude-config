# Compute Pass 패턴

## FComputeShaderUtils::AddPass (권장)

```cpp
FComputeShaderUtils::AddPass(
    GraphBuilder,
    RDG_EVENT_NAME("PassName"),
    ComputeShader,          // TShaderMapRef<FMyCS>
    Parameters,             // FMyCS::FParameters*
    GroupCount              // FIntVector (X, Y, Z)
);
```

### GroupCount 계산
```cpp
// 2D Dispatch
FIntVector GroupCount = FComputeShaderUtils::GetGroupCount(
    FIntPoint(Width, Height),   // 해상도
    FIntPoint(8, 8)             // 스레드 그룹 크기 (numthreads X,Y)
);

// 1D Dispatch
FIntVector GroupCount = FComputeShaderUtils::GetGroupCount(
    ElementCount,   // int32
    64              // 그룹당 스레드 수
);
```

---

## 저수준 AddPass (직접 제어)

```cpp
FMyCS::FParameters* Parameters = GraphBuilder.AllocParameters<FMyCS::FParameters>();
// Parameters 바인딩...

GraphBuilder.AddPass(
    RDG_EVENT_NAME("MyComputePass"),
    Parameters,
    ERDGPassFlags::Compute,
    [Parameters, GroupCount](FRHIComputeCommandList& RHICmdList)
    {
        TShaderMapRef<FMyCS> Shader(GetGlobalShaderMap(GMaxRHIFeatureLevel));
        FComputeShaderUtils::Dispatch(RHICmdList, Shader, *Parameters, GroupCount);
    }
);
```

---

## Async Compute

```cpp
// Pass 플래그에 AsyncCompute 추가
GraphBuilder.AddPass(
    RDG_EVENT_NAME("AsyncPass"),
    Parameters,
    ERDGPassFlags::Compute | ERDGPassFlags::AsyncCompute,
    [](FRHIComputeCommandList& RHICmdList) { ... }
);
```

> **주의**: Async Compute는 의존성이 없는 Pass에서만 의미있음.
> RDG가 의존성 분석 후 자동으로 Async 큐에 스케줄링.

---

## Indirect Dispatch (DrawIndirect / DispatchIndirect)

```cpp
// Indirect Args Buffer 생성
FRDGBufferRef ArgsBuffer = GraphBuilder.CreateBuffer(
    FRDGBufferDesc::CreateIndirectDesc<FRHIDispatchIndirectParameters>(1),
    TEXT("IndirectArgs")
);

// Args 채우기 Pass
// ...

// Indirect Dispatch
GraphBuilder.AddPass(
    RDG_EVENT_NAME("IndirectCompute"),
    Parameters,
    ERDGPassFlags::Compute,
    [Parameters, ArgsBuffer](FRHIComputeCommandList& RHICmdList)
    {
        FRHIBuffer* ArgsBufRHI = ArgsBuffer->GetRHI(); // ★ GetRHI() 사용
        TShaderMapRef<FMyCS> Shader(GetGlobalShaderMap(GMaxRHIFeatureLevel));
        SetComputePipelineState(RHICmdList, Shader.GetComputeShader());
        SetShaderParameters(RHICmdList, Shader, Shader.GetComputeShader(), *Parameters);
        RHICmdList.DispatchIndirectComputeShader(ArgsBufRHI, 0);
        UnsetShaderUAVs(RHICmdList, Shader, Shader.GetComputeShader());
    }
);
```

---

## USF (USSP Compute Shader) 골격

```hlsl
// MyShader.usf
#include "/Engine/Public/Platform.ush"

RWTexture2D<float4> OutputTexture;
Texture2D           InputTexture;
SamplerState        InputSampler;
float4              Params;

[numthreads(8, 8, 1)]
void MainCS(uint3 DispatchThreadId : SV_DispatchThreadID)
{
    uint2 Pixel = DispatchThreadId.xy;
    // ...
    OutputTexture[Pixel] = float4(1, 0, 0, 1);
}
```

---

## 체크리스트

- [ ] `TexCreate_UAV` 플래그가 Texture Desc에 있는가?
- [ ] `numthreads` 크기와 `GetGroupCount` 그룹 크기가 일치하는가?
- [ ] Lambda 안에서 `FRDGTextureRef` 대신 `GetRHI()` 사용했는가?
- [ ] `SetShaderParameters` 후 `UnsetShaderUAVs` 호출했는가? (저수준 패턴)
- [ ] `FComputeShaderUtils::AddPass` 사용 시 위 두 항목 불필요 (자동 처리)
