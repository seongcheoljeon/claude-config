# FRDGTexture / FRDGBuffer 리소스 관리

## Texture

### 생성 (Transient)
```cpp
// 2D Texture
FRDGTextureDesc Desc = FRDGTextureDesc::Create2D(
    Extent,           // FIntPoint
    PixelFormat,      // EPixelFormat (PF_FloatRGBA 등)
    ClearValue,       // FClearValueBinding
    Flags             // ETextureCreateFlags
);
FRDGTextureRef Tex = GraphBuilder.CreateTexture(Desc, TEXT("DebugName"));

// 자주 쓰는 Flags 조합
TexCreate_ShaderResource | TexCreate_UAV                    // Compute RW
TexCreate_ShaderResource | TexCreate_RenderTargetable       // Raster RT
TexCreate_ShaderResource | TexCreate_DepthStencilTargetable // Depth
TexCreate_ShaderResource | TexCreate_UAV | TexCreate_RenderTargetable // 혼합
```

### FRDGTextureDesc 팩토리 메서드
```cpp
FRDGTextureDesc::Create2D(Extent, Format, ClearValue, Flags)
FRDGTextureDesc::Create2DArray(Extent, Format, ClearValue, Flags, ArraySize)
FRDGTextureDesc::Create3D(Size, Format, ClearValue, Flags)          // FIntVector
FRDGTextureDesc::CreateCube(Size, Format, ClearValue, Flags)
```

### SRV / UAV 생성
```cpp
// SRV (기본 — 전체 Mip, 전체 Array)
FRDGTextureSRVRef SRV = GraphBuilder.CreateSRV(Tex);

// SRV (특정 Mip)
FRDGTextureSRVRef SRV = GraphBuilder.CreateSRV(
    FRDGTextureSRVDesc::CreateForMipLevel(Tex, MipIndex));

// SRV (특정 Array Slice)
FRDGTextureSRVRef SRV = GraphBuilder.CreateSRV(
    FRDGTextureSRVDesc::CreateForSlice(Tex, ArraySlice));

// UAV (Mip 0)
FRDGTextureUAVRef UAV = GraphBuilder.CreateUAV(Tex);

// UAV (특정 Mip)
FRDGTextureUAVRef UAV = GraphBuilder.CreateUAV(
    FRDGTextureUAVDesc(Tex, MipIndex));
```

### 외부 리소스 → RDG 등록
```cpp
// IPooledRenderTarget → RDG
FRDGTextureRef RDGTex = GraphBuilder.RegisterExternalTexture(PooledRT);

// FRHITexture → RDG (CreateRenderTarget 래퍼 사용)
TRefCountPtr<IPooledRenderTarget> Wrapped = CreateRenderTarget(RHITexture, TEXT("Name"));
FRDGTextureRef RDGTex = GraphBuilder.RegisterExternalTexture(Wrapped);

// 이미 RDGTexture가 있고 두 번 등록 방지
FRDGTextureRef RDGTex = GraphBuilder.FindExternalTexture(PooledRT);
if (!RDGTex) RDGTex = GraphBuilder.RegisterExternalTexture(PooledRT);
```

### RDG → 외부 유지 (Extract)
```cpp
TRefCountPtr<IPooledRenderTarget> OutPooled;
GraphBuilder.QueueTextureExtraction(RDGTex, &OutPooled);
// Execute() 이후 OutPooled 사용 가능
```

---

## Buffer

### 생성 (Transient)
```cpp
// Structured Buffer
FRDGBufferDesc Desc = FRDGBufferDesc::CreateStructuredDesc(
    sizeof(FMyStruct),   // 원소 크기
    ElementCount         // 원소 수
);
FRDGBufferRef Buffer = GraphBuilder.CreateBuffer(Desc, TEXT("MyBuffer"));

// ByteAddress Buffer
FRDGBufferDesc Desc = FRDGBufferDesc::CreateByteAddressDesc(SizeInBytes);

// Vertex Buffer
FRDGBufferDesc Desc = FRDGBufferDesc::CreateBufferDesc(Stride, NumElements);

// Upload Buffer (CPU → GPU)
FRDGBufferDesc Desc = FRDGBufferDesc::CreateUploadDesc(sizeof(T), Count);
```

### Buffer SRV / UAV
```cpp
FRDGBufferSRVRef SRV = GraphBuilder.CreateSRV(Buffer, PixelFormat); // typed
FRDGBufferSRVRef SRV = GraphBuilder.CreateSRV(FRDGBufferSRVDesc(Buffer)); // structured

FRDGBufferUAVRef UAV = GraphBuilder.CreateUAV(Buffer, PixelFormat); // typed
FRDGBufferUAVRef UAV = GraphBuilder.CreateUAV(FRDGBufferUAVDesc(Buffer)); // structured
```

### Upload (CPU 데이터 → GPU Buffer)
```cpp
// 방법 1: GraphBuilder.AllocUploadData
MyStruct* UploadData = GraphBuilder.AllocPODArray<MyStruct>(Count);
FMemory::Memcpy(UploadData, SrcData, sizeof(MyStruct) * Count);

// 방법 2: FRDGUploadData 패턴 (UE5.3+)
GraphBuilder.QueueBufferUpload(Buffer, UploadData, sizeof(MyStruct) * Count);
```

---

## 리소스 수명 요약

| 종류 | 생성 시점 | 해제 시점 | 비고 |
|------|-----------|-----------|------|
| Transient Texture | `CreateTexture()` | 마지막 사용 Pass 이후 | 자동 풀링 |
| Transient Buffer | `CreateBuffer()` | 마지막 사용 Pass 이후 | 자동 풀링 |
| External (등록) | `RegisterExternalTexture()` | `Execute()` 완료 | 외부 소유 |
| Extracted | `QueueTextureExtraction()` | 명시적 Release | 추출 후 외부 소유 |
