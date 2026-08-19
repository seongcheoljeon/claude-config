# Buffer Readback (GPU → CPU)

## 원칙

GPU Readback은 **비동기 + 지연 접근** 패턴이 필수.
같은 프레임에서 Write → Read는 GPU 스톨(stall)을 유발하므로 **N 프레임 후 읽기** 권장.

---

## FRHIGPUBufferReadback (권장)

```cpp
// 멤버 변수로 보관
TUniquePtr<FRHIGPUBufferReadback> Readback;

// 초기화 (한 번)
Readback = MakeUnique<FRHIGPUBufferReadback>(TEXT("MyReadback"));
```

### Readback 요청 (Render Thread)

```cpp
void RequestReadback(FRDGBuilder& GraphBuilder, FRDGBufferRef SourceBuffer)
{
    AddEnqueueCopyPass(GraphBuilder, Readback.Get(), SourceBuffer, 0 /*전체 크기*/);
    // 또는 크기 지정:
    AddEnqueueCopyPass(GraphBuilder, Readback.Get(), SourceBuffer, sizeof(FMyStruct) * Count);
}
```

### 결과 읽기 (다음 프레임 이후)

```cpp
// Render Thread에서 준비 여부 확인
if (Readback->IsReady())
{
    const FMyStruct* Data = static_cast<const FMyStruct*>(
        Readback->Lock(sizeof(FMyStruct) * Count));

    // ★ Lock ~ Unlock 사이에서만 포인터 유효
    for (int32 i = 0; i < Count; ++i)
    {
        ProcessData(Data[i]);
    }

    Readback->Unlock();
}
```

---

## FRHIGPUTextureReadback

```cpp
TUniquePtr<FRHIGPUTextureReadback> TextureReadback;
TextureReadback = MakeUnique<FRHIGPUTextureReadback>(TEXT("MyTexReadback"));

// 요청
AddEnqueueCopyPass(GraphBuilder, TextureReadback.Get(), SourceTexture, FIntVector(Width, Height, 1));

// 읽기
if (TextureReadback->IsReady())
{
    int32 OutRowPitchInPixels;
    const void* Data = TextureReadback->Lock(OutRowPitchInPixels);
    // ... 처리 ...
    TextureReadback->Unlock();
}
```

---

## N 프레임 지연 패턴 (Production 권장)

```cpp
// 멤버 변수
static constexpr int32 ReadbackDelay = 2; // 2프레임 지연
TArray<TUniquePtr<FRHIGPUBufferReadback>> ReadbackPool;
int32 WriteIndex = 0;
int32 ReadIndex  = 0;

// 초기화
for (int32 i = 0; i < ReadbackDelay + 1; ++i)
    ReadbackPool.Add(MakeUnique<FRHIGPUBufferReadback>(TEXT("Readback")));

// 매 프레임 (Render Thread)
void PerFrame(FRDGBuilder& GraphBuilder, FRDGBufferRef Buffer)
{
    // 이전 프레임 결과 읽기
    auto& PendingReadback = ReadbackPool[ReadIndex % ReadbackPool.Num()];
    if (PendingReadback->IsReady())
    {
        const FMyStruct* Data = static_cast<const FMyStruct*>(
            PendingReadback->Lock(DataSize));
        ConsumeData(Data);
        PendingReadback->Unlock();
    }

    // 현재 프레임 요청
    AddEnqueueCopyPass(GraphBuilder,
        ReadbackPool[WriteIndex % ReadbackPool.Num()].Get(), Buffer, DataSize);

    WriteIndex++;
    ReadIndex = FMath::Max(0, WriteIndex - ReadbackDelay);
}
```

---

## Game Thread로 결과 전달

```cpp
// Render Thread에서 읽은 데이터를 Game Thread로 전달
TArray<FMyStruct> ResultCopy(Data, Count); // 복사

AsyncTask(ENamedThreads::GameThread, [ResultCopy = MoveTemp(ResultCopy)]()
{
    // Game Thread에서 안전하게 사용
    for (const FMyStruct& Item : ResultCopy)
        ProcessOnGameThread(Item);
});
```

---

## 주의사항

| 규칙 | 이유 |
|------|------|
| 같은 프레임 Write→Read 금지 | GPU stall (수 ms ~ 수십 ms) |
| `IsReady()` 확인 후 `Lock()` | 준비 전 Lock은 강제 stall 발생 |
| Lock 후 즉시 Unlock | 포인터 보관 금지 |
| Readback 오브젝트 재사용 | 매 프레임 new/delete 금지 |
