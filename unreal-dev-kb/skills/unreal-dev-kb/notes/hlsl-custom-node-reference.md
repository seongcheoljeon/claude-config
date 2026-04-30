# UnrealEngine HLSL Custom Node 작성자 레퍼런스

> 본 문서는 UE5 엔진 소스(`Engine/Shaders/Private/MaterialTemplate.ush` 외)를 직접 분석해 정리한 셰이더 작업자용 카탈로그입니다. 머티리얼 그래프의 **Custom 노드** 안에서 활용 가능한 헬퍼, 매크로, `Parameters.*` 멤버를 한곳에 모았습니다.
>
> 분석 기준 경로: `C:\Users\admin\source\repos\UnrealEngine\Engine\Shaders\` (UE 5.x)

---

## Part 1: 셀프 진단 - 무엇이 필요한가

| 시나리오 | 필요한 것 | 어디서? |
|---|---|---|
| 픽셀 위치/노멀에 접근 | `Parameters.AbsoluteWorldPosition`, `Parameters.WorldNormal` | Part 2 |
| WPO에서 정점 이동 | `Parameters.WorldPosition` (Vertex), `RotateAboutAxis` | Part 3, 4 |
| 화면/UV 좌표 | `Parameters.ScreenPosition`, `Parameters.SvPosition`, `Parameters.ViewBufferUV` | Part 2 |
| Tangent ↔ World 변환 | `TransformTangentVectorToWorld`, `TransformWorldVectorToTangent` | Part 4 |
| 회전 (축+각도) | `RotateAboutAxis(float4 axisAngle, pivot, position)` | Part 4 |
| 노이즈/난수 | `RandFast`, `RandBBSfloat`, `GradientNoise3D_*`, `SimplexNoise3D_TEX`, `VoronoiNoise3D_ALU` | Part 4 |
| 거리장 샘플 | `GetDistanceToNearestSurfaceGlobal`, `GetDistanceFieldGradientGlobal` | Part 4 |
| 카메라/시간 정보 | `ResolvedView.WorldCameraOrigin`, `View.GameTime` | Part 6 |
| 색공간 변환 | `sRGBToLinear`, `LinearToSrgb`, ACES 톤맵 | Part 7 |
| 셰이딩 모델 분기 | `MATERIAL_SHADINGMODEL_*`, `MATERIALBLENDING_*` | Part 5 |
| 파티클 데이터 | `Parameters.Particle.*` (Color, RelativeTime, Random, Velocity) | Part 2 |
| 인스턴스 데이터 | `Parameters.PerInstanceParams`, `Parameters.PerInstanceRandom` | Part 2/3 |
| LWC 안전 변환 | `WSAdd`, `WSSubtractDemote`, `DFMultiplyVector`, `WSMultiplyDemote` | Part 10 |

**Custom 노드 호출 컨벤션** — 입력 핀이 하나라도 있으면, Custom 노드 본문은 자동으로 `MaterialFloat3 CustomExpression0(FMaterialPixelParameters Parameters, ...)` 형태로 래핑됩니다. 따라서 본문에서 `Parameters.WorldNormal` 같은 표기로 바로 접근 가능합니다 (단, **함수/구조체 선언 안에서는 접근 불가**, Part 10 참조).

---

## Part 2: FMaterialPixelParameters 멤버 전체

> 정의 위치: `Engine/Shaders/Private/MaterialTemplate.ush` line ~425
> Custom 노드 본문에서 `Parameters.<이름>` 으로 접근

### 핵심 멤버

| 멤버 | 타입 | 의미 / 사용 예 |
|---|---|---|
| `TexCoords[i]` | `float2[]` | i번째 UV 채널 (`NUM_TEX_COORD_INTERPOLATORS`만큼). `Parameters.TexCoords[0]` |
| `VertexColor` | `half4` | 보간된 정점 컬러 (선형 공간) |
| `WorldNormal` | `half3` | 월드 노멀 (정규화). 노멀맵 적용 후 |
| `NormalDistribution` | `half3` | 노멀 분포 (clear coat / aniso) |
| `WorldTangent` | `half3` | 월드 탄젠트 (정규화) |
| `ReflectionVector` | `half3` | 월드 반사 벡터 |
| `CameraVector` | `float3` | **점→카메라** 벡터 (정규화) |
| `LightVector` | `half3` | 라이트 함수 렌더링 시에만 유효 |
| `SvPosition` | `float4` | `SV_POSITION` (xy=픽셀좌표, z=DeviceZ, w=SceneDepth). 뷰포트 상대 아님 |
| `ScreenPosition` | `float4` | NDC 위치 (-1..1, w=SceneDepth). w 나누기 전 |
| `ViewBufferUV` | `float2` | 뷰의 픽셀 UV (PixelDepthOffset 영향 없음) |
| `TangentToWorld` | `half3x3` | **탄젠트→월드 회전 행렬**. transpose는 World→Tangent. `[2]`는 vertex normal |
| `WorldVertexNormal_Center` | `half3` | 픽셀 중심 보간 정점 노멀 (derivative-safe) |
| `AbsoluteWorldPosition` | `FDFVector3` | 절대 월드 위치 (LWC). WPO/디스플레이스먼트 포함 |
| `WorldPosition_CamRelative` | `float3` | 카메라 상대 월드 위치 |
| `WorldPosition_NoOffsets` | `FDFVector3` | WPO 미적용 월드 위치 (`NEEDS_WORLD_POSITION_EXCLUDING_SHADER_OFFSETS` 시 유효) |
| `WorldPosition_NoOffsets_CamRelative` | `float3` | 위와 동일하나 카메라 상대 |
| `LightingPositionOffset` | `half3` | 트랜슬루선시 라이팅 오프셋 (앨리어싱 방지) |
| `UnMirrored` | `half` | UV 미러링 부호 |
| `TwoSidedSign` | `half` | 양면 표시 부호 |
| `AOMaterialMask` | `float` | AO 마스크 |
| `PerInstanceRandom` | `half` | 인스턴스별 난수 |
| `PerInstanceParams` | `float4` | 인스턴스 커스텀 파라미터 (`USE_INSTANCING || IS_NANITE_PASS`) |
| `PrimitiveId` | `uint` | View.PrimitiveSceneData 인덱스 |
| `Particle` | `FMaterialParticleParameters` | 파티클 데이터. Part 2.1 참조 |
| `LayerWeights` | `float4` | (모바일) 레이어 가중치 |

### 디리버티브 (DDX/DDY 보간 안전판)

| 멤버 | 용도 |
|---|---|
| `WorldPosition_DDX/DDY` | 위치 미분 |
| `WorldGeoNormal_DDX/DDY` | 지오 노멀 미분 |
| `VertexColor_DDX/DDY` | 정점 컬러 미분 |
| `ScreenPosition_DDX/DDY` | 스크린 위치 미분 |
| `TexCoords_DDX/DDY[i]` | UV 미분 |

### 헤어/Substrate/Nanite 전용

| 멤버 | 조건 |
|---|---|
| `HairControlPointId`, `HairPrimitiveUV`, `HairPrimitiveGroupIndex` | `HAIR_STRAND_MESH_FACTORY` |
| `InstanceLocalToWorld` (FDFMatrix) | `HAS_INSTANCE_LOCAL_TO_WORLD_PS` |
| `InstanceWorldToLocal` (FDFInverseMatrix) | `HAS_INSTANCE_WORLD_TO_LOCAL_PS` |
| `PrevScreenPosition` | `IS_NANITE_PASS` |
| `InstanceId` | `IS_NANITE_PASS` |
| `ViewId` | `MOBILE_MULTI_VIEW` |
| `CustomDataOffset/Count` | `USES_PER_INSTANCE_CUSTOM_DATA && VF_USE_PRIMITIVE_SCENE_DATA` |

### 2.1 FMaterialParticleParameters (Parameters.Particle.*)

| 멤버 | 타입 | 의미 |
|---|---|---|
| `RelativeTime` | `half` | 파티클 수명 [0..1] |
| `MotionBlurFade` | `half` | 모션 블러 페이드 |
| `Random` | `half` | 파티클별 난수 [0..1] |
| `Velocity` | `half4` | xyz=방향, w=속력 |
| `Color` | `half4` | 파티클 색 |
| `TranslatedWorldPositionAndSize` | `float4` | xyz=translated WP, w=반경 |
| `PrevTranslatedWorldPositionAndSize` | `float4` | 이전 프레임 |
| `WorldPosition` | `FWSVector3` | 절대 월드 위치 |
| `PrevWorldPosition` | `FWSVector3` | 이전 절대 위치 |
| `MacroUV` | `half4` | 매크로 UV scale/bias |
| `DynamicParameter[0..3]` | `half4` | 다이나믹 파라미터 (마스크별 활성) |
| `ParticleToWorld` | `FDFMatrix` | 메시 파티클 변환 |
| `WorldToParticle` | `FDFInverseMatrix` | 역변환 |
| `SubUVCoords[2]`, `SubUVLerp` | - | `USE_PARTICLE_SUBUVS` |

### 사용 예

```cpp
// 픽셀 노멀을 흔들기
float3 N = Parameters.WorldNormal;
float3 jitter = float3(sin(View.GameTime * 5), 0, 0) * 0.1;
return normalize(N + jitter);

// 카메라까지의 거리
float dist = length(Parameters.WorldPosition_CamRelative);

// 파티클 수명에 따라 색 페이드
return lerp(float3(1,0,0), float3(0,0,1), Parameters.Particle.RelativeTime);
```

---

## Part 3: FMaterialVertexParameters 멤버 (WPO/디스플레이스먼트용)

> 정의 위치: `MaterialTemplate.ush` line ~675

| 멤버 | 타입 | 의미 |
|---|---|---|
| `WorldPosition` | `float3` | **Translated World** 위치 (VertexFactoryGetWorldPosition 결과) |
| `PositionPrimitiveSpace` | `float3` | 프리미티브 로컬 위치 (월드 변환 전) |
| `PositionInstanceSpace` | `float3` | 인스턴스 로컬 위치 (인스턴싱 비활성 시 위와 동일) |
| `TangentToWorld` | `half3x3` | 탄젠트→월드. `[2]`가 정점 노멀 |
| `PreSkinnedPosition` | `float3` | 스키닝 적용 전 위치 |
| `PreSkinnedNormal` | `float3` | 스키닝 적용 전 노멀 |
| `VertexColor` | `half4` | 정점 컬러 |
| `TexCoords[i]` | `float2[]` | UV (`NUM_MATERIAL_TEXCOORDS_VERTEX`만큼) |
| `PerInstanceRandom` | `float` | 인스턴스 난수 |
| `InstanceLocalToWorld` | `FDFMatrix` | 인스턴스 변환 (조건부) |
| `InstanceWorldToLocal` | `FDFInverseMatrix` | 역변환 |
| `PerInstanceParams` | `float4` | 인스턴스 파라미터 |
| `InstanceId`, `InstanceOffset` | `uint` | 인스턴스 인덱스 |
| `PrevFrameLocalToWorld` | `FDFMatrix` | 이전 프레임 변환 (속도/모션블러용) |
| `Particle` | `FMaterialParticleParameters` | (파티클 VF) |
| `MaterialAttributes` | `FMaterialAttributes` | 머티리얼 출력 모음 |
| `SceneData` | `FSceneDataIntermediates` | 프리미티브 + 인스턴스 데이터 캐시 |
| `PrimitiveId` | `uint` | View.PrimitiveSceneData 인덱스 |
| `bEvaluateWorldPositionOffset` | `bool` | WPO 평가 여부 |
| `LWCData` | `FMaterialLWCData` | LWC 데이터 (절대 위치, World↔Local) |
| `CustomDataOffset/Count` | `uint` | `USES_PER_INSTANCE_CUSTOM_DATA` |
| `WaterWaveParamIndex` | `uint` | `WATER_MESH_FACTORY` |

### 사용 예 (WPO Custom 노드)

```cpp
// 인스턴스마다 무작위 회전
float angle = Parameters.PerInstanceRandom * 6.28318;
float3 axis = float3(0,0,1);
float3 pivot = Parameters.WorldPosition;
return RotateAboutAxis(float4(axis, angle), pivot, Parameters.WorldPosition);
```

---

## Part 4: 내장 헬퍼 함수 카탈로그

### 4.1 위치 / 변환

| 함수 | 시그니처 | 의미 |
|---|---|---|
| `GetTranslatedWorldPosition(Parameters)` | `float3` | 카메라 상대 월드 위치 |
| `GetWorldPosition(Parameters)` | `FWSVector3` | LWC 절대 월드 위치 |
| `GetWorldPosition_NoMaterialOffsets(Parameters)` | `FWSVector3` | WPO 미적용 절대 위치 |
| `GetTranslatedWorldPosition_NoMaterialOffsets(Parameters)` | `float3` | 위 + 카메라 상대 |
| `GetObjectWorldPosition(Parameters)` | `FWSVector3` | 오브젝트(프리미티브) 원점 |
| `GetLocalToWorld3x3(Parameters)` | `float3x3` | 로컬→월드 회전 행렬 |
| `GetLocalToWorld(Parameters)` | `FDFMatrix` | 로컬→월드 (LWC) |
| `GetPrevLocalToWorld(Parameters)` | `FDFMatrix` | 이전 프레임 |

### 4.2 벡터 변환 (Tangent/World/Local/View)

| 함수 | 입력 → 출력 |
|---|---|
| `TransformTangentVectorToWorld(TangentToWorld, V)` | Tangent → World |
| `TransformWorldVectorToTangent(Parameters, V)` | World → Tangent |
| `TransformTangentVectorToView(Parameters, V)` | Tangent → View |
| `TransformLocalVectorToWorld(Parameters, V)` | Local → World |
| `TransformLocalVectorToPrevWorld(Parameters, V)` | Local → 이전 World |
| `TransformLocalPositionToWorld(Parameters, P)` | Local → World (위치) |
| `TransformTangentNormalToWorld(TangentToWorld, N)` | 노멀 전용 Tangent → World (normalize 포함) |

> **벡터 vs 위치 구분 주의** — 위치는 평행이동이 들어가므로 별도 함수 사용. Part 10 참조.

### 4.3 회전 (RotateAboutAxis)

```cpp
// 정의: Engine/Shaders/Private/MaterialTemplate.ush:2000
float3 RotateAboutAxis(
    float4 NormalizedRotationAxisAndAngle,  // xyz=정규화된 축, w=각도(라디안)
    float3 PositionOnAxis,                  // 회전 중심점
    float3 Position                         // 회전할 점
);
// 반환값: Position에 더해야 할 *오프셋* (회전된 위치 그 자체가 아님!)

// LWC 오버로드
float3 RotateAboutAxis(float4 axisAngle, FWSVector3 pivot, FWSVector3 position);
```

**구현 핵심**: 축에 투영 → 직교축 (UAxis, VAxis) 구성 → `sincos`로 회전 → 오프셋 반환.

### 4.4 노이즈 / 랜덤 (`Random.ush`)

| 함수 | 시그니처 | 비고 |
|---|---|---|
| `Rand3DPCG16(int3 p)` | `uint3` | PCG 16-bit |
| `RandFast(uint2 PixelPos, float Magic=3571)` | `float [0,1)` | 픽셀 기반 빠른 난수, ~10 ALU |
| `RandBBSfloat(float seed)` | `float [0,1)` | Blum-Blum-Shub, ~8 ALU |
| `Hash...` | (`Random.ush` 내 다양) | 픽셀 좌표 → 난수 |
| `GradientNoise3D_ALU(v, bTiling, RepeatSize)` | `float` | Perlin 변형 (ALU) |
| `GradientNoise3D_TEX(v, bTiling, RepeatSize)` | `float` | 텍스처 LUT 사용 (빠름) |
| `ValueNoise3D_ALU(v, bTiling, RepeatSize)` | `float` | Value Noise |
| `VoronoiNoise3D_ALU(v, Quality, bTiling, RepeatSize, bDistanceOnly)` | `float4` | xyz=cell pos, w=거리 |
| `SimplexNoise3D_TEX(EvalPos)` | `float` | Simplex (텍스처 기반) |

> **Custom 노드에서 사용**: 헤더 include 필요 시 Custom 노드 detail의 *Include File Paths*에 `/Engine/Private/Random.ush` 추가.

### 4.5 거리장 (Distance Field)

> 위치: `Engine/Shaders/Private/DistanceField/GlobalDistanceFieldShared.ush`

| 함수 | 시그니처 | 의미 |
|---|---|---|
| `GetDistanceToNearestSurfaceGlobal(TranslatedWorldPosition)` | `float` | 가장 가까운 표면까지 거리 |
| `GetDistanceToNearestSurfaceGlobal(FDFVector3 WorldPosition)` | `float` | LWC 오버로드 |
| `GetDistanceToNearestSurfaceGlobal(FLWCVector3)` | `float` | LWC 오버로드 |
| `GetDistanceFieldGradientGlobal(TranslatedWorldPosition)` | `float3` | 그래디언트 (표면 노멀 추정) |
| `DistanceToNearestSurfaceForObject(ObjIdx, P, MaxDist)` | `float` | 단일 오브젝트 |

> Custom 노드에서 사용 시 Detail 패널의 *Include File Paths*에 `/Engine/Private/DistanceField/GlobalDistanceFieldShared.ush` 추가하고 입력 핀에 World Position 연결.

### 4.6 타입 헬퍼

| 매크로/타입 | 의미 |
|---|---|
| `MaterialFloat`, `MaterialFloat2/3/4` | 플랫폼별 `float` 또는 `half` (모바일 최적화) |
| `MaterialFloat3x3` | 3x3 행렬 |
| `FWSVector3` | LWC 월드 공간 벡터 (Tile + Offset) |
| `FDFVector3` | Double-Float 벡터 |
| `FDFMatrix` / `FDFInverseMatrix` | LWC 행렬 |

---

## Part 5: 자주 쓰는 매크로 / 정의

> 정의: `MaterialTemplate.ush` 상단 + 머티리얼 컴파일 시 동적 주입

### 셰이딩 모델

```cpp
MATERIAL_SHADINGMODEL_DEFAULT_LIT
MATERIAL_SHADINGMODEL_UNLIT
MATERIAL_SHADINGMODEL_SUBSURFACE
MATERIAL_SHADINGMODEL_PREINTEGRATED_SKIN
MATERIAL_SHADINGMODEL_CLEAR_COAT
MATERIAL_SHADINGMODEL_SUBSURFACE_PROFILE
MATERIAL_SHADINGMODEL_TWOSIDED_FOLIAGE
MATERIAL_SHADINGMODEL_HAIR
MATERIAL_SHADINGMODEL_CLOTH
MATERIAL_SHADINGMODEL_EYE
MATERIAL_SHADINGMODEL_SINGLELAYERWATER
MATERIAL_SHADINGMODEL_THIN_TRANSLUCENT
```

### 블렌드 모드

```cpp
MATERIALBLENDING_OPAQUE
MATERIALBLENDING_MASKED
MATERIALBLENDING_TRANSLUCENT
MATERIALBLENDING_ADDITIVE
MATERIALBLENDING_MODULATE
MATERIALBLENDING_ALPHACOMPOSITE
MATERIALBLENDING_ALPHAHOLDOUT

// 합성 매크로
MATERIALBLENDING_ANY_TRANSLUCENT  // Translucent | Additive | Modulate | Substrate translucent
MATERIALBLENDING_MASKED_USING_COVERAGE  // Forward + Masked + Alpha-to-coverage
```

### 도메인 / 노멀 / 양면

```cpp
MATERIAL_DOMAIN_SURFACE
MATERIAL_DOMAIN_DEFERREDDECAL
MATERIAL_DOMAIN_LIGHTFUNCTION
MATERIAL_DOMAIN_VOLUME
MATERIAL_DOMAIN_POSTPROCESS
MATERIAL_DOMAIN_UI

MATERIAL_TANGENTSPACENORMAL  // 1=노멀이 탄젠트 공간, 0=월드
MATERIAL_TWOSIDED            // 양면
MATERIAL_FULLY_ROUGH         // Fully Rough
MATERIAL_USE_ALPHA_TO_COVERAGE
```

### 컴파일 컨텍스트

```cpp
COMPILER_HLSL          // HLSL 컴파일러
FEATURE_LEVEL          // SM5/SM6/ES3_1 등
FEATURE_LEVEL_ES3_1    // 모바일
FORWARD_SHADING        // 포워드 패스
IS_NANITE_PASS
USE_INSTANCING
USE_INSTANCE_CULLING
HAIR_STRAND_MESH_FACTORY
WATER_MESH_FACTORY
NIAGARA_PARTICLE_FACTORY
NUM_TEX_COORD_INTERPOLATORS
NUM_MATERIAL_TEXCOORDS_VERTEX
NEEDS_WORLD_POSITION_EXCLUDING_SHADER_OFFSETS
```

### 사용 예

```cpp
#if MATERIAL_SHADINGMODEL_HAIR
    // Hair 전용 처리
#elif MATERIAL_SHADINGMODEL_DEFAULT_LIT
    // 일반 처리
#endif

#if !MATERIAL_TANGENTSPACENORMAL
    // 월드 공간 노멀일 때
#endif
```

---

## Part 6: View / ResolvedView 구조체

> 정의: `Engine/Shaders/Private/SceneView.ush`, `SceneTexturesCommon.ush`
> 인스턴스드 스테레오/멀티뷰에서는 **`ResolvedView`** 사용 (현재 눈에 해당하는 뷰), 단일뷰는 `View`로도 동작.

### 자주 쓰는 멤버

| 멤버 | 타입 | 의미 |
|---|---|---|
| `ResolvedView.WorldCameraOrigin` | `float3` | 카메라 절대 위치 (translated 기준) |
| `ResolvedView.PreViewTranslation` | `FDFVector3` | LWC ↔ Translated 변환용 |
| `ResolvedView.TranslatedWorldToView` | `float4x4` | Translated World → View |
| `ResolvedView.TranslatedWorldToClip` | `float4x4` | Translated World → Clip |
| `ResolvedView.ViewToTranslatedWorld` | `float4x4` | 역변환 |
| `ResolvedView.ClipToTranslatedWorld` | `float4x4` | Clip → World |
| `ResolvedView.ViewSizeAndInvSize` | `float4` | xy=뷰 크기, zw=1/크기 |
| `ResolvedView.ViewRectMin` | `float4` | 뷰포트 시작 |
| `ResolvedView.BufferSizeAndInvSize` | `float4` | 백버퍼 크기 |
| `View.GameTime` | `float` | 게임 시간 (초) |
| `View.RealTime` | `float` | 실시간 시간 |
| `View.DeltaTime` | `float` | 프레임 간격 |
| `View.PrevFrameGameTime` | `float` | 이전 게임 시간 |
| `View.FrameNumber` | `uint` | 프레임 번호 |
| `View.StateFrameIndexMod8` | `uint` | TAA 지터링용 |
| `View.TemporalAAParams` | `float4` | TAA 파라미터 |
| `View.PreExposure` | `float` | 자동노출 스케일 |
| `View.OneOverPreExposure` | `float` | 역수 |

### 사용 예

```cpp
// 시간 기반 애니메이션
float wave = sin(View.GameTime * 2.0);

// 카메라 거리
float3 toCam = ResolvedView.WorldCameraOrigin - Parameters.WorldPosition_CamRelative;

// SvPosition → ViewportUV
float2 viewportUV = (Parameters.SvPosition.xy - ResolvedView.ViewRectMin.xy)
                   * ResolvedView.ViewSizeAndInvSize.zw;
```

---

## Part 7: Common.ush 유틸리티

> 위치: `Engine/Shaders/Private/Common.ush`

### 산술

| 함수 | 의미 |
|---|---|
| `Square(x)` | x*x. float/2/3/4 오버로드 |
| `Pow2(x)` ~ `Pow6(x)` | x^N (오버로드 다수, line 1082~) |
| `saturate(x)` | clamp(x, 0, 1) (HLSL 내장) |
| `rcp(x)` | 1/x (HLSL 내장, 빠름) |

### 색공간

| 함수 | 의미 |
|---|---|
| `sRGBToLinear(c)` / `LinearToSrgb(c)` | sRGB ↔ Linear |
| `sRGBToLinearAccurate(c)` | 정확한 변환 (Square 대신 Pow) |

### 톤매핑 (`TonemapCommon.ush`)

| 함수 | 의미 |
|---|---|
| `TonemapAndGammaCorrect(LinearColor)` | UE 기본 톤매퍼 |
| `FilmToneMap(LinearColor)` / `FilmToneMapInverse(c)` | 필름 톤매핑 |
| `ACESOutputTransform(SceneColor, ...)` | ACES RRT+ODT |
| `ACESInvOutputTransform(...)` | ACES 역변환 |
| `HableToneMap(LinearColor)` | Hable (Uncharted 2) |
| `HableToneMapCurve(X)` | Hable 커브 |
| `SimpleReinhardToneMap(c)` | Reinhard |
| `WhiteBalance(c, Temp, Tint, ...)` | 화이트 밸런스 |
| `CorrelatedColorTemperature(x, y)` | 색온도 |

### 색 변환 (`ColorUtils.ush`, `ColorSpace.ush`)

| 함수 | 의미 |
|---|---|
| `YuvToRgb(YUV, ColorTransform, SrgbToLinear)` | YUV → RGB |
| `RgbToYuv(RGB, ColorTransform, LinearToSrgb)` | RGB → YUV |
| `RGBToHSV(rgb)` / `HSVToRGB(hsv)` | HSV 변환 (`ColorSpace.ush`에 정의) |

### 기타

| 함수 | 의미 |
|---|---|
| `EncodeNormal/DecodeNormal` | 노멀 인코딩 (G-Buffer) |
| `EncodeVelocityToTexture/DecodeVelocityFromTexture` | 모션 벡터 |
| `RaySphereIntersect`, `LineLineIntersection` | 지오메트리 헬퍼 |

---

## Part 8: Custom Node Include 시스템

### 8.1 가상 셰이더 경로

UE 셰이더 시스템은 **가상 경로**를 통해 셰이더 파일을 찾습니다.

| 가상 경로 | 매핑 위치 | 용도 |
|---|---|---|
| `/Engine/Private/...` | `Engine/Shaders/Private/` | 엔진 내부 |
| `/Engine/Public/...` | `Engine/Shaders/Public/` | 엔진 공개 헤더 |
| `/Project/...` | 프로젝트의 `Shaders/` 폴더 | 게임 모듈에서 등록 필요 |
| `/Plugin/<PluginName>/...` | 해당 플러그인의 `Shaders/` 폴더 | 플러그인 자동 등록 |

### 8.2 프로젝트 셰이더 폴더 등록

Game 모듈 `StartupModule()`에서:

```cpp
FString ShaderDir = FPaths::Combine(
    FPaths::ProjectDir(), TEXT("Shaders"));
AddShaderSourceDirectoryMapping(TEXT("/Project"), ShaderDir);
```

이후 Custom 노드의 *Include File Paths*에 `/Project/MyHelpers.ush` 입력 가능.

### 8.3 .ush vs .usf

| 확장자 | 용도 |
|---|---|
| `.ush` | 헤더 (Unreal Shader Header). `#include` 전용. 셰이더 진입점 없음 |
| `.usf` | 셰이더 본문 (Unreal Shader File). `MainPS`, `MainVS` 같은 entrypoint 보유 |

> **Custom 노드 include는 항상 .ush** — 진입점이 있는 .usf를 include하면 컴파일 충돌.

### 8.4 Custom 노드 Include 사용법

1. Custom 노드 선택 → Detail 패널
2. **Include File Paths** 배열에 가상 경로 추가
   - 예: `/Engine/Private/Random.ush`
   - 예: `/Project/MyMath.ush`
3. 본문에서 함수/매크로 호출

---

## Part 9: 디버깅 패턴

### 9.1 값 시각화

```cpp
// 단일 스칼라를 컬러로
return float3(saturate(value), 0, 0);

// 음수 / 양수 표시
return float3(saturate(-value), saturate(value), 0);

// 범위 체크 ([0,1] 안인지)
return any(value < 0 || value > 1) ? float3(1,0,1) : float3(value, 0);

// UV 시각화
return float3(Parameters.TexCoords[0], 0);

// 노멀 시각화 (월드)
return Parameters.WorldNormal * 0.5 + 0.5;
```

### 9.2 분기 디버깅

```cpp
// 특정 조건 강조
float test = (Parameters.AOMaterialMask > 0.5) ? 1.0 : 0.0;
return float3(test, 0, 0);
```

### 9.3 컴파일 에러 해석

| 에러 | 원인 | 해결 |
|---|---|---|
| `error X3067: ambiguous function call` | Pixel/Vertex Parameters 동일 float 수 | 엔진 자동 처리됨 (`Dummy uint` 추가) |
| `'Parameters' is undeclared` | 함수/struct 안에서 접근 | Part 10.1 참조 |
| `cannot convert from 'FWSVector3' to 'float3'` | LWC 타입 미스매치 | `WSMultiplyDemote` / `DFDemote` 사용 |
| `not all control paths return a value` | 모든 분기가 return 안함 | 마지막에 default return 추가 |
| `redefinition of '...'` | Include 파일에 implementation 포함 | .ush를 헤더로만, 가드(`#pragma once`) 사용 |

### 9.4 Shader Complexity 뷰모드

뷰포트 → Show → Visualize → Shader Complexity. Custom 노드 비용 즉시 확인.

---

## Part 10: 흔한 함정

### 10.1 Parameters는 함수/struct 선언 안에서 접근 불가

```cpp
// 잘못된 예
float3 MyHelper()
{
    return Parameters.WorldNormal;  // 컴파일 에러: undeclared
}
return MyHelper();

// 올바른 예
float3 MyHelper(FMaterialPixelParameters Params)
{
    return Params.WorldNormal;
}
return MyHelper(Parameters);
```

### 10.2 mul() 인자 순서

UE 셰이더는 **row-major** 컨벤션이지만, HLSL `mul`은 행렬 위치에 따라 결과가 다름.

```cpp
// 벡터를 행렬로 변환 (행 벡터 컨벤션)
float3 worldVec = mul(localVec, LocalToWorld3x3);  // OK

// 열 벡터로 쓰면 잘못된 결과
float3 wrong = mul(LocalToWorld3x3, localVec);  // 다른 결과!

// TangentToWorld는 row-major이므로 vec * mat
float3 worldNormal = mul(tangentNormal, Parameters.TangentToWorld);
```

### 10.3 LWC vs Float

UE5는 **Large World Coordinates** (LWC)를 도입. 절대 위치는 `FWSVector3` / `FDFVector3`로 저장됨.

| 작업 | 함수 |
|---|---|
| LWC 덧셈 | `WSAdd(a, b)` |
| LWC 뺄셈 (결과를 float3로) | `WSSubtractDemote(a, b)` |
| LWC × 행렬 | `WSMultiply(P, M)` |
| LWC → float3 (저장된 정밀도 손실 감수) | `WSMultiplyDemote(P, WorldToLocal)` |
| 방향 벡터 변환 | `DFMultiplyVector(V, M)` (위치가 아닌 방향) |

```cpp
// 잘못: LWC를 float3로 직접 사용
float3 wp = Parameters.AbsoluteWorldPosition;  // 정밀도 손실 + 컴파일 경고

// 올바름: TranslatedWorldPosition 사용 (이미 카메라 상대)
float3 twp = GetTranslatedWorldPosition(Parameters);

// LWC 위치 차이는 float3로 안전하게 표현 가능 (작은 거리)
float3 delta = WSSubtractDemote(P1_lwc, P2_lwc);
```

### 10.4 Position vs Direction 변환

평행이동(translation) 포함 여부가 다름.

| 종류 | 함수 |
|---|---|
| 위치 (Translation 적용) | `Transform*PositionTo*` |
| 방향/벡터 (Translation 무시) | `Transform*VectorTo*` |
| 노멀 (스케일 보정 + normalize) | `TransformTangentNormalToWorld` |

### 10.5 ResolvedView vs View

- 단일뷰 렌더링: 둘 다 동일
- 인스턴스드 스테레오/멀티뷰: **반드시 `ResolvedView`** 사용 (현재 처리 중인 눈)
- 안전하게 항상 `ResolvedView` 사용 권장

### 10.6 half vs float

모바일에서는 `half` (16-bit)로 다운캐스트 가능. `MaterialFloat*` 매크로는 플랫폼별 자동 선택. 정밀도 필요 시 명시적으로 `float` 사용.

### 10.7 Custom 노드의 출력 타입

Custom 노드 Detail의 **Output Type**과 본문 `return`이 일치해야 함. 불일치 시 silent truncation 또는 에러.

---

## Part 11: 참고 파일 위치

| 파일 | 내용 |
|---|---|
| [`Engine/Shaders/Private/MaterialTemplate.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/MaterialTemplate.ush) | **핵심**. Parameters 구조체 + 헬퍼 함수 모두 |
| [`Engine/Shaders/Private/Common.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/Common.ush) | Square, Pow*, sRGB, 인코딩 |
| [`Engine/Shaders/Private/Random.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/Random.ush) | 노이즈/난수 (RandFast, GradientNoise, Voronoi, Simplex) |
| [`Engine/Shaders/Private/RandomPCG.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/RandomPCG.ush) | PCG 난수 |
| [`Engine/Shaders/Private/RandomInterleavedGradientNoise.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/RandomInterleavedGradientNoise.ush) | TAA 지터링 노이즈 |
| [`Engine/Shaders/Private/SceneView.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/SceneView.ush) | View / ResolvedView 정의 |
| [`Engine/Shaders/Private/ColorUtils.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/ColorUtils.ush) | YUV ↔ RGB |
| [`Engine/Shaders/Private/ColorSpace.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/ColorSpace.ush) | HSV, 색공간 변환 |
| [`Engine/Shaders/Private/TonemapCommon.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/TonemapCommon.ush) | ACES, Hable, FilmToneMap |
| [`Engine/Shaders/Private/DistanceField/GlobalDistanceFieldShared.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Private/DistanceField/GlobalDistanceFieldShared.ush) | GetDistanceToNearestSurfaceGlobal 등 |
| [`Engine/Shaders/Public/Platform.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Public/Platform.ush) | 플랫폼 매크로 (`MaterialFloat*` 정의) |
| [`Engine/Shaders/Public/FP16Math.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Public/FP16Math.ush) | half 수학 |
| [`Engine/Shaders/Public/WaveBroadcastIntrinsics.ush`](file:///mnt/c/Users/admin/source/repos/UnrealEngine/Engine/Shaders/Public/WaveBroadcastIntrinsics.ush) | Wave intrinsics |

---

## 빠른 치트시트

```cpp
// === 좌표 ===
Parameters.AbsoluteWorldPosition       // LWC 절대 월드 (FDFVector3)
GetTranslatedWorldPosition(Parameters) // 카메라 상대 (float3) -- 가장 안전
Parameters.ScreenPosition              // NDC (-1..1)
Parameters.SvPosition.xy               // 픽셀 좌표
Parameters.ViewBufferUV                // 뷰 UV [0..1]

// === 노멀/탄젠트 ===
Parameters.WorldNormal                 // 픽셀 노멀
Parameters.TangentToWorld[2]           // 정점 노멀
mul(tangentNormal, Parameters.TangentToWorld)  // T → W

// === 시간/카메라 ===
View.GameTime
ResolvedView.WorldCameraOrigin
Parameters.CameraVector                // 점→카메라

// === 회전 ===
RotateAboutAxis(float4(axis, angle), pivot, position)  // 오프셋 반환!

// === 노이즈 ===
RandFast(uint2(Parameters.SvPosition.xy))
GradientNoise3D_TEX(worldPos * 0.01, false, 0)

// === 거리장 ===
GetDistanceToNearestSurfaceGlobal(GetTranslatedWorldPosition(Parameters))

// === 색 ===
sRGBToLinear(c), LinearToSrgb(c)
Square(x), Pow5(x)

// === 분기 ===
#if MATERIAL_SHADINGMODEL_HAIR ...
#if !MATERIAL_TANGENTSPACENORMAL ...
```
