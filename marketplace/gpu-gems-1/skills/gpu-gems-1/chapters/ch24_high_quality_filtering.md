# Chapter 24: High-Quality Filtering
> 저자: Kevin Bjorke, NVIDIA

## 핵심 개념
- **해결하려는 문제**: GPU 하드웨어의 텍스처 필터링은 빠르지만 텍셀 포맷과 필터 유형에 제한이 있다. 커스텀 이미지 필터링(안티앨리어싱, 에지 감지, 바이큐빅 등)을 품질과 속도 사이에서 균형 잡아 구현하는 것
- **핵심 아이디어**:
  1. **3×3 Convolution**: 9개 텍셀 가중 합산. Helper 텍스처로 텍스처 읽기 횟수 9→3으로 감소
  2. **Mitchell-Netravali Bicubic 필터**: 4×4 텍셀 기반 고품질 필터링. 커널을 텍스처에 저장
  3. **Analytical Antialiasing**: ddx()/ddy() 편미분으로 필터 폭을 계산하여 프로시저럴 패턴의 앨리어싱 제거
  4. **Separable 필터**: 2D 필터를 1D×2로 분리하여 계산 복잡도 감소
  5. **Helper 텍스처**: 인접 텍셀 오프셋을 채널에 인코딩하여 한 번의 샘플링으로 4개 이웃 획득

## 기술적 세부사항

### 3×3 Convolution 기본 구현
```hlsl
float4 convolve3x3PS(vertexOutput IN, uniform sampler2D ColorMap,
                     uniform float W00..W22, uniform float Sum,
                     uniform float StepHoriz, uniform float StepVert) : COLOR
{
  float2 ox = float2(StepHoriz, 0.0);
  float2 oy = float2(0.0, StepVert);
  // 9개 텍셀 샘플링
  float4 C00 = tex2D(ColorMap, IN.UV - oy - ox);
  // ... 총 9개
  float4 Ci = C00*W00 + C01*W01 + ... + C22*W22;
  return Ci / Sum;
}
```
→ 9회 텍스처 읽기, 40+ 명령어

### Helper 텍스처 최적화 (그레이스케일)
인접 4텍셀을 하나의 RGBA 텍스처에 미리 패킹:
- **Neighbor 텍스처**: R=왼쪽, G=오른쪽, B=위, A=아래
- **Corner 텍스처**: R=좌상, G=우상, B=좌하, A=우하

```hlsl
float gray = tex2D(GrayMap, IN.UV).x;       // 중앙
float4 ntex = tex2D(NeighborMap, IN.UV);     // 상하좌우 4개
float4 ctex = tex2D(CornerMap, IN.UV);       // 대각선 4개
```
→ 3회 텍스처 읽기로 9개 텍셀 접근

### 사전 결합 가중치 최적화
```hlsl
float Ci = W11 * gray + dot(ntex, W10120121) + dot(ctex, W00022022);
```
→ ~11 명령어로 감소 (40+ → 11)

### Sobel 에지 감지
```hlsl
float sx = g20 + g22 - g00 - g02 + 2*(g21 - g01);  // 수평
float sy = g22 + g02 - g00 - g20 + 2*(g12 - g10);  // 수직
float dist = sx*sx + sy*sy;
float result = (dist > Threshold*Threshold) ? 0 : 1;
```

### Mitchell-Netravali Bicubic 필터
4×4 텍셀 기반, B와 C 파라미터로 필터 특성 조절:

**필터 함수 (0 < x < 1):**
$$\frac{(12-9B-6C)x^3 + (-18+12B+6C)x^2 + (6-2B)}{6}$$

**필터 함수 (1 ≤ x < 2):**
$$\frac{(-B-6C)x^3 + (6B+30C)x^2 + (-12B-48C)x + (8B+24C)}{6}$$

**구현:**
- 커널 가중치를 256×1 텍스처에 사전 계산
- 4행 각각에 대해 cubicFilter 적용 (f.x), 결과에 대해 다시 cubicFilter (f.y)
- 총 16 텍셀 샘플 + 5 커널 텍스처 룩업

```hlsl
float4 cubicFilter(samplerRECT kernelTex, float xValue,
                   float4 c0, float4 c1, float4 c2, float4 c3) {
  float4 h = texRECT(kernelTex, float2(xValue * 256.0, 0.0));
  return c0*h.x + c1*h.y + c2*h.z + c3*h.w;
}
```

### Analytical Stripe Antialiasing
ddx()/ddy()로 필터 폭을 계산하고, 스트라이프 함수의 적분을 해석적으로 구함:

```hlsl
half stripe(float value, half balance, half invScale, float scale) {
  half width = abs(ddx(value)) + abs(ddy(value));  // 필터 폭
  half w = width * invScale;
  half x0 = value / scale - (w / 2.0);
  half x1 = x0 + w;
  half edge = balance / scale;
  half i0 = (1.0 - edge)*floor(x0) + max(0.0, frac(x0) - edge);
  half i1 = (1.0 - edge)*floor(x1) + max(0.0, frac(x1) - edge);
  return clamp((i1 - i0) / w, 0, 1);
}
```

### 편미분 기반 적응형 필터링
- `ddx()`, `ddy()`로 보간된 값의 변화율 계산
- 텍스처 필터 윈도우를 미분값 기반 사각형으로 결정
- 밉맵 레벨 자동 선택
- 편미분을 (0,0)으로 전달하면 강제 nearest-neighbor:
  ```hlsl
  float2 nilUV = float2(0, 0);
  float4 pt = tex2D(myTex, IN.UV, nilUV, nilUV);
  ```

## 수식 및 알고리즘

### YCbCr → RGB 변환 (ITU-R BT.601)
$$\text{YUV} = [1.164(Y - 16/255), (Cb - 128/255), (Cr - 128/255)]$$
$$R = \text{YUV}.x + 1.596 \cdot \text{YUV}.z$$
$$G = \text{YUV}.x - 0.813 \cdot \text{YUV}.z - 0.392 \cdot \text{YUV}.y$$
$$B = \text{YUV}.x + 2.017 \cdot \text{YUV}.y$$

### Stripe 적분
구간 $[x_0, x_1]$에서:
$$i(x) = (1 - e) \lfloor x \rfloor + \max(0, \text{frac}(x) - e)$$
$$\text{stripe} = \frac{i(x_1) - i(x_0)}{x_1 - x_0}$$

### 성능 비교
| 기법 | 명령어 수 | 텍스처 읽기 |
|------|-----------|------------|
| 기본 3×3 | ~40+ | 9 |
| Helper 텍스처 | ~11 | 3 |
| 텍스처 기반 스트라이프 | 프로시저럴의 1/3 | 1 |
| 프로시저럴 스트라이프 | 높음 | 0 |

## UE5 관점에서의 활용

- **Compute Shader 컨볼루션**: UE5에서는 3×3 같은 소규모 컨볼루션도 Compute Shader로 구현. 공유 메모리로 텍스처 읽기 최적화
- **Bicubic 필터링**: UE5의 Temporal Upsampling(TSR)에서 bicubic/Catmull-Rom 필터 사용. 업스케일링 시 바이리니어보다 선명한 결과
- **ddx/ddy**: HLSL의 ddx(), ddy()는 UE5 머티리얼에서도 사용 가능 (DDX, DDY 노드). 프로시저럴 패턴 앤티앨리어싱에 활용
- **Sobel 에지 감지**: UE5의 포스트 프로세스에서 Outline/Edge Detection 효과에 동일한 Sobel 커널 사용
- **Helper 텍스처 패턴**: 현대 GPU에서는 텍스처 읽기 비용이 상대적으로 낮아져, 이 특정 최적화의 필요성은 감소. 하지만 GatherRed/Green/Blue/Alpha 명령어가 유사한 역할
- **Separable 필터**: Bloom, DOF, SSR 등 UE5의 거의 모든 블러/필터 효과가 separable 구현
- **Mitchell-Netravali**: UE5의 다양한 다운샘플/업샘플 패스에서 사용. 특히 TSR의 History 샘플링

## 핵심 요약 (3줄)
- High-Quality Filtering은 3×3 컨볼루션, 바이큐빅 필터링, 해석적 안티앨리어싱 등 GPU에서 커스텀 이미지 필터를 효율적으로 구현하는 기법들을 다룬다
- Helper 텍스처로 텍스처 읽기를 9→3으로 줄이고, 커널 텍스처로 바이큐빅을 구현하며, ddx()/ddy()로 프로시저럴 패턴을 해석적으로 안티앨리어싱한다
- 이 기법들은 UE5의 TSR(바이큐빅 업샘플링), 포스트 프로세스(Sobel, 가우시안), Material(DDX/DDY 노드) 등에서 현재도 핵심 빌딩 블록으로 사용된다
