# Chapter 40: Applying Real-Time Shading to 3D Ultrasound Visualization
> 저자: Thilaka Sumanaweera (Siemens Medical Solutions USA, Inc.)

## 핵심 개념
- **해결하려는 문제**: 비카르테시안(non-Cartesian) 그리드로 획득되는 3D 초음파 데이터를 GPU로 실시간 볼륨 렌더링
- CT/MRI와 달리 초음파 데이터는 **음향 그리드(acoustic grid)**에서 획득 — 피라미드/원뿔형 스캔 패턴
- **3D 프로젝티브 텍스처 매핑**을 활용한 scan conversion 없는 직접 볼륨 렌더링
- 4D 볼륨(3D + 시간) 실시간 시각화로 심장 기능, 태아 이상 진단 지원
- 프로그래머블 GPU의 vertex/fragment 프로세서 활용

## 기술적 세부사항

### 초음파 데이터의 특수성
| 특성 | CT/MRI | 초음파 |
|------|--------|-------|
| 그리드 | 카르테시안 (직교) | 비카르테시안 (음향) |
| 스캔 패턴 | 균일 격자 | 피라미드/원뿔형 빔 |
| 복셀 형태 | 정육면체 | 절두체(frustum) 형태 |
| 시간 해상도 | 느림 | 빠름 (실시간 4D 가능) |

### 기존 접근: Scan Conversion
1. 비카르테시안 데이터를 카르테시안 그리드로 리샘플링
2. 리샘플링된 3D 텍스처를 표준 볼륨 렌더링으로 시각화
- 단점: 리샘플링에 시간/메모리 소모, 품질 저하

### 제안 방법: 프로젝티브 텍스처 매핑
- Scan conversion 없이 원본 음향 그리드에서 직접 렌더링
- **핵심 아이디어**: 초음파 트랜스듀서의 빔 기하학이 프로젝티브 변환으로 모델링 가능
- 3D 프로젝티브 텍스처 좌표를 사용하여 음향 공간 ↔ 카르테시안 공간 매핑

### GPU 구현
1. **Vertex Shader**: 프록시 지오메트리(뷰 정렬 슬라이스)의 좌표를 프로젝티브 텍스처 좌표로 변환
2. **Fragment Shader**: 프로젝티브 텍스처 좌표로 초음파 볼륨 샘플링, Transfer Function 적용
3. **알파 블렌딩**: 슬라이스를 back-to-front 합성

### 워크플로우
```
1. 초음파 스캐너에서 3D 음향 데이터 획득
2. 데이터를 3D 텍스처로 업로드 (음향 그리드 그대로)
3. 뷰 정렬 프록시 슬라이스 생성
4. Vertex shader: 프로젝티브 텍스처 좌표 계산
5. Fragment shader: 텍스처 룩업 + Transfer Function
6. 알파 블렌딩으로 합성
7. 다음 시간 프레임 반복 (4D)
```

## 수식 및 알고리즘

### 프로젝티브 텍스처 매핑
카르테시안 좌표 $(x, y, z)$에서 음향 좌표 $(r, \theta, \phi)$로의 변환:
$$r = \sqrt{x^2 + y^2 + z^2}$$
$$\theta = \arctan\frac{x}{z}$$
$$\phi = \arctan\frac{y}{z}$$

이를 4×4 프로젝티브 변환 행렬로 근사하여 vertex shader에서 효율적으로 계산.

### 볼륨 렌더링 합성
Ch39와 동일한 Over/Under 연산자 사용:
$$C_{acc} = C_{acc} + (1 - \alpha_{acc}) \cdot C_i \cdot \alpha_i$$

## UE5 관점에서의 활용
- UE5의 **볼륨 렌더링**은 균일(카르테시안) 그리드 기반이 대부분
- 비카르테시안 데이터 처리는 **커스텀 셰이더**로 구현 필요 — 이 챕터의 프로젝티브 매핑이 참고 가능
- **Medical Imaging** 분야에서 UE5를 활용한 시각화 프로젝트 증가 (DICOM 뷰어 등)
- 현대적 대안:
  - **Compute Shader 기반 Ray Marching**: scan conversion 없이 직접 비카르테시안 볼륨 렌더링
  - **VTK (Visualization Toolkit)** + UE5 통합
  - **NVIDIA Clara/Holoscan**: 의료 영상 전용 GPU 플랫폼
- 4D 시각화는 **시간축 애니메이션 + 스트리밍**으로 현대에도 동일한 패러다임

## 핵심 요약 (3줄)
1. 초음파 데이터는 비카르테시안 그리드라서 일반 볼륨 렌더링을 직접 적용할 수 없고, 프로젝티브 텍스처 매핑으로 해결한다.
2. Scan conversion(리샘플링) 없이 원본 음향 그리드에서 직접 렌더링하여 품질과 성능을 동시에 확보한다.
3. 현대에는 Compute Shader Ray Marching이 더 유연하지만, 프로젝티브 매핑 아이디어는 특수 좌표계 데이터에 여전히 유효하다.
