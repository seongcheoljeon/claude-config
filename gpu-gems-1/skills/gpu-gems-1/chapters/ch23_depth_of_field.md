# Chapter 23: Depth of Field: A Survey of Techniques
> 저자: Joe Demers, NVIDIA

## 핵심 개념
- **해결하려는 문제**: 물리적 카메라 렌즈의 피사계 심도(Depth of Field) 효과를 실시간 CG에서 시뮬레이션하는 것. 초점 범위 내 물체는 선명하고, 앞뒤 물체는 점진적으로 흐려지는 효과
- **핵심 아이디어**:
  1. **Circle of Confusion (CoC)**: 초점 벗어난 빛이 필름/스크린에서 맺히는 원의 직경. 렌즈 크기와 초점면 거리에 비례
  2. **5가지 기법 서베이**: Ray-Traced, Accumulation Buffer, Layered, Forward-Mapped Z-Buffer, Reverse-Mapped Z-Buffer
  3. **Z-Buffer 기반 CoC 선형화**: z-버퍼 값에서 `CoC = |z × CoCScale + CoCBias|`로 효율적 계산
  4. **Reverse-Mapped Z-Buffer**: 가장 실시간에 적합. 렌더된 씬을 z-값에 따라 가변적으로 블러
  5. **아티팩트와 트레이드오프**: 깊이 불연속, 바이리니어 보간, 픽셀 블리딩 등의 문제와 해결책

## 기술적 세부사항

### Circle of Confusion (CoC) 계산

**월드 공간 공식:**
```
CoC = abs(aperture * (focalLength * (objectDist - planeInFocus)) /
      (objectDist * (planeInFocus - focalLength)))
```

**Z-Buffer에서 오브젝트 거리 역산:**
```
objectDist = -zfar * znear / (z * (zfar - znear) - zfar)
```

**Z-Buffer 값으로 직접 CoC 계산 (최적화):**
$$\text{CoC} = |z \times \text{CoCScale} + \text{CoCBias}|$$

```
CoCScale = (aperture * focalLength * planeInFocus * (zfar - znear)) /
           ((planeInFocus - focalLength) * znear * zfar)

CoCBias = (aperture * focalLength * (znear - planeInFocus)) /
          ((planeInFocus - focalLength) * znear)
```

→ z-버퍼 값에 선형 변환만으로 CoC를 구할 수 있어서 매우 효율적.

### 5가지 기법 비교

| 기법 | 품질 | 속도 | 실시간 가능 | 적합한 용도 |
|------|------|------|-------------|-------------|
| Ray-Traced | 최고 | 최느림 | 아니오 | 오프라인 렌더링 |
| Accumulation Buffer | 정확한 DoF | 느림 | 제한적 | 중간 수준 효과 |
| Layered | 좋음 | 빠름 | 예 | 단순한 씬 |
| Forward-Mapped Z | 좋음 | 느림 | 아니오 | 포스트 프로세싱 |
| Reverse-Mapped Z | 좋음 | 빠름 | **예** | **실시간 게임** |

### Ray-Traced DoF
- 핀홀 모델 대신 렌즈 표면에 레이 분포
- 가장 정확하지만 비실시간
- 샘플 수 줄이면 자연스럽게 노이즈로 퇴화
- 모션 블러, 소프트 섀도우도 자연스럽게 지원

### Accumulation Buffer
- 여러 렌즈 위치에서 씬을 다수 렌더링 후 누적 블렌딩
- CoC 반경 8픽셀이면 ~50패스 필요
- 패스 부족 시 고스팅 아티팩트
- 정확한 DoF 가능하지만 보통 비실시간

### Layered DoF
- 씬을 겹치지 않는 깊이 레이어로 분할
- 레이어별 균일 블러 적용 후 합성
- 한계: 넓은 깊이 범위의 오브젝트가 잘못 표현, 레이어 경계 가시성 오류

### Forward-Mapped Z-Buffer
- 핀홀 렌더링 후 각 소스 픽셀을 CoC 크기의 원으로 목적지에 매핑
- 알파 블렌딩(원 면적에 반비례)
- 정규화 패스 필요
- 하드웨어 매핑이 나쁘고 가시성/셰이딩 아티팩트

### Reverse-Mapped Z-Buffer (가장 실용적)
**밉맵 변형:**
1. 씬 텍스처의 밉맵 생성
2. 각 픽셀의 z-버퍼에서 CoC 계산
3. CoC를 밉맵 레벨 선택에 사용 (tex2D 미분값으로)
4. 하드웨어가 적절한 밉 레벨 선택

**멀티 텍스처 변형:**
1. 원본, 1/4, 1/16 크기 텍스처 3개 준비
2. z-값에 따라 세 텍스처 간 블렌딩
3. 하드웨어 2×2 밉맵보다 좋은 다운샘플링 필터 사용 가능

### 주요 아티팩트와 해결

| 아티팩트 | 원인 | 해결책 |
|----------|------|--------|
| 깊이 불연속 | 전경 블러 오브젝트가 중경 위로 번지지 않음 | 다중 깊이값 읽기, CoC 바이어스 |
| 바이리니어 보간 | 저해상도 밉맵 확대 시 네모난 패턴 | Summed-Area Table, 풀해상도 블러 이미지, 지터 |
| 픽셀 블리딩 | 포커스 색상이 아웃오브포커스 영역으로 번짐 | 레이어별 분리 렌더링 후 합성 |

## 수식 및 알고리즘

### CoC 직경 (월드 공간)
$$\text{CoC} = \left| \frac{A \cdot f \cdot (d - d_f)}{d \cdot (d_f - f)} \right|$$
- $A$: 조리개 크기
- $f$: 초점 거리
- $d$: 오브젝트 거리
- $d_f$: 초점면 거리

### Z-Buffer → 오브젝트 거리
$$d = \frac{-z_{far} \cdot z_{near}}{z(z_{far} - z_{near}) - z_{far}}$$

### Z-Buffer 선형 CoC
$$\text{CoC} = |z \cdot S + B|$$
- $S$, $B$: CPU에서 사전 계산된 스케일/바이어스 상수

### Accumulation Buffer 패스 수
CoC 반경 $r$ 픽셀 → 최소 $\frac{\pi r^2}{4}$ 패스 (단순), $\sim 2r$ 패스 (지터 + 가우시안)

## UE5 관점에서의 활용

- **UE5 DOF**: Reverse-Mapped Z-Buffer의 진화형인 **Cinematic DOF**를 사용. 각 픽셀의 CoC를 계산하고 가변 블러 적용
- **Bokeh DOF**: UE5는 물리적으로 정확한 보케 형태를 시뮬레이션. Forward-Mapped 접근법의 개선판 (scatter-as-gather)
- **CircleDOF / DiaphragmDOF**: 전경/배경을 분리 처리하여 깊이 불연속 아티팩트 해결 — 이 챕터의 Layered 기법과 유사한 발상
- **물리 카메라 파라미터**: UE5의 Cine Camera Actor에서 실제 카메라 용어(f-stop, focal length, sensor size)로 DoF 제어 — CoC 공식이 동일
- **현대적 대안**:
  - **Circular DOF** (Klehm et al. 2014): 효율적인 scatter-based DoF
  - **Hexagonal Bokeh**: 6각형 보케 시뮬레이션
  - **Half-Resolution DoF**: 반 해상도 처리로 성능 최적화
- **Accumulation Buffer 기법**: UE5의 Path Tracer에서 다중 카메라 위치 샘플링으로 정확한 DoF 구현 (오프라인)

## 핵심 요약 (3줄)
- DoF는 CoC(Circle of Confusion) 직경을 z-버퍼에서 계산하고, 이에 비례하는 블러를 적용하여 카메라 렌즈 효과를 시뮬레이션하는 기법이다
- 5가지 기법 중 Reverse-Mapped Z-Buffer가 실시간에 가장 적합하며, 밉맵이나 멀티 텍스처 블렌딩으로 구현한다
- UE5의 Cinematic DOF는 이 기법의 직접적 후속이며, 물리 카메라 파라미터(f-stop, focal length)로 동일한 CoC 공식을 사용한다
