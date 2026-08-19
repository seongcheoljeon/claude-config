# Chapter 41: Real-Time Stereograms
> 저자: Fabio Policarpo (Paralelo Computação Ltda.)

## 핵심 개념
- **해결하려는 문제**: GPU를 활용하여 실시간으로 스테레오그램(3D 숨은 그림)을 생성하는 기법
- 스테레오그램은 2D 이미지에 스테레오 정보를 인코딩하여 숨겨진 3D 씬을 드러내는 이미지
- Bela Julesz(1960년대)의 Random-Dot Stereogram(RDS)에서 시작
- **SIRDS** (Single-Image Random-Dot Stereogram)를 픽셀 셰이더로 실시간 생성
- 뎁스 맵 + 타일 패턴 → 스테레오그램 변환을 GPU에서 수행

## 기술적 세부사항

### 스테레오 비전 기본 원리
- 인간의 두 눈은 약 65mm 간격 → 양안시차(binocular disparity)
- 좌/우 눈에 약간 다른 이미지가 제시되면 뇌가 깊이를 인식
- 스테레오그램: 하나의 이미지에 이 시차 정보를 패턴 변형으로 인코딩

### 스테레오그램의 역사적 발전
1. **스테레오 사진 (1838~)**: 두 장의 사진을 렌즈로 각 눈에 제시
2. **Random-Dot Stereogram (1960s)**: 랜덤 도트 이미지의 영역을 수평 이동하여 깊이 인코딩
3. **Autostereogram**: 단일 이미지에서 반복 패턴의 간격 변화로 깊이 표현
4. **Single-Image Stereogram (SIS)**: 뎁스 맵 기반으로 타일 패턴을 변형

### SIS 생성 알고리즘
입력: 뎁스 맵(회색조) + 타일 패턴(컬러)
출력: 스테레오그램 이미지

```
for each pixel (x, y):
    depth = depthMap[x][y]
    separation = baseSeparation * (1 - depth * depthFactor)
    
    // 좌측 타일 경계에서의 오프셋 계산
    tileX = x mod tileWidth
    offset = tileX + depth * maxShift
    
    // 타일 패턴에서 변형된 좌표로 샘플링
    color = tilePattern[offset mod tileWidth][y mod tileHeight]
    output[x][y] = color
```

핵심: 깊이에 따라 반복 패턴의 **수평 간격**이 변화 → 두 눈이 서로 다른 간격을 인식 → 깊이 지각

### GPU 구현 (픽셀 셰이더)
- 뎁스 맵: 씬을 렌더링하여 뎁스 버퍼를 텍스처로 캡처
- 타일 패턴: 반복 텍스처
- 프래그먼트 셰이더에서:
  1. 현재 픽셀의 뎁스 값 읽기
  2. 뎁스에 따라 텍스처 좌표 오프셋 계산
  3. 변형된 좌표로 타일 패턴 샘플링
  4. 출력

### 실시간 파이프라인
```
Pass 1: 씬을 뎁스 맵으로 렌더링 (렌더 타겟)
Pass 2: 풀스크린 쿼드에 스테레오그램 셰이더 적용
        - 뎁스 텍스처 + 타일 텍스처 입력
        - 뎁스 기반 텍스처 좌표 변형
        - 스테레오그램 출력
```

## 수식 및 알고리즘

### 수평 분리(separation) 계산
$$s(d) = s_{base} \cdot (1 - d \cdot f)$$
- $s(d)$: 깊이 $d$에서의 패턴 반복 간격
- $s_{base}$: 기본 반복 간격 (눈 간격에 비례)
- $f$: 깊이 스케일 팩터

### 텍스처 좌표 변형
$$u' = u + d(x,y) \cdot \Delta u$$
여기서 $d(x,y)$는 정규화된 뎁스 값, $\Delta u$는 최대 변위.

## UE5 관점에서의 활용
- 스테레오그램 자체는 현대 게임에서 사용되지 않지만, 기술적 원리는 관련 분야에 적용:
  - **VR/AR 스테레오 렌더링**: 양안시차 원리 동일
  - **Lenticular Display**: 하드웨어 기반 3D 디스플레이
  - **Depth-of-Field**: 뎁스 맵 기반 후처리 효과
- UE5에서 구현한다면:
  - **Post-Process Material**로 뎁스 버퍼 접근
  - SceneTexture:SceneDepth 노드로 뎁스 읽기
  - Custom HLSL 노드로 패턴 변형 계산
- 뎁스 맵 기반 이미지 효과의 일반적 패턴 (DOF, 모션 블러 등과 동일 구조)

## 핵심 요약 (3줄)
1. 스테레오그램은 깊이에 따른 반복 패턴의 수평 간격 변화로 3D를 인코딩하며, GPU 픽셀 셰이더로 실시간 생성 가능하다.
2. 씬 뎁스맵 렌더링 → 뎁스 기반 텍스처 좌표 변형이라는 2패스 파이프라인으로 구현한다.
3. 직접적 사용은 드물지만, 뎁스 맵 기반 이미지 효과(DOF, VR 스테레오)의 기본 원리와 동일하다.
