# Copy Pass 패턴

## AddCopyTexturePass

```cpp
#include "RenderGraphUtils.h"

// Texture 전체 복사
AddCopyTexturePass(GraphBuilder, SrcTexture, DstTexture);

// 특정 영역 복사
FRHICopyTextureInfo CopyInfo;
CopyInfo.SourcePosition  = FIntVector(SrcX, SrcY, 0);
CopyInfo.DestPosition    = FIntVector(DstX, DstY, 0);
CopyInfo.Size            = FIntVector(Width, Height, 1);
CopyInfo.SourceMipIndex  = 0;
CopyInfo.DestMipIndex    = 0;
AddCopyTexturePass(GraphBuilder, SrcTexture, DstTexture, CopyInfo);
```

## AddCopyBufferPass

```cpp
// Buffer 전체 복사
AddCopyBufferPass(GraphBuilder, DstBuffer, SrcBuffer);
```

## Resolve Pass (MSAA → Non-MSAA)

```cpp
// MSAA 텍스처 Resolve
AddResolvePass(
    GraphBuilder,
    FRenderTargetBinding(MSAATexture, ERenderTargetLoadAction::ELoad),
    FResolveRect(0, 0, Width, Height)
);
```

## 저수준 Copy (AddPass + ERDGPassFlags::Copy)

```cpp
GraphBuilder.AddPass(
    RDG_EVENT_NAME("ManualCopy"),
    Parameters,  // 빈 Parameters도 가능: GraphBuilder.AllocParameters<FRDGPassParameterStruct>()
    ERDGPassFlags::Copy,
    [SrcRHI = SrcTexture->GetRHI(), DstRHI = DstTexture->GetRHI()](FRHICommandList& RHICmdList)
    {
        FRHICopyTextureInfo Info;
        RHICmdList.CopyTexture(SrcRHI, DstRHI, Info);
    }
);
```

## 주의사항

| 상황 | 주의 |
|------|------|
| Src/Dst 포맷 다름 | `CopyTexture` 불가 → Blit 또는 Shader Pass 사용 |
| MSAA → Non-MSAA | `AddResolvePass` 사용 (CopyTexture 불가) |
| Mip 지정 복사 | `FRHICopyTextureInfo.SourceMipIndex` / `DestMipIndex` 명시 |
| 크기 불일치 | `Size` 필드로 복사 영역 제한 |
