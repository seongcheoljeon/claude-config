# 스레드 안전성 & Game Thread ↔ Render Thread 패턴

## 핵심 규칙

| 스레드 | 허용 | 금지 |
|--------|------|------|
| Game Thread | UObject 접근, World 쿼리, 렌더 커맨드 발행 | RHI 직접 호출, RDGBuilder 접근 |
| Render Thread | RDGBuilder, RHI 호출 | UObject 접근, GC 대상 포인터 역참조 |

---

## 데이터 전달 패턴

### ENQUEUE_RENDER_COMMAND (Game → Render)

```cpp
// Game Thread에서 파라미터 캡처 후 렌더 스레드로 전달
FMyParams Params = CollectParamsOnGameThread();

ENQUEUE_RENDER_COMMAND(MyRenderCommand)(
    [Params](FRHICommandListImmediate& RHICmdList)
    {
        // 여기는 Render Thread
        // Params는 값 복사 → 안전
    }
);
```

### FlushRenderingCommands (동기 대기, 사용 주의)

```cpp
// Game Thread에서 렌더 스레드 완료 대기 — 프레임 히치 유발, 꼭 필요할 때만
FlushRenderingCommands();
```

---

## Render Proxy 패턴 (UObject → Render Thread 안전 데이터)

```cpp
// Game Thread: Proxy 생성 및 갱신
class FMySceneProxy
{
public:
    // Game Thread에서 설정
    FLinearColor Color;
    float        Intensity;
    // UObject 포인터 금지 — RHI 리소스 또는 POD만 보관
    FTextureRHIRef TextureRHI;
};

// UMyComponent::CreateSceneProxy() — Game Thread
FMySceneProxy* Proxy = new FMySceneProxy();
Proxy->Color = MyColor; // 값 복사
Proxy->TextureRHI = MyTexture->GetResource()->GetTextureRHI(); // RHI 핸들 복사

// SendRenderTransform_Concurrent — Render Thread에서 Proxy 접근 안전
```

---

## SVE에서 Game Thread 데이터 가져오기

```cpp
class FMySceneViewExtension : public FSceneViewExtensionBase
{
    // Game Thread에서 설정
    std::atomic<float> Intensity { 1.0f };     // atomic: Game/Render 동시 접근

    // 또는: BeginRenderViewFamily 에서 복사 (Render Thread 진입 전)
    float CachedIntensity = 1.0f;

public:
    // Game Thread에서 호출
    void SetIntensity(float InValue) { Intensity.store(InValue); }

    // Render Thread 진입 전 마지막 Game Thread 콜백
    virtual void BeginRenderViewFamily(FSceneViewFamily& InViewFamily) override
    {
        CachedIntensity = Intensity.load(); // 안전한 복사 시점
    }

    virtual void PreRenderViewFamily_RenderThread(
        FRDGBuilder& GraphBuilder, FSceneViewFamily& InViewFamily) override
    {
        // CachedIntensity 사용 → 안전
    }
};
```

---

## TRenderResource (GPU 리소스 수명 관리)

```cpp
class FMyVertexBuffer : public FRenderResource
{
public:
    FBufferRHIRef VertexBufferRHI;

    virtual void InitRHI(FRHICommandListBase& RHICmdList) override
    {
        // Render Thread에서 RHI 리소스 생성
        FRHIResourceCreateInfo CreateInfo(TEXT("MyVB"));
        VertexBufferRHI = RHICmdList.CreateVertexBuffer(Size, BUF_Static, CreateInfo);
    }

    virtual void ReleaseRHI() override
    {
        VertexBufferRHI.SafeRelease();
    }
};

// 전역 인스턴스
TGlobalResource<FMyVertexBuffer> GMyVertexBuffer;

// Render Thread에서 접근
FRHIBuffer* VB = GMyVertexBuffer.VertexBufferRHI;
```

---

## 흔한 실수

```cpp
// ❌ 잘못된 예: Render Thread lambda에서 UObject 접근
GraphBuilder.AddPass(..., ERDGPassFlags::Compute,
    [this](FRHIComputeCommandList& RHICmdList)
    {
        float Val = MyUObject->Value; // 크래시 위험: GC가 이미 해제했을 수 있음
    }
);

// ✅ 올바른 예: 값 미리 복사
float CachedVal = MyUObject->Value; // Render Thread 진입 전에 복사
GraphBuilder.AddPass(..., ERDGPassFlags::Compute,
    [CachedVal](FRHIComputeCommandList& RHICmdList)
    {
        // CachedVal 사용 → 안전
    }
);
```
