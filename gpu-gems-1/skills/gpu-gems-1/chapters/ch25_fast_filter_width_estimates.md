# Chapter 25: Fast Filter-Width Estimates with Texture Maps
> 저자: Matt Pharr, NVIDIA

## 핵심 개념
- **해결하려는 문제**: 프로시저럴 텍스처의 안티앨리어싱에 필요한 필터 폭(filter width)을 계산해야 하는데, 일부 하드웨어 프로파일(예: arbfp1)이 ddx/ddy 미분 함수를 지원하지 않는 상황에서 이를 근사하는 것
- **핵심 아이디어**:
  1. **밉맵 기반 미분 추정**: 텍스처 하드웨어가 밉맵 레벨을 선택하는 원리를 역이용하여, 텍스처 좌표의 변화율을 추정
  2. **특수 필터맵**: 밉맵 각 레벨에 해당 레벨의 log₂(텍셀 수)를 인코딩한 텍스처
  3. **3개 셰이더 명령어**: tex2D + exp2 + 스케일링으로 필터 폭을 계산
  4. **등방성 필터링**: 단일 필터 폭 근사 (이방성 대안보다 단순)
  5. **엣지 케이스 처리**: 최상/최하위 밉맵 레벨에서의 보정

## 기술적 세부사항

### 기본 filterwidth 함수 (ddx/ddy 사용 시)
```hlsl
float filterwidth(float2 v) {
  float2 fw = max(abs(ddx(v)), abs(ddy(v)));
  return max(fw.x, fw.y);
}
```

### 밉맵 기반 대안의 원리
하드웨어가 텍스처 좌표의 변화율에 따라 자동으로 밉맵 레벨을 선택한다는 점을 이용:
- 텍스처 좌표가 빠르게 변하면 → 높은(거친) 밉맵 레벨 선택
- 텍스처 좌표가 느리게 변하면 → 낮은(세밀한) 밉맵 레벨 선택

이 매핑을 역으로 하면: 선택된 밉맵 레벨 → 텍스처 좌표 변화율 ≈ 필터 폭

### 필터맵 생성

**밉맵 레벨 인코딩:**
- Level 0: 128×128 → 값 = 16 × 7 = 112 (log₂(128) = 7)
- Level 1: 64×64 → 값 = 16 × 6 = 96
- ...
- 최상위 레벨: 1×1 → 값 = 0

```cpp
GLubyte *data = new GLubyte[RES * RES];
for (int level = 0; level < LEVELS; ++level) {
  int res = (1 << (LEVELS - 1 - level));
  int log2Width = LEVELS - 1 - level;
  for (int i = 0; i < res * res; ++i)
    data[i] = 16 * log2Width;    // 정밀도를 위해 16배 스케일링
  glTexImage2D(GL_TEXTURE_2D, level, 1, res, res, 0,
               GL_RED, GL_UNSIGNED_BYTE, data);
}
```

### 런타임 필터 폭 계산
```hlsl
float filterwidth(float2 uv) {
  float log2width = (255.0 / 16.0) * tex2D(filterMap, uv).x;
  return exp2(-log2width);
}
```

1. 필터맵에서 텍스처 룩업 → 하드웨어가 적절한 밉맵 레벨 선택
2. 인코딩된 log₂ 값 추출 + 역스케일
3. `exp2(-log2width)`로 필터 폭 계산

### 엣지 케이스 처리 (강건한 버전)
```hlsl
float filterwidth(float2 uv) {
  float log2width = (255.0 / 16.0) * tex2D(filterMap, uv).x;
  if (log2width < 0.01) {     // 최상위 밉맵에 도달
    log2width = (255.0 / 16.0) * tex2D(filterMap, uv / 512.0).x;
    return 512.0 * exp2(-log2width);
  }
  return exp2(-log2width);
}
```

최상위/최하위 밉맵 레벨에서 정확도가 떨어지는 문제를 스케일된 텍스처 좌표로 보정.

### 텍스처 필터 설정
```
GL_TEXTURE_MIN_FILTER: GL_NEAREST_MIPMAP_LINEAR  // 밉맵 간 선형 보간
GL_TEXTURE_MAG_FILTER: GL_NEAREST                 // 확대 시 최근접
GL_TEXTURE_WRAP_S/T:   GL_REPEAT                   // 반복
```

NEAREST_MIPMAP_LINEAR가 중요: 밉맵 레벨 간 보간을 통해 연속적인 필터 폭 값을 얻음.

## 수식 및 알고리즘

### 필터 폭과 밉맵 레벨의 관계
$$\text{filterwidth} = 2^{-\text{mipLevel}}$$
$$\text{mipLevel} = -\log_2(\text{filterwidth})$$

### 인코딩/디코딩
$$\text{encoded} = 16 \times \log_2(\text{resolution})$$
$$\text{log2width} = \frac{255}{16} \times \text{texValue}$$
$$\text{filterwidth} = 2^{-\text{log2width}}$$

### 프로시저럴 체커보드 (필터 폭 활용)
```hlsl
float checker(float2 uv) {
  float width = filterwidth(uv);
  float2 p0 = uv - 0.5 * width;
  float2 p1 = uv + 0.5 * width;
  #define BUMPINT(x) (floor((x)/2) + 2.0*max((x)/2 - floor((x)/2) - 0.5, 0.0))
  float2 i = (BUMPINT(p1) - BUMPINT(p0)) / width;
  return i.x * i.y + (1 - i.x) * (1 - i.y);
}
```

### 필터 영역 경계
$$|uv - uv_1| < \text{filterwidth}(uv)$$

## UE5 관점에서의 활용

- **ddx/ddy 보편화**: 현대 GPU (SM 5.0+)는 모두 ddx/ddy를 지원하므로, 밉맵 기반 우회의 원래 동기는 사라짐
- **하지만 원리는 여전히 유효**: 밉맵 레벨과 텍스처 좌표 변화율의 관계는 여전히 핵심 개념
  - UE5의 Virtual Texture 밉맵 선택
  - Streaming Pool의 밉맵 레벨 결정
  - Nanite의 텍셀 밀도 계산
- **프로시저럴 안티앨리어싱**: UE5 Material의 프로시저럴 패턴에서 DDX/DDY 노드로 동일한 기법 사용
- **Texture Streaming**: 밉맵 레벨 = 필터 폭이라는 관계는 UE5의 텍스처 스트리밍 시스템의 기초. 필요한 밉맵만 메모리에 로드
- **현대적 대안**:
  - `CalculateLevelOfDetail()` / `CalculateLevelOfDetailUnclamped()`: HLSL 5.0+에서 직접 밉맵 레벨을 쿼리
  - `GetDimensions()`: 텍스처 크기를 직접 조회
  - Quad-level 연산: Wave Intrinsics로 인접 픽셀 값 접근

## 핵심 요약 (3줄)
- ddx/ddy를 지원하지 않는 하드웨어에서 텍스처 밉맵 선택 매커니즘을 역이용하여 필터 폭을 추정하는 기법이다
- 밉맵 각 레벨에 log₂(해상도)를 인코딩한 특수 텍스처를 만들고, 런타임에 단 3개 셰이더 명령어로 필터 폭을 계산한다
- ddx/ddy가 보편화된 현재는 직접적 필요성이 줄었지만, 밉맵 레벨 ↔ 필터 폭의 관계 이해는 UE5의 텍스처 스트리밍, LOD, 프로시저럴 안티앨리어싱에 여전히 핵심이다
