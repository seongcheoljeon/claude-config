# Chapter 31: Using FX Composer
> 저자: Christopher Maughan (NVIDIA)

## 핵심 개념
- **해결하려는 문제**: FX Composer의 실제 사용법 가이드 — 셰이더 개발 워크플로우
- .fx 파일은 Direct3D 렌더링 상태, 텍스처, 버텍스/픽셀 셰이더, 파라미터를 포함하는 통합 이펙트 포맷
- 머티리얼 시스템, 씬 그래프, 텍스처 패널, 프로파일링을 활용한 셰이더 개발 실습
- Shader Perf를 통한 하드웨어별 명령어 수 분석
- 렌더 타겟 디버깅 가능 (glow.fx 예제)

## 기술적 세부사항

### 주요 패널 사용법

#### Materials Panel
- .fx 파일을 3D 오브젝트에 적용하여 미리보기
- 드래그 앤 드롭으로 머티리얼을 씬 오브젝트에 적용
- 여러 머티리얼 동시 비교 가능

#### Scene Graph Panel
- 트리 구조로 씬 구성 요소 표시
- 라이트, GeoPipe(지오메트리), 카메라 등 모든 오브젝트 접근
- Properties 패널에서 파라미터 실시간 조정

#### Textures Panel
- 선택된 머티리얼의 모든 텍스처 표시
- 렌더 타겟도 표시 — 이펙트의 중간 결과물 디버깅 가능
- .dds 파일로 텍스처 저장 기능

#### GeoPipe 시스템
- 지오메트리 생성 파이프라인
- 플러그인 체인: Sphere → Subdivide → UVMapper 등
- 커스텀 지오메트리 임포터/프로세서 추가 가능

### Shader Perf (성능 분석)
- 이펙트의 GPU별 명령어 수(instruction count) 분석
- 하드웨어 프로파일별 성능 예측
- 텍스처 로드 없이도 분석 가능

### 프로젝트 워크플로우
1. .fx 파일 작성 (Editor에서 신택스 하이라이팅)
2. Materials Panel에서 결과 확인
3. Render Window에서 씬에 적용
4. Textures Panel에서 중간 텍스처 디버깅
5. Shader Perf에서 성능 분석
6. 반복 수정

## 수식 및 알고리즘
이 챕터는 도구 사용법 중심이므로 수학적 내용보다는 워크플로우에 집중:
```
[FX Composer Workflow]
1. Load/Create .fx file
2. Preview in Materials Panel
3. Apply to scene geometry
4. Debug render targets in Textures Panel
5. Profile with Shader Perf
6. Export .fx for application use
```

## UE5 관점에서의 활용
- FX Composer의 머티리얼 프리뷰 → UE5 **Material Editor Preview** (실시간 3D 프리뷰)
- .fx 파일의 역할 → UE5 **.usf/.ush 셰이더 파일** + 머티리얼 에셋
- Textures Panel의 렌더 타겟 디버깅 → UE5 **Buffer Visualization** (GBuffer 시각화)
- Shader Perf → UE5 **Shader Complexity View**, RenderDoc의 셰이더 명령어 분석
- GeoPipe의 프로시저럴 지오메트리 → UE5 **Procedural Mesh Component**, Geometry Script

## 핵심 요약 (3줄)
1. FX Composer는 .fx 파일 기반 셰이더 개발의 전체 워크플로우를 하나의 IDE에서 지원한다.
2. 렌더 타겟 디버깅과 Shader Perf를 통한 성능 분석이 핵심 기능이다.
3. 현대의 UE5 Material Editor + RenderDoc 조합이 이 도구의 기능을 완전히 대체한다.
