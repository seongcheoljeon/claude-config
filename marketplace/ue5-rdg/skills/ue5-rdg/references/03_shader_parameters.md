# Shader Parameters 바인딩

## SHADER_PARAMETER_STRUCT 매크로 목록

### 기본 타입
```cpp
SHADER_PARAMETER(float,      MyFloat)
SHADER_PARAMETER(FVector4f,  MyVec4)     // ★ UE5: FVector4f (not FVector4)
SHADER_PARAMETER(FMatrix44f, MyMatrix)   // ★ UE5: FMatrix44f
SHADER_PARAMETER(uint32,     MyUint)
SHADER_PARAMETER(int32,      MyInt)
SHADER_PARAMETER(FIntPoint,  MyIntPoint)
SHADER_PARAMETER(FIntVector, MyIntVector)
```

### RDG Texture
```cpp
SHADER_PARAMETER_RDG_TEXTURE(Texture2D,                 MyTexture)       // SRV (자동)
SHADER_PARAMETER_RDG_TEXTURE_SRV(Texture2D,             MySRV)           // 명시적 SRV
SHADER_PARAMETER_RDG_TEXTURE_UAV(RWTexture2D<float4>,   MyUAV)           // UAV
SHADER_PARAMETER_RDG_TEXTURE_ARRAY(Texture2D,           MyTexArray, [4]) // 배열
```

### RDG Buffer
```cpp
SHADER_PARAMETER_RDG_BUFFER_SRV(StructuredBuffer<FMyStruct>, MyBufSRV)
SHADER_PARAMETER_RDG_BUFFER_UAV(RWStructuredBuffer<FMyStruct>, MyBufUAV)
SHADER_PARAMETER_RDG_BUFFER_SRV(Buffer<float4>,          MyTypedBuf)
```

### Sampler
```cpp
SHADER_PARAMETER_SAMPLER(SamplerState, MySampler)
// 바인딩:
Params->MySampler = TStaticSamplerState<SF_Linear, AM_Clamp>::GetRHI();
```

### 외부 RHI 리소스 (non-RDG)
```cpp
SHADER_PARAMETER_TEXTURE(Texture2D,    MyExtTex)   // FRHITexture*
SHADER_PARAMETER_SRV(Texture2D,        MyExtSRV)   // FRHIShaderResourceView*
SHADER_PARAMETER_UAV(RWTexture2D<...>, MyExtUAV)   // FRHIUnorderedAccessView*
```

### Uniform Buffer / View Uniform Buffer
```cpp
SHADER_PARAMETER_STRUCT_REF(FViewUniformShaderParameters, View)
SHADER_PARAMETER_STRUCT_REF(FSceneTextureUniformParameters, SceneTextures)
SHADER_PARAMETER_RDG_UNIFORM_BUFFER(FMyUniformBuffer, MyUB)

// 바인딩:
Params->View = View.ViewUniformBuffer;
```

### Render Target (Raster Pass 전용)
```cpp
RENDER_TARGET_BINDING_SLOTS()
// 바인딩:
Params->RenderTargets[0] = FRenderTargetBinding(MyRDGTexture, ERenderTargetLoadAction::ELoad);
Params->RenderTargets.DepthStencil = FDepthStencilBinding(
    DepthTex, ERenderTargetLoadAction::ELoad, ERenderTargetLoadAction::ENoAction,
    FExclusiveDepthStencil::DepthWrite_StencilNop);
```

---

## Global Shader 선언 패턴

```cpp
// Header (.h)
class FMyShader : public FGlobalShader
{
    DECLARE_GLOBAL_SHADER(FMyShader);
    SHADER_USE_PARAMETER_STRUCT(FMyShader, FGlobalShader);

    BEGIN_SHADER_PARAMETER_STRUCT(FParameters, )
        SHADER_PARAMETER(FVector4f, Params)
        SHADER_PARAMETER_RDG_TEXTURE_SRV(Texture2D, InputTex)
        SHADER_PARAMETER_RDG_TEXTURE_UAV(RWTexture2D<float4>, OutputTex)
    END_SHADER_PARAMETER_STRUCT()

    // Permutation (선택)
    class FMyPermutationDim : SHADER_PERMUTATION_BOOL("MY_FEATURE");
    using FPermutationDomain = TShaderPermutationDomain<FMyPermutationDim>;

    static bool ShouldCompilePermutation(const FGlobalShaderPermutationParameters& Parameters)
    {
        return IsFeatureLevelSupported(Parameters.Platform, ERHIFeatureLevel::SM5);
    }
};

// Source (.cpp)
IMPLEMENT_GLOBAL_SHADER(FMyShader, "/MyPlugin/MyShader.usf", "MainCS", SF_Compute);
```

## Permutation 사용
```cpp
FMyShader::FPermutationDomain PermutationVector;
PermutationVector.Set<FMyShader::FMyPermutationDim>(bMyFeature);
TShaderMapRef<FMyShader> Shader(GetGlobalShaderMap(GMaxRHIFeatureLevel), PermutationVector);
```

---

## Virtual Shader Path 등록

`/MyPlugin/` 경로를 엔진에 등록하려면:

```cpp
// MyPlugin.cpp (IModuleInterface::StartupModule)
FString ShaderDir = FPaths::Combine(IPluginManager::Get()
    .FindPlugin(TEXT("MyPlugin"))->GetBaseDir(), TEXT("Shaders"));
AddShaderSourceDirectoryMapping(TEXT("/MyPlugin"), ShaderDir);
```

또는 `uplugin`에서:
```json
"ShaderDirectories": [{ "Path": "Shaders" }]
```
