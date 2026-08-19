# Chapter 17: Ambient Occlusion
> 저자: Matt Pharr, Simon Green (NVIDIA)

## 핵심 개념
- **해결하려는 문제**: 환경맵(environment map)에서 오는 복잡한 조명 분포를 고려하면서, 지오메트리에 의한 빛의 차폐(occlusion)를 효율적으로 계산하는 것
- **핵심 아이디어**:
  1. **Accessibility (접근성)**: 표면 위 반구에서 다른 지오메트리에 가려지지 않는 비율. "스마트한 ambient 항"
  2. **Bent Normal (굽은 노멀)**: 차폐되지 않은 방향들의 평균 벡터. 환경맵 룩업 방향으로 사용
  3. **전처리 + 실시간 분리**: 모델 의존적인 occlusion 데이터를 오프라인 계산, 조명은 실시간 변경 가능
  4. **블러된 환경맵 룩업**: accessibility에 비례하는 블러 폭으로 환경맵을 샘플링
  5. **레이 트레이싱 or 하드웨어 가속 전처리**: 반구 방향 레이 캐스팅 또는 구형 섀도우맵 배열로 occlusion 계산

## 기술적 세부사항

### 전처리 알고리즘 (레이 트레이싱 방식)
각 삼각형 중심에서 반구 방향으로 레이를 쏴서 차폐 여부를 판단:

```
For each triangle:
  center = 삼각형 중심점 계산
  rays = 반구 위에 균일 분포된 레이 세트 생성
  avgUnoccluded = (0, 0, 0)
  numUnoccluded = 0
  For each ray:
    if (레이가 다른 지오메트리와 교차하지 않음):
      avgUnoccluded += ray.direction
      numUnoccluded++
  bentNormal = normalize(avgUnoccluded)
  accessibility = numUnoccluded / totalRays
```

### 레이 생성 (Rejection Sampling)
```
while (true):
  x, y, z = random(-1, 1)
  if (x² + y² + z² > 1) continue     // 단위구 밖이면 버림
  if (dot((x,y,z), N) < 0) continue   // 반구 아래면 버림
  return normalize(x, y, z)
```

### 하드웨어 가속 전처리
- 오브젝트 주위에 128~1024개의 섀도우 맵 광원을 구형으로 배치
- 각 광원마다 2 패스: 섀도우맵 생성 + 렌더링
- 최적화: 패스당 8개 섀도우맵을 텍스처 좌표 세트로 누적
- 뒷면 아티팩트 제거를 위해 N·L 함수를 곱함

### 데이터 저장
- 삼각형 중심에서 계산 → 인접 면 평균으로 정점당 값 생성
- 버텍스 셰이더를 통해 프래그먼트 보간
- 또는 텍스처맵에 저장 (거친 테셀레이션 모델용)

### 환경맵 블러 룩업
- bent normal을 lat-long 좌표로 변환하여 환경맵 룩업
- 블러 폭 = $\sqrt{\text{accessibility}}$ — 차폐가 많을수록 좁은 영역만 보임
- 밉맵 레벨 선택으로 자연스러운 블러 구현

## 수식 및 알고리즘

### Latitude-Longitude 환경맵 매개변수화
$$x = \sin\theta \cos\phi, \quad y = \sin\theta \sin\phi, \quad z = \cos\theta$$
$$\text{texcoord} = \left(\frac{\phi}{2\pi}, \frac{\theta}{\pi}\right)$$

### 블러 폭 계산 (1차 근사)
$$\text{width} = \sqrt{\text{accessibility}}$$

필터 면적이 가시 비율에 비례하도록 스케일링.

### Fragment Shader: 환경 조명
```hlsl
half4 main(half3 B : TEXCOORD0,          // bent normal
           half accessibility : TEXCOORD1,
           uniform sampler2D envlatlong) : COLOR
{
  half2 uv = latlong(B);
  half2 blurx, blury;
  computeBlur(uv, accessibility, blurx, blury);
  half3 Cenv = tex2D(envlatlong, uv, blurx, blury).xyz;
  return half4(accessibility * Cenv, 1);
}
```

### Lat-Long 좌표 변환
```hlsl
half2 latlong(half3 v) {
  v = normalize(v);
  half theta = acos(v.z);
  half phi = atan2(v.y, v.x) + PI;
  return half2(phi, theta) * half2(0.1591549, 0.6366198);
  // 0.1591549 = 1/(2π), 0.6366198 = 2/π... 아니, 1/π
}
```

### 최적화: 역삼각함수 대체
256×256 큐브맵 텍스처로 acos/atan2를 대체하면 GPU 명령어 수가 ~60에서 ~10으로 감소.

## UE5 관점에서의 활용

- **SSAO (Screen-Space Ambient Occlusion)**: 이 챕터의 AO 개념이 스크린 공간으로 확장된 것. UE5는 GTAO (Ground Truth Ambient Occlusion)를 기본 사용
- **Bent Normal**: UE5의 Distance Field AO에서 bent normal 개념을 적극 활용. 간접광 방향 보정에 사용
- **전처리 AO → 라이트맵**: 이 챕터의 오프라인 레이 트레이싱 AO는 UE5의 Lightmass 베이킹과 동일한 원리
- **현대적 대안**:
  - **RTAO (Ray-Traced AO)**: 하드웨어 레이 트레이싱으로 정확한 AO 계산 (Lumen의 일부)
  - **DFAO (Distance Field AO)**: SDF 기반 실시간 AO, bent normal 포함
  - **SSAO 변형들**: HBAO+, GTAO 등이 이 챕터의 기본 아이디어를 스크린 공간에서 구현
- **환경맵 블러**: UE5의 Reflection Capture에서 roughness에 따른 밉맵 레벨 선택이 동일한 원리

## 핵심 요약 (3줄)
- Ambient Occlusion은 표면 위 반구의 차폐 비율(accessibility)과 차폐되지 않은 평균 방향(bent normal)을 전처리로 계산하는 기법이다
- 환경맵 룩업 시 bent normal을 방향으로, accessibility의 제곱근을 블러 폭으로 사용하여 차폐에 따른 조명 변화를 효율적으로 표현한다
- 이 기본 원리는 현재 SSAO, GTAO, DFAO, RTAO 등 다양한 실시간 AO 기법으로 발전했으며, UE5에서는 GTAO + Lumen의 조합이 표준이다
