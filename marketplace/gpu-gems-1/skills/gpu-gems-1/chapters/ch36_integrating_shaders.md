# Chapter 36: Integrating Shaders into Applications
> 저자: John O'Rorke (Monolith Productions)

## 핵심 개념
- **해결하려는 문제**: 애플리케이션에 셰이더를 통합하여 유연하고 데이터 드리븐한 렌더러를 구축하는 방법
- 셰이더 API 사용법이 아닌, 애플리케이션과 셰이더 사이의 **통신 레이어(glue layer)** 설계
- 렌더링 스테이트를 **리소스**로 취급 — 렌더러를 거의 완전히 데이터 드리븐으로 만듦
- 시맨틱(Semantic)과 어노테이션(Annotation)으로 셰이더-앱 간 데이터 바인딩
- 셰이더 폴백(fallback) 전략으로 다양한 하드웨어 지원

## 기술적 세부사항

### 셰이더를 리소스로 취급
- 과거: 텍스처, 메시만 외부 리소스
- 현재: 셰이더(.fx)도 외부 리소스 → **렌더러가 거의 완전히 데이터 드리븐**
- 디바이스 렌더링 설정까지 셰이더 파일이 제어

### 셰이더-앱 간 데이터 통신

#### 1. 씬 정보 파라미터
- 카메라 변환, 라이트 위치/색상 등 씬 상태
- 시맨틱으로 자동 바인딩:
```hlsl
float4x4 wvp : WorldViewProjection;  // 시맨틱 바인딩
```
- FX Composer 스타일 — 변수명은 자유, 시맨틱이 용도를 결정

#### 2. 머티리얼 파라미터
- 셰이더별 고유 파라미터 (스페큘러 강도, 색상 등)
- 어노테이션으로 기본값, 설명, UI 정보 제공:
```hlsl
float Specular = 4.0 : MaterialParam 
    < float Default = 1.0; string Desc = "Specular power"; >;
```

#### 3. 텍스처 바인딩
- 어노테이션으로 텍스처 용도 지정 (diffuse, normal, environment 등)
- 애플리케이션이 어노테이션을 읽어 적절한 텍스처 로딩

### 셰이더 폴백 전략
- 하드웨어가 셰이더를 지원하지 않을 경우의 대처
- .fx 파일 내에 여러 technique 정의 (품질 순서대로)
- 런타임에 하드웨어 능력에 맞는 technique 자동 선택:
```
technique HighQuality { ... }  // SM 3.0
technique MedQuality  { ... }  // SM 2.0
technique LowQuality  { ... }  // Fixed Function
```

### 렌더링 루프 설계
1. 씬 상태 업데이트 (카메라, 라이트)
2. 오브젝트별 머티리얼(셰이더) 바인딩
3. 시맨틱 기반으로 자동 파라미터 설정
4. 머티리얼별 텍스처 바인딩
5. 패스별 렌더링 (멀티패스 이펙트)

## 수식 및 알고리즘
```
// 데이터 드리븐 렌더링 루프 의사코드
for each object in scene:
    shader = object.material.shader
    technique = shader.SelectBestTechnique(hardware)
    
    for each pass in technique:
        // 시맨틱 기반 자동 바인딩
        for each param in pass.parameters:
            if param.semantic == "WorldViewProjection":
                param.value = camera.WVP
            elif param.semantic == "LightPosition":
                param.value = light.position
            elif param.annotation["MaterialParam"]:
                param.value = material.GetParam(param.name)
        
        pass.Apply()
        object.Draw()
```

## UE5 관점에서의 활용
- 이 챕터의 설계 패턴은 **UE5 렌더링 아키텍처의 기초**
- UE5의 **FShaderParameterBindings**: 시맨틱 기반 자동 파라미터 바인딩의 현대적 구현
- **Material Instance** 시스템: 머티리얼 파라미터의 데이터 드리븐 관리
- **Shader Model 폴백**: UE5의 Feature Level 시스템 (SM5, SM6, ES3.1 등)
- 현대적 발전:
  - **Bindless Resources**로 텍스처 바인딩 오버헤드 제거
  - **GPU-driven rendering**으로 CPU-GPU 통신 최소화
  - **Material Graph**로 시각적 셰이더 프로그래밍

## 핵심 요약 (3줄)
1. 셰이더를 리소스로 취급하고, 시맨틱/어노테이션 기반 데이터 바인딩으로 데이터 드리븐 렌더러를 구축하는 설계 패턴이다.
2. 씬 정보, 머티리얼 파라미터, 텍스처를 체계적으로 셰이더에 전달하는 통신 레이어가 핵심이다.
3. 이 패턴은 UE5를 비롯한 모든 현대 렌더링 엔진의 기본 아키텍처가 됐다.
