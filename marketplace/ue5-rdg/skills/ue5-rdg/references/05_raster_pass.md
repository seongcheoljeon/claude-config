# Raster Pass 패턴

## 기본 구조

```cpp
// Parameters에 반드시 RENDER_TARGET_BINDING_SLOTS() 포함
BEGIN_SHADER_PARAMETER_STRUCT(FParameters, )
    SHADER_PARAMETER_STRUCT_REF(FViewUniformShaderParameters, View)
    RENDER_TARGET_BINDING_SLOTS()   // ★ Raster Pass 필수
END_SHADER_PARAMETER_STRUCT()
```

## RT 바인딩

```cpp
FMyPS::FParameters* Parameters = GraphBuilder.AllocParameters<FMyPS::FParameters>();

// Color RT
Parameters->RenderTargets[0] = FRenderTargetBinding(
    OutputTexture,
    ERenderTargetLoadAction::EClear   // EClear / ELoad / ENoAction
);

// 여러 MRT
Parameters->RenderTargets[1] = FRenderTargetBinding(
    NormalTexture, ERenderTargetLoadAction::EClear);

// Depth
Parameters->RenderTargets.DepthStencil = FDepthStencilBinding(
    DepthTexture,
    ERenderTargetLoadAction::EClear,       // Depth Load
    ERenderTargetLoadAction::ENoAction,    // Stencil Load
    FExclusiveDepthStencil::DepthWrite_StencilNop
);
```

## AddPass (Raster)

```cpp
GraphBuilder.AddPass(
    RDG_EVENT_NAME("MyRasterPass"),
    Parameters,
    ERDGPassFlags::Raster,
    [Parameters, &View](FRHICommandList& RHICmdList)
    {
        RHICmdList.SetViewport(0, 0, 0.0f, Width, Height, 1.0f);
        
        FGraphicsPipelineStateInitializer PSOInit;
        RHICmdList.ApplyCachedRenderTargets(PSOInit);
        
        // Blend, Depth, Rasterizer 상태 설정
        PSOInit.BlendState        = TStaticBlendState<>::GetRHI();
        PSOInit.DepthStencilState = TStaticDepthStencilState<false, CF_Always>::GetRHI();
        PSOInit.RasterizerState   = TStaticRasterizerState<>::GetRHI();
        
        TShaderMapRef<FMyVS> VertexShader(GetGlobalShaderMap(GMaxRHIFeatureLevel));
        TShaderMapRef<FMyPS> PixelShader(GetGlobalShaderMap(GMaxRHIFeatureLevel));
        
        PSOInit.BoundShaderState.VertexDeclarationRHI = GFilterVertexDeclaration.VertexDeclarationRHI;
        PSOInit.BoundShaderState.VertexShaderRHI      = VertexShader.GetVertexShader();
        PSOInit.BoundShaderState.PixelShaderRHI       = PixelShader.GetPixelShader();
        PSOInit.PrimitiveType = PT_TriangleList;
        
        SetGraphicsPipelineState(RHICmdList, PSOInit, 0);
        SetShaderParameters(RHICmdList, PixelShader, PixelShader.GetPixelShader(), *Parameters);
        
        DrawRectangle(RHICmdList, ...);
    }
);
```

## Full-Screen Pass (DrawScreenPass) — 권장

```cpp
#include "ScreenPass.h"

// VS/PS 쌍으로 화면 전체를 덮는 Triangle 렌더링
AddDrawScreenPass(
    GraphBuilder,
    RDG_EVENT_NAME("FullscreenPass"),
    View,
    FScreenPassRenderTarget(OutputTexture, ERenderTargetLoadAction::ENoAction),
    FScreenPassTexture(InputTexture),
    PixelShader,        // TShaderMapRef<FMyPS>
    Parameters
);
```

## PixelShader + FScreenPassVS 조합

```cpp
// VS 없이 PS만 선언 시 FScreenPassVS 사용
class FMyPS : public FGlobalShader
{
    DECLARE_GLOBAL_SHADER(FMyPS);
    SHADER_USE_PARAMETER_STRUCT(FMyPS, FGlobalShader);

    BEGIN_SHADER_PARAMETER_STRUCT(FParameters, )
        SHADER_PARAMETER_STRUCT_INCLUDE(FScreenPassTextureViewportParameters, Input)
        SHADER_PARAMETER_RDG_TEXTURE(Texture2D, InputTexture)
        SHADER_PARAMETER_SAMPLER(SamplerState, InputSampler)
        RENDER_TARGET_BINDING_SLOTS()
    END_SHADER_PARAMETER_STRUCT()
};
```

## LoadAction 선택 기준

| 상황 | LoadAction |
|------|-----------|
| 이전 내용 필요 없음 (완전히 덮어씀) | `ENoAction` (가장 빠름) |
| 클리어해서 시작 | `EClear` |
| 이전 내용 위에 합성 | `ELoad` |

## FExclusiveDepthStencil 주요 값

```cpp
FExclusiveDepthStencil::DepthWrite_StencilNop
FExclusiveDepthStencil::DepthRead_StencilNop
FExclusiveDepthStencil::DepthNop_StencilWrite
FExclusiveDepthStencil::DepthWrite_StencilWrite
FExclusiveDepthStencil::DepthRead_StencilRead
```
