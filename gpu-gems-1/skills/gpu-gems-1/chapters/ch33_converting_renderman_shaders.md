# Chapter 33: Converting Production RenderMan Shaders to Real-Time
> 저자: Stephen Marshall (Sony Pictures Imageworks)

## 핵심 개념
- **해결하려는 문제**: 영화 제작용 RenderMan 셰이더를 실시간 GPU 셰이더(Cg)로 변환하는 방법론
- Stuart Little 영화의 **fur(털) 셰이더**를 변환 예제로 사용
- 오프라인 렌더링(시간당 프레임)과 실시간 렌더링의 간극을 줄이는 것이 목표
- 주파수(frequency) 분석을 통해 vertex vs fragment shader 배치 최적화
- 영화 VFX 워크플로우에서 실시간 프리뷰의 가치

## 기술적 세부사항

### RenderMan → Cg 변환의 핵심 이슈

#### 1. 다중 광원 처리
- RenderMan: `illuminance` 루프로 모든 광원을 자연스럽게 순회
- Cg/HLSL: 멀티패스로 처리하거나, 셰이더 내에서 루프 — 하드웨어 제약 존재
- 해결: 광원 수에 맞는 셰이더 변형 생성 또는 멀티패스 렌더링

#### 2. Vertex vs Fragment Frequency 분석
- RenderMan은 모든 계산이 per-pixel
- GPU에서는 per-vertex로 옮길 수 있는 계산을 식별해야 함
  - 위치 의존적이지만 저주파(low-frequency) → vertex shader
  - 고주파 디테일(노말맵, 스페큘러) → fragment shader
- vertex shader로 옮기면 계산량 대폭 감소 (vertex 수 << pixel 수)

#### 3. 하드웨어 프로파일별 최적화
- 명령어 수 제한이 있으므로, 프로파일에 맞게 셰이더 복잡도 조절
- half/fixed 정밀도 활용으로 명령어 수 절약
- 텍스처 룩업으로 복잡한 수학 함수 대체

### Stuart Little Fur Shader 변환
- 원본: RenderMan SL로 작성된 복잡한 털 셰이더
- 주요 구성 요소:
  - Diffuse 라이팅 (Kajiya-Kay 모델 기반)
  - Specular 하이라이트
  - Self-shadowing (털 내부 그림자)
  - Ambient occlusion
- Cg 변환 시 일부 기능 단순화 필요

### 결과 비교
- 실시간 버전은 원본 대비 시각적 품질이 다소 떨어지지만, 아티스트 이터레이션 속도 대폭 향상
- 프리뷰 용도로는 충분한 품질

## 수식 및 알고리즘
```
// RenderMan → Real-Time 변환 워크플로우
1. RenderMan 셰이더 분석
   - 입력 변수, 출력 변수 식별
   - 광원 루프 구조 파악
2. 주파수 분석
   - 각 계산의 공간적 변화율 평가
   - Low-freq → vertex shader
   - High-freq → fragment shader
3. 하드웨어 제약 확인
   - 타겟 프로파일의 명령어 수 제한
   - 텍스처 유닛 수
4. Cg 코드 작성 및 최적화
   - 정밀도 최적화 (float → half)
   - 텍스처 룩업 활용
   - 멀티패스 분리 (필요 시)
5. 결과 비교 및 반복
```

## UE5 관점에서의 활용
- 이 챕터의 핵심 문제(오프라인↔실시간 간극)는 **Path Tracing in UE5**로 크게 좁혀짐
- UE5의 **Lumen**은 실시간으로 GI를 계산하여 오프라인 렌더러에 근접한 품질 달성
- **Film/Virtual Production** 워크플로우에서 실시간 프리뷰는 이제 표준
- 현대적 대안: USD/MaterialX 기반의 **universal shader** 포맷이 렌더러간 셰이더 변환 문제를 해결 중
- UE5의 **Substrate** 머티리얼 모델은 오프라인 렌더러의 복잡한 BSDF를 실시간으로 구현

## 핵심 요약 (3줄)
1. RenderMan→Cg 변환의 핵심은 주파수 분석으로 vertex/fragment shader에 적절히 계산을 분배하는 것이다.
2. Stuart Little fur 셰이더 사례로 영화급 셰이더의 실시간 변환이 가능하지만 품질 타협이 필요했다.
3. 현대에는 Path Tracing, Lumen, MaterialX 등으로 오프라인/실시간 간극이 크게 좁혀졌다.
