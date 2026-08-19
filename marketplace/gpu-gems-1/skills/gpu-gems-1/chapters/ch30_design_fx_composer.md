# Chapter 30: The Design of FX Composer
> 저자: Christopher Maughan (NVIDIA)

## 핵심 개념
- **해결하려는 문제**: 셰이더(.fx 파일) 개발을 위한 IDE 도구의 설계 철학과 아키텍처
- FX Composer는 Direct3D 이펙트를 개발/디버깅/프로파일링하는 NVIDIA의 셰이더 IDE
- **확장 가능한 엔진** 설계가 핵심 — 미래 API 변경에 대응
- 도구 개발에서는 FPS보다 **기능성과 안정성**이 우선
- 각 패널별 별도 D3D 디바이스 사용으로 유연성 확보

## 기술적 세부사항

### 설계 목표
1. .NET과 유사한 친숙한 IDE 인터페이스
2. 확장 가능한 엔진 아키텍처
3. .fx 파일 생성 및 결과 시각화를 위한 안정적 환경

### 주요 패널 구성
- **Materials Panel**: 여러 .fx 파일을 3D 오브젝트에 렌더링하여 표시
- **Textures Panel**: 렌더 타겟 및 머티리얼 텍스처 표시
- **Editor Window**: 신택스 하이라이팅, undo/redo, 북마크 등
- **Render Window**: 이펙트가 적용된 씬 표시
- **Scene Graph Panel**: 트리 구조로 씬 오브젝트 관리

### 아키텍처 결정
- **패널별 별도 D3D 디바이스**: 리소스 중복이 발생하지만, 각 패널을 독립적으로 풀스크린/세컨드 모니터로 분리 가능
- Reference Rasterizer를 하드웨어 렌더링과 나란히 실행 가능
- **GeoPipe 시스템**: 지오메트리 파이프라인 노드 — 플러그인으로 구, 토러스 등 프리미티브 생성

### 엔진 설계
- 씬 그래프 기반 렌더링
- 디바이스 매니저가 여러 D3D 디바이스 관리
- .fx 파일을 D3DX effects 프레임워크로 로딩
- 공개 인터페이스로 향후 확장 지원

### Semantic/Annotation 시스템
.fx 파일의 파라미터에 시맨틱과 어노테이션을 붙여 IDE가 자동으로 UI를 생성:
```hlsl
float4x4 WorldViewProj : WORLDVIEWPROJECTION;  // 시맨틱: 엔진이 자동 바인딩
float3 LightDir : DIRECTION
<
    string Object = "DirectionalLight";  // 어노테이션: 씬의 라이트와 연결
    string Space = "World";
>;
float Roughness
<
    string UIWidget = "slider";    // UI 힌트: 슬라이더로 표시
    float UIMin = 0.0;
    float UIMax = 1.0;
    float UIStep = 0.01;
>;
```
- 시맨틱 → 엔진이 변환 행렬, 라이트 등을 자동 공급
- 어노테이션 → IDE가 파라미터를 적절한 위젯(슬라이더, 컬러피커 등)으로 표시

### Shader Perf (성능 프로파일링)
- NVIDIA GPU의 명령어 수를 정적 분석 — 실행 전에 병목 예측
- 산술(ALU), 텍스처(TEX), 보간(INTERP) 명령어 카운트 분리 표시
- 다양한 GPU 타겟(NV30, NV40 등)별로 추정 사이클 수 비교
- 현대적 후계: **NSight Graphics**의 Shader Profiler, **RenderDoc**의 Pipeline State 뷰어

### 편집→컴파일→프리뷰 사이클
1. Editor에서 .fx 코드 수정
2. Ctrl+Enter로 즉시 컴파일
3. 컴파일 에러 시 에러 패널에 라인 번호와 메시지 표시
4. 성공 시 Materials/Render 패널이 자동 갱신 — **1초 이내 피드백**
5. 이 빠른 이터레이션이 FX Composer의 핵심 가치

## 수식 및 알고리즘
이 챕터는 수학적 알고리즘보다 **소프트웨어 아키텍처** 중심:
```
[FX Composer Architecture]
├── IDE Shell (VS.NET-like docking panels)
├── Engine
│   ├── Device Manager (multiple D3D devices)
│   ├── Scene Graph (hierarchical objects)
│   ├── GeoPipe (geometry pipeline plugins)
│   └── Effect System (.fx file loading/rendering)
├── Editor (syntax highlighting, Cg/HLSL)
├── Shader Perf (instruction count analysis)
└── Plugin System (extensibility)
```

## UE5 관점에서의 활용
- FX Composer의 역할은 현대에서 **UE5 Material Editor**가 계승 — 노드 기반 비주얼 셰이더 편집
- UE5의 머티리얼 시스템도 .fx처럼 **데이터 드리븐** 접근 — 머티리얼 인스턴스, 파라미터 노출
- **RenderDoc, Nsight Graphics**가 셰이더 디버깅/프로파일링 도구로 FX Composer의 Shader Perf를 대체
- 패널별 독립 디바이스 개념은 현대 IDE에서 뷰포트별 독립 렌더링으로 계승
- 현대적 대안: HLSL/GLSL 실시간 편집은 **ShaderToy**, **MaterialX** 등으로도 가능

## 핵심 요약 (3줄)
1. FX Composer는 .fx 기반 셰이더 개발을 위한 IDE로, 확장성과 안정성을 최우선으로 설계됐다.
2. 패널별 별도 D3D 디바이스라는 과감한 설계로 유연성을 확보했다.
3. 현대에는 UE5 Material Editor, RenderDoc 등이 이 도구의 역할을 물려받았다.
