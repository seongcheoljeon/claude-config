# GraphBuilder 생명주기 & 핵심 API

## 생명주기

```
FRDGBuilder GraphBuilder(RHICmdList, RDGEventName, ERDGBuilderFlags)
    │
    ├─ CreateTexture() / CreateBuffer()       ← 리소스 선언 (메모리 미할당)
    ├─ RegisterExternalTexture()              ← 외부 리소스 임포트
    ├─ AddPass()                              ← Pass 그래프에 추가
    ├─ QueueTextureExtraction()               ← Execute 후 결과 유지 예약
    │
    └─ Execute()                              ← 그래프 컴파일 + GPU 커맨드 발행
```

## 생성자

```cpp
// 일반 사용 (Render Thread)
FRDGBuilder GraphBuilder(RHICmdList);

// 이벤트 이름 포함 (GPU Profiling)
FRDGBuilder GraphBuilder(RHICmdList, RDG_EVENT_NAME("MyRenderPass"));

// 플래그
// ERDGBuilderFlags::AllowParallelExecute  — 병렬 실행 허용 (UE5.1+)
FRDGBuilder GraphBuilder(RHICmdList, RDG_EVENT_NAME(""), ERDGBuilderFlags::AllowParallelExecute);
```

## 핵심 메서드

### AllocParameters
```cpp
// Pass Parameters 구조체를 RDG 스택에 할당
// 반드시 GraphBuilder.AllocParameters 사용 (스택/힙 직접 할당 금지)
FMyShader::FParameters* Params = GraphBuilder.AllocParameters<FMyShader::FParameters>();
```

### AddPass
```cpp
// 일반 AddPass
GraphBuilder.AddPass(
    RDG_EVENT_NAME("PassName"),        // GPU 이벤트 이름
    Parameters,                         // SHADER_PARAMETER_STRUCT 포인터
    ERDGPassFlags::Compute,             // Pass 타입 플래그
    [LocalParam = Parameters](FRHIComputeCommandList& RHICmdList)
    {
        // ★ 여기서 FRDGTextureRef 사용 금지 — GetRHI() 호출해서 FRHITexture* 사용
        RHICmdList.SetComputeShader(...);
    }
);
```

### ERDGPassFlags

| Flag | 의미 |
|------|------|
| `Compute` | Async Compute 가능한 Compute Pass |
| `Raster` | Rasterization Pass (RTV/DSV 바인딩 포함) |
| `Copy` | Copy 전용 Pass |
| `NeverCull` | Culling 방지 (디버그, 강제 실행) |
| `AsyncCompute` | 명시적 Async Compute 큐 사용 |
| `SkipRenderPass` | BeginRenderPass/EndRenderPass 없이 Raster 사용 |

### QueueTextureExtraction / QueueBufferExtraction
```cpp
TRefCountPtr<IPooledRenderTarget> OutRT;
GraphBuilder.QueueTextureExtraction(RDGTexture, &OutRT);
// Execute() 완료 후 OutRT 유효

TRefCountPtr<FRDGPooledBuffer> OutBuf;
GraphBuilder.QueueBufferExtraction(RDGBuffer, &OutBuf);
```

### Execute
```cpp
GraphBuilder.Execute();
// 이후 GraphBuilder 사용 불가
// QueueTextureExtraction한 리소스는 이 시점 이후 접근 가능
```

## RDGEventName 매크로

```cpp
RDG_EVENT_NAME("StaticName")
RDG_EVENT_NAME("Dynamic_%d", SomeInt)
RDG_EVENT_SCOPE(GraphBuilder, "ScopeName")   // 중첩 스코프
```

## 중요 주의사항

1. **Lambda 캡처**: `FRDGTextureRef`/`FRDGBufferRef`를 lambda에 직접 캡처하면 안 됨.
   Parameters 포인터를 캡처하거나, `PassParameters->Texture->GetRHI()` 패턴 사용.

2. **Render Thread 전용**: GraphBuilder는 Render Thread에서만 사용.

3. **Parameters 수명**: `AllocParameters`로 할당된 메모리는 `Execute()` 까지 RDG가 관리.
