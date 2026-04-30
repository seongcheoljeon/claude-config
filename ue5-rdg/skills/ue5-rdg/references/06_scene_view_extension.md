# Scene View Extension (SVE) + RDG 연동

## 클래스 계층

```
ISceneViewExtension
└── FSceneViewExtensionBase   ← 권장 베이스 클래스
    └── FMySceneViewExtension
```

## 최소 구현

```cpp
// MySceneViewExtension.h
class FMySceneViewExtension : public FSceneViewExtensionBase
{
public:
    FMySceneViewExtension(const FAutoRegister& AutoRegister);

    // ISceneViewExtension interface
    virtual void SetupViewFamily(FSceneViewFamily& InViewFamily) override {}
    virtual void SetupView(FSceneViewFamily& ViewFamily, FSceneView& InView) override {}
    virtual void BeginRenderViewFamily(FSceneViewFamily& InViewFamily) override {}

    // ★ RDG Pass를 추가하는 주요 진입점들:
    virtual void PreRenderViewFamily_RenderThread(
        FRDGBuilder& GraphBuilder, FSceneViewFamily& InViewFamily) override;

    virtual void PostRenderViewFamily_RenderThread(
        FRDGBuilder& GraphBuilder, FSceneViewFamily& InViewFamily) override;

    virtual void PrePostProcessPass_RenderThread(
        FRDGBuilder& GraphBuilder, const FSceneView& View,
        const FPostProcessingInputs& Inputs) override;

    virtual void SubscribeToPostProcessingPass(
        EPostProcessingPass Pass,
        FAfterPassCallbackDelegateArray& InOutPassCallbacks,
        bool bIsPassEnabled) override;
};
```

## 생성 및 등록

```cpp
// World Subsystem 등에서 생성
MyExtension = FSceneViewExtensions::NewExtension<FMySceneViewExtension>();

// 자동 등록/해제: FAutoRegister가 처리
// 명시적 비활성화:
MyExtension->IsActiveThisFrameFunctions.Add(
    FSceneViewExtensionIsActiveFunctor([](const ISceneViewExtension*, const FSceneViewExtensionContext&) {
        return bEnabled;
    })
);
```

## 주요 콜백 호출 순서

```
PreRenderViewFamily_RenderThread     ← 뷰 렌더링 전 (GBuffer 전)
PreRenderView_RenderThread           ← 각 View 렌더링 전
PostRenderBasePassDeferred_RenderThread  ← BasePass 완료 후
PrePostProcessPass_RenderThread      ← PostProcess 직전
SubscribeToPostProcessingPass        ← PostProcess 파이프라인 내 삽입
PostRenderViewFamily_RenderThread    ← 모든 렌더링 완료 후
```

## SubscribeToPostProcessingPass 패턴

```cpp
void FMySceneViewExtension::SubscribeToPostProcessingPass(
    EPostProcessingPass Pass,
    FAfterPassCallbackDelegateArray& InOutPassCallbacks,
    bool bIsPassEnabled)
{
    if (Pass == EPostProcessingPass::Tonemap)
    {
        InOutPassCallbacks.Add(
            FAfterPassCallbackDelegate::CreateRaw(
                this, &FMySceneViewExtension::PostProcessCallback_RenderThread));
    }
}

FScreenPassTexture FMySceneViewExtension::PostProcessCallback_RenderThread(
    FRDGBuilder& GraphBuilder,
    const FSceneView& View,
    const FPostProcessingInputs& Inputs)
{
    // Inputs.SceneColor → 이전 Pass 출력
    FScreenPassTexture SceneColor = (*Inputs.SceneColorTexture);
    
    // 출력 Texture 생성
    FRDGTextureRef OutputTexture = GraphBuilder.CreateTexture(
        SceneColor.Texture->Desc, TEXT("MyOutput"));

    // Pass 추가 ...

    return FScreenPassTexture(OutputTexture, SceneColor.ViewRect);
}
```

## FPostProcessingInputs 주요 멤버

```cpp
Inputs.SceneColorTexture       // FRDGTexture** (scene color)
Inputs.SceneDepthTexture       // FRDGTexture*
Inputs.SceneVelocityTexture    // FRDGTexture*  (UE5.1+)
Inputs.SceneTextures           // FSceneTextureShaderParameters
```

## SceneTextures 바인딩

```cpp
// PrePostProcessPass에서 SceneTextures 가져오기
FSceneTextureShaderParameters SceneTextureParameters =
    Inputs.SceneTextures->GetShaderParameters();

// Uniform Buffer로 바인딩
Params->SceneTextures = Inputs.SceneTextures;
```

## 주의사항

1. SVE 콜백은 **Render Thread** 에서 호출됨 → Game Thread 데이터 직접 접근 금지.
2. `PreRenderViewFamily` 에서 게임 데이터를 복사해 멤버 변수에 저장 후 사용.
3. `FAutoRegister` 기반 등록 → 수명이 ViewExtension 객체와 동일.
4. `IsActiveThisFrame` 으로 조건부 활성화 가능.
