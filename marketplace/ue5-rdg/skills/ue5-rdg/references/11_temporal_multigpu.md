# Temporal / Multi-GPU 패턴

## Temporal (이전 프레임 리소스 활용)

### 기본 원칙

RDG Transient 리소스는 Execute() 후 해제됨.
이전 프레임 결과를 다음 프레임에서 사용하려면 **Extract → 다음 프레임 Register** 패턴 필수.

```
Frame N:   CreateTexture → ... → QueueTextureExtraction → Execute → [PooledRT 보존]
Frame N+1: RegisterExternalTexture(PooledRT) → 이전 결과 SRV로 사용
```

### 구현

```cpp
// 멤버 변수 (Subsystem 또는 Proxy)
TRefCountPtr<IPooledRenderTarget> PreviousFrameRT;

// 매 프레임 렌더 패스
void RenderTemporalPass(FRDGBuilder& GraphBuilder, const FViewInfo& View)
{
    // 현재 프레임 출력 생성
    FRDGTextureRef CurrentOutput = GraphBuilder.CreateTexture(
        FRDGTextureDesc::Create2D(View.ViewRect.Size(), PF_FloatRGBA,
            FClearValueBinding::Black, TexCreate_ShaderResource | TexCreate_UAV),
        TEXT("TemporalOutput"));

    // 이전 프레임 등록 (없으면 더미 텍스처 사용)
    FRDGTextureRef PreviousInput = nullptr;
    if (PreviousFrameRT.IsValid())
    {
        PreviousInput = GraphBuilder.RegisterExternalTexture(PreviousFrameRT);
    }
    else
    {
        // 첫 프레임: 검은 텍스처로 초기화
        PreviousInput = GraphBuilder.CreateTexture(CurrentOutput->Desc, TEXT("BlackDummy"));
        AddClearUAVPass(GraphBuilder, GraphBuilder.CreateUAV(PreviousInput), FLinearColor::Black);
    }

    // Temporal Blend Pass
    FMyTemporalCS::FParameters* Params = GraphBuilder.AllocParameters<FMyTemporalCS::FParameters>();
    Params->CurrentFrame  = GraphBuilder.CreateSRV(/* 이번 프레임 결과 */);
    Params->PreviousFrame = GraphBuilder.CreateSRV(PreviousInput);
    Params->OutputTexture = GraphBuilder.CreateUAV(CurrentOutput);
    Params->BlendFactor   = 0.1f; // 10% 현재 + 90% 이전
    // ...AddPass...

    // 다음 프레임을 위해 보존
    GraphBuilder.QueueTextureExtraction(CurrentOutput, &PreviousFrameRT);
}
```

### Motion Vector / Reprojection

```cpp
// View에서 이전 프레임 행렬 접근
const FMatrix44f PreviousViewProjection = FMatrix44f(View.PrevViewInfo.ViewMatrices.GetViewProjectionMatrix());

// Shader에서 Reprojection
// float4 PrevClip = PreviousViewProjectionMatrix * float4(WorldPos, 1.0);
// float2 PrevUV = PrevClip.xy / PrevClip.w * 0.5 + 0.5;
```

### 히스토리 리셋 조건

```cpp
bool bNeedReset = !PreviousFrameRT.IsValid()
    || View.bCameraCut                          // 카메라 컷
    || View.ViewRect != PreviousViewRect        // 해상도 변경
    || bSceneChanged;                           // 씬 변경

if (bNeedReset)
    PreviousFrameRT.SafeRelease();
```

---

## Multi-GPU (mGPU / SLI)

> **실용 범위**: UE5에서 mGPU는 제한적으로 지원됨.
> 대부분의 프로젝트에서 직접 사용 빈도 낮음. 엔진 내부 구현 참고 목적.

### GPU 마스크

```cpp
// 특정 GPU에 패스 할당
FRHIGPUMask GPUMask = FRHIGPUMask::GPU0();
FRHIGPUMask AllGPUs = FRHIGPUMask::All();

// RHICmdList에 GPU 마스크 설정
SCOPED_GPU_MASK(RHICmdList, GPUMask);
```

### Cross-GPU Transfer

```cpp
// GPU0 결과 → GPU1로 전송
RHICmdList.TransferResources(
    { FTransferResourceParams(Texture->GetRHI(), FRHIGPUMask::GPU0(), FRHIGPUMask::GPU1(), true, true) }
);
```

### RDG에서 mGPU

```cpp
// GraphBuilder 생성 시 GPU 마스크 전달
FRDGBuilder GraphBuilder(RHICmdList, RDG_EVENT_NAME(""), ERDGBuilderFlags::None, FRHIGPUMask::GPU0());
```

> **참고**: mGPU 관련 코드는 `Engine/Source/Runtime/RHI/Public/RHI.h`의
> `WITH_MGPU` 매크로로 조건 컴파일됨. 대부분 단일 GPU 빌드에서는 무효화됨.

---

## Temporal + History 관련 유용 유틸

```cpp
// FTemporalAAHistory — UE 내장 TAA 히스토리 구조체
FTemporalAAHistory& History = View.PrevViewInfo.TemporalAAHistory;
if (History.IsValid())
{
    FRDGTextureRef HistoryTex = GraphBuilder.RegisterExternalTexture(History.RT[0]);
}

// FPreviousViewInfo — 이전 프레임 뷰 정보 전체
const FPreviousViewInfo& PrevView = View.PrevViewInfo;
```
