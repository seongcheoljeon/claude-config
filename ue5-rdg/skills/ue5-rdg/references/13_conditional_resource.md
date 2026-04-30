# 조건부 Pass & 리소스 패턴

## 조건부 Pass 실행

### 방법 1: 그래프 구성 단계에서 분기 (권장)

```cpp
// Render Thread에서 조건 평가 후 Pass 자체를 추가하지 않음
if (bFeatureEnabled)
{
    AddMyComputePass(GraphBuilder, InputTex, OutputTex);
}
// → 가장 명확하고 비용 없음 (Pass 추가 자체를 안 함)
```

### 방법 2: NeverCull + 내부 얼리 아웃

```cpp
GraphBuilder.AddPass(
    RDG_EVENT_NAME("ConditionalPass"),
    Parameters,
    ERDGPassFlags::Compute | ERDGPassFlags::NeverCull,
    [bEnabled](FRHIComputeCommandList& RHICmdList)
    {
        if (!bEnabled) return; // GPU 커맨드 미발행
        // ...
    }
);
// 단점: Pass 노드 자체는 항상 그래프에 존재
```

### 방법 3: Permutation으로 분기

```cpp
class FMyCS : public FGlobalShader
{
    class FEnableFeatureDim : SHADER_PERMUTATION_BOOL("ENABLE_FEATURE");
    using FPermutationDomain = TShaderPermutationDomain<FEnableFeatureDim>;
};

FMyCS::FPermutationDomain Permutation;
Permutation.Set<FMyCS::FEnableFeatureDim>(bFeatureEnabled);
TShaderMapRef<FMyCS> Shader(GetGlobalShaderMap(GMaxRHIFeatureLevel), Permutation);
```

---

## Texture Pool 재사용 패턴

```cpp
// GRenderTargetPool 직접 사용 (RDG 외부)
TRefCountPtr<IPooledRenderTarget> PooledRT;

FPooledRenderTargetDesc Desc(FPooledRenderTargetDesc::Create2DDesc(
    Extent, PF_FloatRGBA,
    FClearValueBinding::Black,
    TexCreate_ShaderResource | TexCreate_UAV,
    false  // bInForceSeparateTargetAndShaderResource
));
GRenderTargetPool.FindFreeElement(RHICmdList, Desc, PooledRT, TEXT("MyPooledRT"));

// RDG에 등록
FRDGTextureRef RDGTex = GraphBuilder.RegisterExternalTexture(PooledRT);
```

---

## 리소스 별칭 (Aliasing) — 고급

RDG는 Transient 리소스 간 메모리를 자동으로 재사용(alias).
명시적으로 제어하려면:

```cpp
// 두 텍스처가 겹치지 않음을 보장 → 메모리 공유 허용
FRDGTextureDesc Desc = ...;
FRDGTextureRef TexA = GraphBuilder.CreateTexture(Desc, TEXT("A"));
FRDGTextureRef TexB = GraphBuilder.CreateTexture(Desc, TEXT("B"));
// TexA 사용이 끝난 후 TexB 사용 → RDG가 자동으로 같은 메모리 재사용
```

> **강제 비활성화**: `r.RDG.TransientResourceCache 0`으로 별칭 없이 독립 할당 (디버깅용)

---

## AddClearUAVPass

```cpp
// Float 클리어
AddClearUAVPass(GraphBuilder, GraphBuilder.CreateUAV(Texture), FLinearColor::Black);
AddClearUAVPass(GraphBuilder, GraphBuilder.CreateUAV(Texture), FVector4f(0, 0, 0, 0));

// Uint 클리어
AddClearUAVPass(GraphBuilder, GraphBuilder.CreateUAV(Buffer), uint32(0));
```

---

## Pass 의존성 명시 (드문 케이스)

```cpp
// 대부분은 Parameters 선언으로 자동 의존성 추론됨.
// 자동 추론이 안 되는 경우(예: 포인터 우회)에만 수동 설정.

// UAV Barrier 강제 삽입
GraphBuilder.AddPass(
    RDG_EVENT_NAME("ForceBarrier"),
    EmptyParameters,
    ERDGPassFlags::Compute | ERDGPassFlags::NeverCull,
    [](FRHIComputeCommandList& RHICmdList)
    {
        // 빈 패스로 Barrier 삽입
    }
);
```

---

## FRDGPassParameterStruct (빈 Parameters)

```cpp
// Parameters가 없는 Pass
struct FEmptyPassParameters
{
    // 비어 있음
};
// 또는 엔진 제공 빈 구조체 사용:
auto* EmptyParams = GraphBuilder.AllocParameters<FRDGPassParameterStruct>(0);
```
