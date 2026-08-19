# Chapter 26: The OpenEXR Image File Format
> 저자: Florian Kainz, Rod Bogart, Drew Hess (Industrial Light & Magic)

## 핵심 개념
- **해결하려는 문제**: 기존 이미지 포맷(8비트/10비트)은 디스플레이 재현용으로 설계되어 동적 범위가 0.0~1.0으로 제한됨. GPU 렌더링, 합성, 포스트 프로세싱에서 정밀도 손실/클리핑 없이 HDR 데이터를 보존하는 것
- **핵심 아이디어**:
  1. **Half 포맷 (16비트 부동소수점)**: 1 부호 + 5 지수 + 10 가수. 최대값 65,504, 최소 양수 5.96×10⁻⁸. 1조:1 다이나믹 레인지
  2. **선형 색공간**: 픽셀값이 상대적 장면 휘도에 비례. 값 2배 = 밝기 2배. 올바른 알파 블렌딩과 안티앨리어싱의 전제조건
  3. **채널별 혼합 데이터 타입**: RGBA는 half, depth 채널은 float 등 유연한 구조
  4. **무손실 압축**: PIZ(웨이블릿+허프만, 35-55%), ZIP(zlib, 45-55%), RLE(60-75%)
  5. **VFX 산업 표준**: ILM이 개발, 크로스 플랫폼 오픈소스

## 기술적 세부사항

### Half 포맷 상세
- 16비트: 1 sign + 5 exponent + 10 mantissa
- 8스톱(노출 단계) 범위에서 채널당 8,192개 고유 값
- 비교: 8비트 감마 2.2는 동일 범위에 235개 값
- 각 포토그래픽 스톱(2배 계수)에 1,024개 고유 값
- NVIDIA의 하드웨어 half 구현과 동일

### OpenEXR 파일 구조

**헤더 속성들:**
| 속성 | 설명 |
|------|------|
| displayWindow | 이미지 해상도 |
| dataWindow | 크롭 & 오프셋 파라미터 |
| pixelAspectRatio | 가로:세로 비율 |
| channels | 채널 설명 (이름, 타입) |
| compression | 압축 알고리즘 |
| lineOrder | 스캔라인 저장 순서 |
| 커스텀 속성 | 앱별 메타데이터 |

### 압축 방식 비교
| 방식 | 기법 | 압축률 | 속도 |
|------|------|--------|------|
| PIZ | 웨이블릿 변환 + 허프만 | 35-55% | 균형 |
| ZIP | zlib 기반 수평 차분 | 45-55% | 압축 느림, 해제 빠름 |
| RLE | 차분값의 런렝스 인코딩 | 60-75% | 빠르지만 효율 낮음 |

### 파일 읽기 (C++ API)
```cpp
Imf::RgbaInputFile in(fileName);
Imath::Box2i win = in.dataWindow();
Imath::V2i dim(win.max.x - win.min.x + 1, win.max.y - win.min.y + 1);
pixelBuffer = new Imf::Rgba[dim.x * dim.y];
int dx = win.min.x, dy = win.min.y;
in.setFrameBuffer(pixelBuffer - dx - dy * dim.x, 1, dim.x);
in.readPixels(win.min.y, win.max.y);
```

### GPU 텍스처 바인딩 (OpenGL)
```cpp
glTexImage2D(GL_TEXTURE_RECTANGLE_NV, 0, GL_FLOAT_RGBA16_NV,
             dim.x, dim.y, 0, GL_RGBA, GL_HALF_FLOAT_NV, pixelBuffer);
```
- `GL_TEXTURE_RECTANGLE_NV`: 비 2의 거듭제곱 해상도 지원
- `GL_NEAREST` 필터링으로 정확한 값 보존
- `GL_CLAMP_TO_EDGE` 래핑

### 감마 보정 셰이더
```hlsl
Out main(float2 texCoord : TEXCOORD0,
         uniform samplerRECT image, uniform float gamma) {
  half4 pixel = h4texRECT(image, texCoord);
  output.color = pow(pixel, gamma);
  return output;
}
```

### 노출 조절 셰이더
```hlsl
pixel.rgb *= expMult;           // 선형 값에 노출 배수 곱
output.color = pow(pixel, gamma); // 감마 보정은 마지막에
```

### 필름 시뮬레이션 (LUT)
```hlsl
half lookup(samplerRECT lut, half h) {
  float f = pack_2half(h.xx);
  half4 bytes = unpack_4ubyte(f);
  return h1texRECT(lut, bytes.xy * 256.0);  // 256×256 LUT
}
```
- 채널별 독립 LUT로 필름 응답 곡선 시뮬레이션
- pack/unpack으로 half 값을 2D 인덱스로 변환

### 합성 연산 (Porter-Duff)
```hlsl
// Over: c = a + (1 - a.α) × b
c = a + (1 - a.a) * b;

// In: c = b.α × a
c = b.a * a;

// Out: c = (1 - b.α) × a
c = (1 - b.a) * a;
```

## 수식 및 알고리즘

### 모니터 감마
$$L(v) = L_m \cdot v^\gamma$$
- $L(v)$: 출력 휘도
- $v$: 프레임버퍼 값 (0~1)
- $\gamma$: 모니터 감마 (보통 2.2)

### 감마 역산
$$\gamma = \frac{\log(L_1/L_2)}{\log(v_1/v_2)}$$

### 감마 보정
$$\text{output} = \text{input}^{1/\gamma}$$

### 다이나믹 레인지 (스톱 단위)
$$\text{Stops} = \log_2(L_{max} / L_{min})$$
예: 1,000,000:1 = 20 스톱

### 선형 색공간 원칙
- 값 2배 = 밝기 2배
- 2로 나누기 = 1스톱 감소
- 올바른 알파 블렌딩의 전제조건
- 중간 값을 0-1로 클램핑하면 안 됨

## UE5 관점에서의 활용

- **UE5의 HDR 파이프라인**: UE5는 렌더링 전체를 선형 HDR 색공간에서 수행. 이 챕터의 핵심 원칙인 "선형에서 처리, 디스플레이 시에만 감마 보정"을 완전히 따름
- **Half 포맷**: UE5의 렌더 타겟은 R16G16B16A16_FLOAT (half) 또는 R11G11B10_FLOAT 사용 — OpenEXR의 half와 동일
- **EXR 임포트/익스포트**: UE5는 OpenEXR을 네이티브 지원. HDRI 환경맵 임포트, 무비 렌더 큐(MRQ)의 EXR 출력에 사용
- **톤매핑**: 이 챕터의 감마 보정 + 노출 배수가 UE5의 ACES/Filmic 톤매퍼로 발전. 더 정교한 S-커브 + 색역 매핑
- **합성 연산**: 이 챕터의 Porter-Duff Over/In/Out은 UE5의 알파 블렌딩과 동일한 원리
- **LUT 기반 색 변환**: UE5의 Color Grading LUT가 이 챕터의 필름 시뮬레이션 LUT와 동일한 개념
- **OpenEXR 라이브러리**: UE5는 OpenEXR 라이브러리를 ThirdParty로 포함. 직접 사용 가능

## 핵심 요약 (3줄)
- OpenEXR은 16비트 부동소수점(half) 기반의 HDR 이미지 포맷으로, 1조:1 다이나믹 레인지와 채널당 8,192개 값(8스톱)의 정밀도를 제공한다
- "선형 색공간에서 처리, 디스플레이에서만 감마 보정"이라는 원칙과 Porter-Duff 합성 연산을 GPU 셰이더로 구현하여 VFX 파이프라인을 지원한다
- UE5의 전체 HDR 렌더링 파이프라인, EXR 임포트/익스포트, 톤매핑이 이 챕터의 원칙을 그대로 계승하며, half 포맷은 렌더 타겟의 표준이다
