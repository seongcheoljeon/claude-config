# RDG Uniform Buffer 패턴

## 언제 쓰나

- 여러 Pass가 **동일한 파라미터 세트**를 공유할 때
- Shader에서 `cbuffer` 로 묶어 접근하고 싶을 때
- `FViewUniformShaderParameters` 같은 엔진 내장 UB를 바인딩할 때

---

## Custom Uniform Buffer 정의

```cpp
// 선언 (헤더)
BEGIN_GLOBAL_SHADER_PARAMETER_STRUCT(FMyUniformBuffer, )
    SHADER_PARAMETER(FVector4f,  Color)
    SHADER_PARAMETER(float,      Intensity)
    SHADER_PARAMETER(FIntPoint,  Resolution)
    SHADER_PARAMETER_TEXTURE(Texture2D, LUTTexture)
    SHADER_PARAMETER_SAMPLER(SamplerState, LUTSampler)
END_GLOBAL_SHADER_PARAMETER_STRUCT()

// 구현 (소스)
IMPLEMENT_GLOBAL_SHADER_PARAMETER_STRUCT(FMyUniformBuffer, "MyUB");
```

## RDG Uniform Buffer 생성 및 바인딩

```cpp
// 데이터 채우기
FMyUniformBuffer UBData;
UBData.Color      = FVector4f(1, 0, 0, 1);
UBData.Intensity  = 2.0f;
UBData.Resolution = FIntPoint(1920, 1080);
UBData.LUTTexture = LUTTextureRHI;
UBData.LUTSampler = TStaticSamplerState<SF_Bilinear>::GetRHI();

// RDG UB 생성
TRDGUniformBufferRef<FMyUniformBuffer> RDGUB =
    GraphBuilder.CreateUniformBuffer(GraphBuilder.AllocParameters<FMyUniformBuffer>(UBData));

// Pass Parameters에 바인딩
SHADER_PARAMETER_RDG_UNIFORM_BUFFER(FMyUniformBuffer, MyUB)   // Parameters 구조체에 선언
Params->MyUB = RDGUB;
```

## USF에서 접근

```hlsl
// MyUB는 IMPLEMENT_GLOBAL_SHADER_PARAMETER_STRUCT 두 번째 인자와 동일
float4 Color     = MyUB.Color;
float  Intensity = MyUB.Intensity;
```

---

## 엔진 내장 Uniform Buffer 바인딩

```cpp
// View Uniform Buffer
SHADER_PARAMETER_STRUCT_REF(FViewUniformShaderParameters, View)
Params->View = View.ViewUniformBuffer;

// SceneTextures UB (PostProcess에서)
SHADER_PARAMETER_STRUCT_REF(FSceneTextureUniformParameters, SceneTextures)
Params->SceneTextures = Inputs.SceneTextures;

// Primitive UB
SHADER_PARAMETER_STRUCT_REF(FPrimitiveUniformShaderParameters, Primitive)
```

---

## 주의사항

- UB 내부에 `FRDGTexture*`/`FRDGBuffer*` 직접 넣기 불가 → `SHADER_PARAMETER_TEXTURE` (RHI) 사용
- RDG 리소스를 UB에 넣으려면 `TRDGUniformBufferRef` + `SHADER_PARAMETER_RDG_UNIFORM_BUFFER` 패턴 사용
- UB는 Pass 당 한 번만 바인딩 — 같은 UB를 여러 Pass에 재사용 가능
