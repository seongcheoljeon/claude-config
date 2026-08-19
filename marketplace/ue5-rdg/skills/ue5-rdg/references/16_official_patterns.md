# 공식 문서 기반 — 누락 패턴 완전 보완
> 출처: 언리얼 엔진 5.7 공식 문서 "렌더 종속성 그래프(RDG)"

---

## RDG 핵심 기능 (공식 목록)

- 비동기 컴퓨트 펜스 예약
- 최적의 수명과 메모리 에일리어싱을 통한 일시적 리소스 할당
- **분할 배리어**를 사용한 서브리소스 전환으로 레이턴시를 숨기고 GPU 오버랩 향상
- 병렬 명령 목록 기록
- 그래프의 미사용 리소스 및 패스 컬링
- API 사용 및 리소스 의존성 유효성 검사
- RDG 인사이트에서 그래프 구조체 및 메모리 수명 시각화

---

## FRDGBuilder 중요 제약 (공식 문서)

```cpp
// ★ 단일 스레드 방식 — 한 번에 하나의 인스턴스만 존재 가능
// 계층 그래프나 사이드 바이 사이드 그래프 불가
FRDGBuilder GraphBuilder(RHICmdList);

// ★ FRHICommandListImmediate는 병렬 실행을 막음 — 꼭 필요한 경우에만 사용
// [PassParameters](FRHICommandListImmediate& RHICmdList)  ← 피할 것
// [PassParameters](FRHIComputeCommandList& RHICmdList)    ← Compute 권장
// [PassParameters](FRHICommandList& RHICmdList)           ← Raster 권장
```

---

## RDG_TEXTURE_ACCESS — 셰이더 없는 패스의 리소스 접근 선언

셰이더와 1:1 대응하지 않는 패스(CopyTexture, Clear 등)에서 사용.

```cpp
BEGIN_SHADER_PARAMETER_STRUCT(FCopyTextureParameters, )
    // CopySrc 접근으로 Input 텍스처 선언
    RDG_TEXTURE_ACCESS(Input,  ERHIAccess::CopySrc)
    // CopyDest 접근으로 Output 텍스처 선언
    RDG_TEXTURE_ACCESS(Output, ERHIAccess::CopyDest)
END_SHADER_PARAMETER_STRUCT()

void AddCopyTexturePass(FRDGBuilder& GraphBuilder,
    FRDGTextureRef InputTexture, FRDGTextureRef OutputTexture,
    const FRHICopyTextureInfo& CopyInfo)
{
    FCopyTextureParameters* Parameters = GraphBuilder.AllocParameters<FCopyTextureParameters>();
    Parameters->Input  = InputTexture;
    Parameters->Output = OutputTexture;

    GraphBuilder.AddPass(
        RDG_EVENT_NAME("CopyTexture(%s -> %s)", InputTexture->Name, OutputTexture->Name),
        Parameters,
        ERDGPassFlags::Copy,
        [InputTexture, OutputTexture, CopyInfo](FRHICommandList& RHICmdList)
        {
            // ★ Parameters에 선언했으므로 람다 내에서 GetRHI() 호출 합법
            RHICmdList.CopyTexture(InputTexture->GetRHI(), OutputTexture->GetRHI(), CopyInfo);
        });
}
```

---

## UAV Raster Pass — FPixelShaderUtils::AddUAVPass

RT 없이 UAV 출력만 하는 래스터 패스.

```cpp
BEGIN_SHADER_PARAMETER_STRUCT(FUAVRasterPassParameters, RENDERCORE_API)
    SHADER_PARAMETER_RDG_TEXTURE_UAV(RWTexture2D, Output)
END_SHADER_PARAMETER_STRUCT()

auto* PassParameters = GraphBuilder.AllocParameters<FUAVRasterPassParameters>();
PassParameters->Output = GraphBuilder.CreateUAV(OutputTexture);

FIntRect ViewportRect = ...;
FPixelShaderUtils::AddUAVPass(
    GraphBuilder,
    RDG_EVENT_NAME("Raster UAV Pass"),
    PassParameters,
    ViewportRect,
    [](FRHICommandList& RHICmdList)
    {
        // 파라미터를 바인딩하고 드로
    });
```

---

## FPixelShaderUtils::AddFullscreenPass — 전체화면 PS Pass

```cpp
// FAddDrawScreenPass 대신 공식 권장 유틸리티
FPixelShaderUtils::AddFullscreenPass(
    GraphBuilder,
    ShaderMap,                      // GetGlobalShaderMap(GMaxRHIFeatureLevel)
    RDG_EVENT_NAME("MyFullscreen"),
    PixelShader,                    // TShaderMapRef<FMyPS>
    PassParameters,
    FIntRect(FIntPoint::ZeroValue, ViewSize)
);
```

---

## ClearUnusedGraphResources — Permutation 기반 리소스 정리

셰이더 Permutation에 따라 사용하지 않는 리소스를 null로 정리.

```cpp
FMyShaderCS::FParameters* PassParameters = GraphBuilder.AllocParameters<FMyShaderCS::FParameters>();
// ... 파라미터 채우기 ...

// ★ AddPass 전에 반드시 호출 — 미사용 RDG 리소스를 null 처리해 불필요한 의존성 제거
ClearUnusedGraphResources(*ComputeShader, PassParameters);

GraphBuilder.AddPass(
    RDG_EVENT_NAME("..."),
    PassParameters,
    ERDGPassFlags::Compute,
    [PassParameters, ComputeShader, GroupCount](FRHIComputeCommandList& RHICmdList)
    {
        FComputeShaderUtils::Dispatch(RHICmdList, ComputeShader, *PassParameters, GroupCount);
    });

// 여러 셰이더 버전
ClearUnusedGraphResources(VertexShader, PixelShader, &PassParameters);
```

---

## kGolden2DGroupSize — 최적 2D 그룹 크기

```cpp
// FComputeShaderUtils::kGolden2DGroupSize = 8 (공식 권장값)
FComputeShaderUtils::AddPass(
    GraphBuilder,
    RDG_EVENT_NAME("GenerateMips DestMipLevel=%d", MipLevel),
    ComputeShader,
    PassParameters,
    FComputeShaderUtils::GetGroupCount(DestTextureSize, FComputeShaderUtils::kGolden2DGroupSize)
    // ↑ GetGroupCount(FIntPoint, int32) 오버로드: 내부적으로 FIntPoint(Size, Size)로 처리
);
```

---

## Buffer Upload — FRDGUploadData + ERDGInitialDataFlags

```cpp
FRDGBufferRef IndexBuffer = GraphBuilder.CreateBuffer(
    FRDGBufferDesc::CreateUploadDesc(sizeof(uint32), NumIndices),
    TEXT("MyIndexBuffer"));

// ★ RDG 내부 할당자 사용 — Execute()까지 수명 보장
FRDGUploadData<int32> Indices(GraphBuilder, NumIndices);

Indices[0] = ...;
Indices[1] = ...;
Indices[NumIndices - 1] = ...;

// ★ NoCopy: 데이터 수명이 그래프 연기 이후까지 보장될 때 사용
//    NoCopy가 아니면 RDG가 내부적으로 복사본 생성
GraphBuilder.QueueBufferUpload(IndexBuffer, Indices, ERDGInitialDataFlags::NoCopy);
```

> 업로드 버퍼는 **비일시적(non-transient)** 으로 자동 표시됨.
> 즉각 명령 목록의 수동 Lock/Unlock 사용 금지 — 병렬 실행 방해.

---

## 메모리 수명 — AllocPOD / AllocObject / Alloc

```cpp
// ❌ 나쁜 예: 스택 변수를 레퍼런스 캡처
FMyObject Object;
GraphBuilder.AddPass(..., [&Object](FRHICommandList&) {
    // Object가 스택에 있음 → Execute 시점에 이미 파괴됨!
});

// ✅ POD 구조체 (소멸자 없음, 가장 빠름)
FMyObject* Object = GraphBuilder.AllocPOD<FMyObject>();
GraphBuilder.AddPass(..., [Object](FRHICommandList&) { /* 유효 */ });

// ✅ C++ 오브젝트 (소멸자 호출 필요 시)
FMyObject* Object = GraphBuilder.AllocObject<FMyObject>();
GraphBuilder.AddPass(..., [Object](FRHICommandList&) { /* 유효 */ });

// ✅ 미가공 메모리
void* Memory = GraphBuilder.Alloc(SizeInBytes, AlignInBytes);

// ✅ Pass Parameters (추가 트래킹 수행)
FMyParams* Params = GraphBuilder.AllocParameters<FMyParams>();
```

> 할당된 메모리는 GraphBuilder 인스턴스 소멸 시까지 유효.
> 선형 할당자 사용 — 매우 빠름.

---

## 외부 리소스 — ConvertToExternal vs Extract 차이

```cpp
// 방법 1: QueueTextureExtraction (Extract)
// 수명이 그래프 끝으로 연장 → Execute() 후 접근 가능
TRefCountPtr<IPooledRenderTarget> ExtractedTexture;
GraphBuilder.QueueTextureExtraction(Texture, &ExtractedTexture);
GraphBuilder.Execute();
// ← 이후 ExtractedTexture 유효

// 방법 2: ConvertToExternalTexture (즉시 변환)
// ★ 그래프 끝까지 기다릴 수 없을 때 사용
// 수명이 그래프 앞으로 연장 → 즉시 풀링된 포인터 반환
// 단점: 기본 할당을 다른 리소스와 공유 불가 (메모리 에일리어싱 없음)
TRefCountPtr<IPooledRenderTarget> ImmediateRef;
ImmediateRef = GraphBuilder.ConvertToExternalTexture(Texture);
// ← Execute() 전에도 ImmediateRef 접근 가능

// Buffer 버전
TRefCountPtr<FRDGPooledBuffer> PooledBuffer;
GraphBuilder.ConvertToExternalBuffer(Buffer, &PooledBuffer); // Extract
// 또는
PooledBuffer = GraphBuilder.ConvertToExternalBuffer(Buffer); // 즉시 변환
```

---

## Static Uniform Buffer — Mesh Draw Command 최적화

메시 드로 명령 캐시/공유를 위한 패스 빈도 바인딩.

```cpp
// ★ 고유 스태틱 슬롯 정의
IMPLEMENT_STATIC_UNIFORM_BUFFER_SLOT(SceneTextures);

// SceneTextures 슬롯에 데스크탑 버전 등록
IMPLEMENT_STATIC_UNIFORM_BUFFER_STRUCT(
    FSceneTextureUniformParameters, "SceneTexturesStruct", SceneTextures);

// 같은 슬롯에 모바일 버전도 등록 (한 번에 하나만 바인딩)
IMPLEMENT_STATIC_UNIFORM_BUFFER_STRUCT(
    FMobileSceneTextureUniformParameters, "MobileSceneTextures", SceneTextures);

// RDG는 각 패스 실행 전 자동으로 스태틱 UB를 명령 목록에 바인딩
// ★ 모든 스태틱 UB는 패스 파라미터 구조체에 포함해야 함
```

---

## RDG Uniform Buffer — 공식 패턴 (BEGIN_UNIFORM_BUFFER_STRUCT)

```cpp
// ★ BEGIN_UNIFORM_BUFFER_STRUCT (RDG UB용) ≠ BEGIN_GLOBAL_SHADER_PARAMETER_STRUCT
BEGIN_UNIFORM_BUFFER_STRUCT(FMyUniformParameters, )
    SHADER_PARAMETER_RDG_TEXTURE(Texture2D, Texture)
END_UNIFORM_BUFFER_STRUCT()

BEGIN_SHADER_PARAMETER_STRUCT(FMyPassParameters, )
    SHADER_PARAMETER_RDG_UNIFORM_BUFFER(FMyUniformParameters, UniformBuffer)
    RENDER_TARGET_BINDING_SLOTS()
END_SHADER_PARAMETER_STRUCT()

// 생성
FMyUniformParameters* UniformParameters = GraphBuilder.AllocParameters<FMyUniformParameters>();
UniformParameters->Texture = InputTexture;
TRDGUniformBufferRef<FMyUniformParameters> UniformBuffer =
    GraphBuilder.CreateUniformBuffer(UniformParameters);

// 사용 (Pass Lambda 내에서)
FRHIUniformBuffer* UB_RHI = UniformBuffer->GetRHI();      // RHI UB 접근
FRHITexture* TexRHI = (*UniformBuffer)->Texture->GetRHI(); // 내부 RDG 텍스처 → RHI
```

> 현재 단점: RDG UB 내 리소스는 null 처리 불가 → 사용하지 않는 파라미터도 항상 포함됨.

---

## Raster Pass — Depth Stencil EClear + 빈 람다 패턴

```cpp
PassParameters->RenderTargets.DepthStencil = FDepthStencilBinding(
    Texture,
    ERenderTargetLoadAction::EClear,        // 뎁스 하드웨어 클리어
    ERenderTargetLoadAction::EClear,        // 스텐실 하드웨어 클리어
    FExclusiveDepthStencil::DepthWrite_StencilWrite
);

GraphBuilder.AddPass(
    RDG_EVENT_NAME("ClearDepthStencil (%s)", Texture->Name),
    PassParameters,
    ERDGPassFlags::Raster,
    [](FRHICommandList&)
    {
        // ★ 빈 람다 — EClear LoadAction이 하드웨어 클리어를 처리
        // 람다 안에서 아무것도 하지 않아도 됨
    });
```

---

## 성능 프로파일링 — 공식 3종 스코프

```cpp
// 1. GPU 프로파일 영역 (RDG Insights, RenderDoc)
RDG_EVENT_SCOPE(GraphBuilder, "MyScopeName");

// 2. stat gpu 명령 영역
RDG_GPU_STAT_SCOPE(GraphBuilder, MyStatName);  // DECLARE_GPU_STAT(MyStatName) 필요

// 3. CSV 프로파일러 영역
RDG_CSV_STAT_EXCLUSIVE_SCOPE(GraphBuilder, MyCSVStat);

// ★ RDG 영역은 빌더를 입력으로 사용 — 분리된 구성/실행 타임라인을 올바르게 반영
```

---

## 코딩 규칙 (공식 문서)

1. **점으로 분리된 리소스 이름** 사용
   ```cpp
   TEXT("TSR.History.ScreenPercentage")   // ✅
   TEXT("TSRHistoryScreenPercentage")     // ❌
   ```

2. **그래프 빌더 인스턴스 이름**: `GraphBuilder`

3. **셰이더 파라미터 구조체 이름**: `FParameters`

4. **패스 네임스페이스**: `RDG_EVENT_SCOPE` 사용

5. **유틸리티 함수 우선 사용**: `RenderGraphUtils.h`, `ScreenPass.h`

---

## Async Compute — 공식 스케줄링 메커니즘

```cpp
// ★ ERDGPassFlags::AsyncCompute + FRHIComputeCommandList 조합 필수
GraphBuilder.AddPass(
    RDG_EVENT_NAME("MyAsyncComputePass"),
    PassParameters,
    ERDGPassFlags::AsyncCompute,   // ← AsyncCompute 플래그
    [PassParameters](FRHIComputeCommandList& RHICmdList)  // ← ComputeCommandList
    {
        // 실행
    });
```

동작 원리:
- RDG가 그래프를 탐색해 **마지막 생산자(Producer)** 찾음 → 펜스 삽입
- 비동기 컴퓨트 파이프에서 실행
- **첫 번째 소비자(Consumer)** 에서 그래픽 파이프와 재동기화
- 지원하지 않는 플랫폼은 그래픽 파이프로 자동 폴백
- `r.RDG.AsyncCompute` CVar로 비활성화 가능 (기본: 활성화)
