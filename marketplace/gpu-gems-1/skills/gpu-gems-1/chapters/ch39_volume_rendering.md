# Chapter 39: Volume Rendering Techniques
> 저자: Milan Ikits, Joe Kniss (University of Utah), Aaron Lefohn (UC Davis), Charles Hansen (University of Utah)

## 핵심 개념
- **해결하려는 문제**: 3D 볼륨 데이터셋(의료 영상, 유체 시뮬레이션 등)을 GPU 텍스처 기반으로 실시간 렌더링
- **텍스처 기반 볼륨 렌더링**: 3D 텍스처 + 프록시 지오메트리(뷰 정렬 평면)로 볼륨 샘플링
- Transfer Function으로 스칼라 데이터를 색상/불투명도에 매핑
- Pre-integrated Volume Rendering으로 품질 향상
- 2D 텍스처 스택과 3D 텍스처 방식 비교

## 기술적 세부사항

### 볼륨 렌더링 기본 원리

#### Volume Rendering Integral
빛이 볼륨을 통과하며 방출·흡수되는 과정:
$$I(D) = I_0 \cdot T(D) + \int_0^D q(s) \cdot T(s) \, ds$$
- $T(s) = e^{-\int_0^s \kappa(t) dt}$: 투과율 (transparency)
- $q(s)$: 위치 $s$에서의 방출(emission)
- $\kappa(s)$: 흡수 계수 (extinction coefficient)

#### 이산화 — Compositing
연속 적분을 이산 슬라이스로 근사:

**Back-to-Front (Over 연산자)**:
$$C_{out} = C_i + (1 - \alpha_i) \cdot C_{acc}$$

**Front-to-Back (Under 연산자)**:
$$C_{acc} = C_{acc} + (1 - \alpha_{acc}) \cdot C_i$$
$$\alpha_{acc} = \alpha_{acc} + (1 - \alpha_{acc}) \cdot \alpha_i$$

→ 하드웨어 알파 블렌딩으로 직접 구현 가능

### Transfer Function
- 스칼라 데이터 값 → RGBA 색상/불투명도 변환
- 1D 텍스처로 구현 (dependent texture lookup)
- 분류(classification) 단계라고도 함

### 프록시 지오메트리 방식

#### 2D 텍스처 스택
- 축 정렬(axis-aligned) 슬라이스 스택 3세트 (X, Y, Z)
- 시점에 가장 가까운 축의 스택 선택
- 장점: 단순, 2D 텍스처로 충분
- 단점: 축 전환 시 팝핑 아티팩트

#### 3D 텍스처 + 뷰 정렬 평면
- 뷰 방향에 수직인 평면으로 바운딩 박스를 슬라이싱
- 각 슬라이스가 3D 텍스처에서 보간된 값 샘플링
- 장점: 어떤 시점에서도 균일한 품질
- 단점: 3D 텍스처 지원 필요, 메모리 사용량 큼

### Pre-Integrated Volume Rendering
- 인접 슬라이스 사이의 값 변화를 미리 적분
- 2D 룩업 테이블: (앞 슬라이스 값, 뒤 슬라이스 값) → 통합 색상
- 적은 슬라이스로도 고품질 — 슬라이싱 아티팩트 감소

### 구현 세부사항

#### 뷰 정렬 슬라이싱 알고리즘
```
1. 바운딩 박스 8개 꼭짓점을 뷰 공간으로 변환
2. 뷰 방향을 따라 최소/최대 깊이 계산
3. 등간격으로 슬라이스 평면 생성
4. 각 평면과 바운딩 박스의 교차 다각형 계산
5. 다각형을 삼각형으로 테셀레이션
6. 3D 텍스처 좌표 할당
7. back-to-front 또는 front-to-back 순서로 렌더링
```

#### 알파 블렌딩 설정
- Over (back-to-front): srcBlend=1, dstBlend=1-srcAlpha
- Under (front-to-back): srcBlend=1-dstAlpha, dstBlend=1

## 수식 및 알고리즘

### Pre-integrated 룩업 테이블
두 인접 샘플 $s_f$(앞)와 $s_b$(뒤) 사이의 적분된 색상:
$$C_{pre}(s_f, s_b) = \int_0^1 c(s_f + t(s_b - s_f)) \cdot T(t) \, dt$$

이를 2D 텍스처로 미리 계산하여 저장.

## UE5 관점에서의 활용
- UE5의 **Volumetric Fog/Cloud** 시스템이 볼륨 렌더링의 현대적 구현
- **Ray Marching** 기반 볼륨 렌더링이 이 챕터의 슬라이싱 방식을 대체
- UE5 **Heterogeneous Volumes** (5.4+): OpenVDB 볼륨 데이터 실시간 렌더링
- Transfer Function 개념 → UE5 **Volume Material**의 Density/Color 커브
- 현대적 대안:
  - **Ray Marching in Compute Shader**: 프록시 지오메트리 불필요
  - **Neural Radiance Fields (NeRF)**: 학습 기반 볼륨 렌더링
  - **Sparse Voxel Octree**: 메모리 효율적 볼륨 저장
- Pre-integrated 개념은 UE5 Volumetric Fog의 temporal integration과 유사

## 핵심 요약 (3줄)
1. 텍스처 기반 볼륨 렌더링은 3D 텍스처 + 뷰 정렬 프록시 평면으로 볼륨을 슬라이싱하고, 알파 블렌딩으로 합성한다.
2. Transfer Function이 스칼라→색상 매핑을, Pre-integrated 테이블이 적은 슬라이스로 고품질을 보장한다.
3. 현대에는 Ray Marching이 주류이지만, 기본 원리(샘플링, 합성, transfer function)는 동일하다.
