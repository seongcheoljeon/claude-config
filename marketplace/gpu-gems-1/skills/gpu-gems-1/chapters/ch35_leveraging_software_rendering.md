# Chapter 35: Leveraging High-Quality Software Rendering Effects in Real-Time Applications
> 저자: Alexandre Jean Claude, Marc Stevens (Softimage)

## 핵심 개념
- **해결하려는 문제**: 고품질 오프라인 렌더러(mental ray 등)의 결과물을 실시간 셰이딩의 입력 데이터로 활용
- DCC 툴 내에서 통합 워크플로우 구축 — 별도 독립 프로그램으로 내보내지 않음
- **Render-to-Texture**: 소프트웨어 렌더러의 셰이딩 결과를 텍스처 맵으로 베이킹
- **Render-to-Vertices**: 버텍스 속성으로 베이킹
- 노멀맵, 탄젠트맵, 커스텀 속성맵을 mental ray로 생성하여 실시간 셰이더에 공급

## 기술적 세부사항

### 통합 워크플로우의 필요성
- 기존 문제: DCC → 독립 도구 → 실시간 엔진 파이프라인에서 데이터 손실 발생
- 해결: DCC 안에서 직접 고품질 속성맵 생성
- mental ray의 풍부한 렌더링 기능을 그대로 활용

### Render-to-Texture (RTT) 프로세스
1. 타겟 오브젝트의 UV 파라미터화(parameterization) 사용
2. 각 텍셀에 대해 오브젝트 표면의 3D 좌표 계산
3. mental ray가 해당 좌표에서 레이를 쏘고 속성 샘플링
4. 결과를 텍스처 맵으로 저장

### 커스텀 속성맵 생성
- 표면 노멀 → 노멀맵: 노멀 벡터를 RGBA 컬러로 인코딩
- 탄젠트 → 탄젠트맵: 동일 방식
- AO (Ambient Occlusion) → AO맵: mental ray의 GI 기능 활용
- 사실상 **4채널 레지스터에 들어가는 모든 데이터**를 텍스처로 베이킹 가능

### Render-to-Vertices
- 텍셀 대신 각 버텍스 위치에서 속성 샘플링
- 버텍스 컬러나 커스텀 버텍스 속성으로 저장
- 해상도는 낮지만 텍스처 메모리 불필요

### 하이폴리 → 로우폴리 전환
- 하이폴리 모델에서 mental ray로 디테일을 노멀맵으로 베이킹
- 로우폴리 모델에 적용하여 실시간 렌더링
- 통합 환경에서 결과를 즉시 확인 가능

### UV 파라미터화 문제와 해결
- **UV 이음새(seam)**: UV 경계에서 텍셀 누락 → 검은 선이 나타남
  - 해결: 이음새 주변 텍셀을 확장(dilate)하여 패딩 추가
  - 필터링 시 이웃 텍셀이 빈 공간을 샘플링하지 않도록 방지
- **UV 왜곡(distortion)**: 3D 표면 → 2D 전개 시 면적/각도 왜곡 발생
  - 왜곡이 큰 영역은 텍셀 밀도가 불균일 → 품질 저하
  - 해결: 균일한 텍셀 밀도를 위한 UV 최적화 (LSCM, ABF++ 등)
- **해상도 선택 기준**: 최종 렌더링에서 화면 1픽셀당 텍셀 1개 이상 → 오브젝트 크기와 카메라 거리 고려

### mental ray 커스텀 셰이더 작성
```c
// 노멀맵 출력을 위한 mental ray 셰이더 예시
miBoolean normal_output(miColor *result, miState *state, ...) {
    // 월드 스페이스 노멀을 [0,1] 범위로 인코딩
    result->r = state->normal.x * 0.5f + 0.5f;
    result->g = state->normal.y * 0.5f + 0.5f;
    result->b = state->normal.z * 0.5f + 0.5f;
    result->a = 1.0f;
    return miTRUE;
}
```
- `miState` 구조체에서 교차점의 모든 기하학적 속성에 접근 가능
- 노멀, 탄젠트, 곡률, AO 등 원하는 속성을 RGBA로 자유롭게 인코딩
- GI, 글로벌 일루미네이션 결과도 동일 방식으로 베이킹 가능

## 수식 및 알고리즘
```
// Render-to-Texture 워크플로우
for each texel (u, v) in target_texture:
    P = SurfacePosition(object, u, v)      // UV → 3D 좌표
    attr = MentalRay.Sample(P, attribute)   // 속성 샘플링
    texture[u][v] = EncodeAsRGBA(attr)      // RGBA로 인코딩

// 노멀맵 인코딩
normal_color = (normal * 0.5) + 0.5  // [-1,1] → [0,1]
```

## UE5 관점에서의 활용
- 이 챕터의 개념은 현대 게임 개발의 **핵심 파이프라인**이 됨
- UE5의 텍스처 베이킹: **High → Low poly 노멀맵 베이킹**은 모든 AAA 게임에서 사용
- **Substance Designer/Painter**가 이 워크플로우를 전문화한 도구
- UE5의 **Lightmass**는 GI를 라이트맵으로 베이킹하는 동일 개념
- 현대적 대안: **Lumen**이 런타임 GI를 제공하여 일부 베이킹 필요성 제거
- **Virtual Shadow Maps**도 런타임 계산으로 섀도우 베이킹을 대체

## 핵심 요약 (3줄)
1. 고품질 소프트웨어 렌더러(mental ray)의 결과를 텍스처/버텍스로 베이킹하여 실시간 셰이딩에 활용하는 파이프라인이다.
2. 커스텀 소프트웨어 셰이더로 노멀, 탄젠트, AO 등 모든 속성을 RGBA로 인코딩할 수 있다.
3. 이 개념은 현대 게임 개발의 표준 파이프라인(노멀맵 베이킹, 라이트맵 등)의 기초가 됐다.
