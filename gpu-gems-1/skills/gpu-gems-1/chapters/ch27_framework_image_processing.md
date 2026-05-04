# Chapter 27: A Framework for Image Processing
> 저자: Frank Jargstorff, NVIDIA

## 핵심 개념
- **해결하려는 문제**: OpenGL/DirectX 같은 저수준 3D API는 원래 3D 앱용으로 설계되어, GPU 기반 이미지 처리를 직접 구현하기 번거롭다. 이미지 처리에 특화된 추상 계층(프레임워크)을 만드는 것
- **핵심 아이디어**:
  1. **필터 그래프 모델**: Source(생산) → Filter(변환) → Sink(소비) 연산자의 DAG(방향 비순환 그래프)
  2. **Pull 기반 데이터 흐름**: 결과 노드에서 데이터를 "끌어당기는" 방식. MVC 패턴과 잘 맞음
  3. **참조 카운팅 메모리 관리**: Image 클래스가 GPU 버퍼(Buffer)의 핸들(프록시 패턴)로 동작
  4. **Dirty 플래그 메커니즘**: 업스트림 변경 시 재계산 필요 여부를 재귀적으로 확인
  5. **Pbuffer 기반 렌더 투 텍스처**: GPU에 데이터를 유지하며 파이프라인 전체를 GPU에서 처리

## 기술적 세부사항

### 아키텍처 패턴

**세 가지 연산자 유형:**
- **Source Operator**: 입력 없이 출력 생성 (이미지 로더)
- **Sink Operator**: 입력 소비, 출력 없음 (디스플레이)
- **Filter Operator**: 입력 소비 + 출력 생성 (가우시안 블러, 색 변환 등)

**클래스 계층:**
```
SourceOperator (추상)
  ├─ ImageFilter
  └─ LoadOperator

SinkOperator (추상)
  ├─ ImageFilter
  └─ ImageView

ImageFilter (다중 상속)
  ├─ GaussFilter
  ├─ NightFilter
  └─ ScotopicFilter
```

### 핵심 인터페이스

**SourceOperator:**
```cpp
class SourceOperator {
  virtual bool dirty() = 0;    // 재계산 필요?
  virtual Image image() = 0;   // 결과 이미지 반환
};
```

**SinkOperator:**
```cpp
class SinkOperator {
  virtual void setSourceOperator(SourceOperator *pSrc);
protected:
  SourceOperator *_pSourceOperator;
};
```

**ImageFilter (SourceOperator + SinkOperator 다중 상속):**
```cpp
class ImageFilter : public SourceOperator, public SinkOperator {
  virtual Image image();        // 필터 적용 후 결과 반환
  virtual bool dirty();          // 업스트림 dirty 재귀 확인
protected:
  virtual void setCgParameters() = 0;       // 셰이더 파라미터 설정
  virtual CGprogram cgFragmentProgram() = 0; // 프래그먼트 프로그램 반환
};
```

### 처리 파이프라인

**Image::image() 호출 시:**
1. 출력 이미지 생성
2. 소스 연산자에서 입력 이미지 획득 (pull)
3. 출력 크기를 입력에 맞춤
4. 뷰포트 설정 + 직교 프로젝션 구성
5. 버텍스/프래그먼트 프로그램 로드
6. 입력 이미지를 텍스처로 바인딩
7. 화면 정렬 쿼드 렌더링 → 프래그먼트 프로그램이 픽셀 변환
8. 결과를 pbuffer에 저장, 이후 필터의 텍스처로 바인딩

### Dirty 플래그
```
ImageFilter::dirty():
  모든 업스트림 연산자의 dirty() 재귀 호출
  하나라도 dirty면 true 반환
  → 불필요한 재계산 방지
```

### Pbuffer 렌더링 컨텍스트 전환
```cpp
void Buffer::renderBegin() {
  glBindTexture(GL_TEXTURE_RECTANGLE_NV, _hTexture);
  wglReleaseTexImageARB(_hPBuffer, WGL_FRONT_LEFT_ARB);
  wglMakeCurrent(_hDC, _hRenderContext);
}

void Buffer::renderEnd() {
  glBindTexture(GL_TEXTURE_RECTANGLE_NV, _hTexture);
  wglBindTexImageARB(_hPBuffer, WGL_FRONT_LEFT_ARB);
  wglMakeCurrent(_hOldDC, _hOldRenderContext);
}
```

### 가우시안 블러 프래그먼트 셰이더 (Cg)
```cg
void gauss(in float2 vUV : TEXCOORD0,
           out half4 vOut : COLOR,
           const uniform samplerRECT oImage,
           const uniform half aKernel[49])   // 7×7 = 49
{
  half4 vSum = half4(0, 0, 0, 0);
  int k = 0;
  for (int i = -3; i <= 3; i++)
    for (int j = -3; j <= 3; j++) {
      vSum += texRECT(oImage, vUV + half2(i, j)) * aKernel[k];
      k++;
    }
  vOut = vSum;
}
```
- RAD = 3, 커널 크기 7×7 = 49 요소
- σ(시그마): 가우시안 중심에서 50% 감소 지점까지의 거리

### 스코토픽 시각 필터 (복합 예제)
3단계 필터 체인:
1. **색 변환**: 블루 톤으로 변환 (야간 시각)
2. **가우시안 블러**: 해상도 저하 시뮬레이션
3. **에지 샤프닝**: 선명도 보정

→ 복합 필터를 단일 노드로 캡슐화 가능

### 필요한 OpenGL 확장
- `WGL_ARB_pbuffer`: 픽셀 버퍼 생성
- `WGL_ARB_render_texture`: 렌더 투 텍스처
- `WGL_ARB_pixel_format`: 부동소수점 텍스처 포맷
- `NV_texture_rectangle`: 비 2의 거듭제곱 텍스처

### 데이터 타입
Half (16비트 IEEE 부동소수점):
- 속도/정확도 트레이드오프 최적
- 메모리 풋프린트 작음
- OpenEXR 포맷과 네이티브 호환

## 수식 및 알고리즘

### 가우시안 커널
$$G(x, y) = \frac{1}{2\pi\sigma^2} e^{-\frac{x^2+y^2}{2\sigma^2}}$$
- 커널 크기 7×7 (49 요소)로 제한
- σ: 표준 편차

### 컨볼루션
$$I_{out}(x,y) = \sum_{i=-R}^{R} \sum_{j=-R}^{R} I_{in}(x+i, y+j) \cdot K(i,j)$$
- R = 3 (반경)
- K: 커널 가중치

### Pull 기반 평가
```
Sink.display() → Sink.update() → Source.image()
  → Filter.image() → 업스트림 Filter.image() → ... → LoadOperator.image()
```

## UE5 관점에서의 활용

- **UE5 Post Process Chain**: 이 챕터의 필터 그래프 모델이 UE5의 Post Process 체인과 동일한 개념. 각 Post Process 이펙트가 Filter에 해당
- **Render Target 체인**: pbuffer 기반 렌더 투 텍스처 → UE5에서는 FRDGBuilder (Render Dependency Graph)로 발전. 리소스 수명과 의존성을 자동 관리
- **Dirty 플래그 → RDG Dependency**: UE5의 RDG가 패스 간 의존성을 추적하여 불필요한 패스를 자동 제거 — dirty 플래그의 대규모 버전
- **Compute Shader**: 이 챕터의 "풀스크린 쿼드 + 프래그먼트 셰이더" 패턴은 UE5에서 Compute Shader 디스패치로 대체됨. 더 유연하고 효율적
- **현대적 대안**:
  - **FRDGBuilder**: UE5의 렌더 그래프. 이 챕터의 프레임워크를 대규모로 확장한 것
  - **Compute Shader 기반 포스트 프로세스**: 풀스크린 쿼드 대신 cs 디스패치
  - **Vulkan/DX12**: pbuffer/wglMakeCurrent 대신 커맨드 버퍼 + 베리어 + 이미지 레이아웃 전환
- **프레임워크 설계 패턴**: Source/Filter/Sink 패턴은 노드 기반 합성 도구(Nuke, Fusion)와 UE5 Material Editor의 노드 그래프와 동일한 패러다임

## 핵심 요약 (3줄)
- GPU 이미지 처리를 Source→Filter→Sink 연산자의 필터 그래프로 추상화하고, pull 기반 평가 + dirty 플래그로 효율적인 파이프라인을 구현한다
- pbuffer 렌더 투 텍스처로 데이터를 GPU에 유지하며, 가우시안 블러 같은 필터를 프래그먼트 셰이더 + 풀스크린 쿼드로 처리한다
- 이 필터 그래프 아키텍처는 UE5의 Render Dependency Graph(RDG), Post Process Chain, 그리고 노드 기반 합성 도구의 직접적 선조이다
