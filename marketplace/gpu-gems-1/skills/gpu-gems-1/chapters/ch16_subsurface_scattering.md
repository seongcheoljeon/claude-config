# Chapter 16: Real-Time Approximations to Subsurface Scattering
> 저자: Simon Green, NVIDIA

## 핵심 개념
- **해결하려는 문제**: 피부, 대리석 같은 반투명 재질에서 빛이 표면 아래로 들어가 산란 후 다른 지점에서 나오는 현상(Subsurface Scattering)을 실시간으로 근사하는 것
- **핵심 아이디어**:
  1. **Wrap Lighting**: diffuse 조명을 표면 뒤쪽까지 감싸서 SSS의 부드러운 조명 효과를 근사
  2. **Depth Map 기반 흡수 시뮬레이션**: 빛의 입사점~출사점 거리를 depth map으로 측정하여 재질 내부 이동 거리에 따른 흡수 계산
  3. **Texture-Space Diffusion**: UV 공간에서 조명을 렌더링한 뒤 가우시안 블러로 빛의 확산을 시뮬레이션
  4. **파장별 필터링**: R/G/B 채널마다 다른 블러 폭을 적용해 피부의 붉은 색조 전이를 재현
  5. **LUT 기반 피부 셰이딩**: NdotL, NdotH를 인덱스로 하는 2D 텍스처 룩업으로 비용 절감

## 기술적 세부사항

### Wrap Lighting
가장 간단한 SSS 근사법. 표준 diffuse 공식 `max(0, N·L)`을 변형하여 빛이 표면 뒤쪽으로 "감싸도록" 한다.

```hlsl
float diffuse = max(0, dot(L, N));
float wrap_diffuse = max(0, (dot(L, N) + wrap) / (1 + wrap));
```

- `wrap` 값(0~1)이 클수록 빛이 더 뒤쪽까지 감싸짐
- 결과를 1D 텍스처에 인코딩하면 색조 변화도 포함 가능 (명암 경계에서 붉은 빛)
- 매우 저렴하지만, 빛이 재질을 "관통"하는 효과는 표현 불가

### Depth Map 기반 흡수
빛의 재질 내부 이동 거리를 측정하여 지수적 감쇠를 적용하는 방법.

**2-Pass 알고리즘:**
1. **1st Pass (광원 시점)**: 광원에서 장면을 렌더링하여 depth map 생성. 광원→표면 거리를 텍스처에 저장. 셀프 섀도잉 방지를 위해 버텍스를 노멀 방향으로 약간 팽창(grow)
2. **2nd Pass (카메라 시점)**: 각 프래그먼트를 광원 텍스처 공간으로 변환하여 입사점 거리($d_i$)를 룩업하고, 출사점 거리($d_o$)를 계산하여 관통 깊이 $s = d_o - d_i$를 구함

```hlsl
// 흡수 계산
return exp(-s * sigma_t) * lightColor;
```

**한계**: 볼록(convex) 오브젝트에만 정확. 오목한 부분은 depth peeling으로 보완 가능.

### Texture-Space Diffusion
가장 물리적으로 정확한 근사:
1. 메시의 UV 좌표를 화면 좌표로 사용하여 조명을 2D 텍스처에 렌더링 (UV 언래핑)
2. 가우시안 블러를 텍스처 공간에서 적용 → 빛의 확산 효과
3. 블러된 조명 텍스처를 다시 3D 모델에 적용

**파장별 블러**: 피부의 경우 빨간색이 가장 많이 산란하므로 R 채널에 넓은 블러, G/B에는 좁은 블러를 적용.

**Separable 블러 최적화**: 7-tap 가우시안 블러에서 2텍셀 간격 샘플링 + 하드웨어 바이리니어 필터링을 활용하여 효과적으로 13텍셀 범위를 커버.

## 수식 및 알고리즘

### Wrap Lighting 함수
$$\text{wrap\_diffuse} = \max\left(0, \frac{N \cdot L + w}{1 + w}\right)$$

### 지수적 흡수 (Beer-Lambert 법칙 기반)
$$I_{out} = I_{in} \cdot e^{-s \cdot \sigma_t}$$
- $s$: 재질 내부 이동 거리
- $\sigma_t$: 재질의 흡수 계수 (extinction coefficient)

### 관통 거리 계산
$$s = d_o - d_i$$
- $d_i$: 광원→입사점 거리 (depth map에서 룩업)
- $d_o$: 광원→출사점 거리 (직접 계산)

### 피부 LUT 생성 공식
```hlsl
NdotL_wrap = (NdotL + wrap) / (1 + wrap);
diffuse = max(NdotL_wrap, 0.0);
scatter = smoothstep(0.0, scatterWidth, NdotL_wrap) *
          smoothstep(scatterWidth * 2.0, scatterWidth, NdotL_wrap);
specular = (NdotL_wrap > 0) ? pow(NdotH, shininess) : 0;
```

### Vertex Shader: UV 공간 언래핑
```hlsl
OUT.hpos.xy = IN.texture * 2 - 1;  // UV를 [-1,1] 클립 공간으로 매핑
OUT.hpos.z = 0.0;
OUT.hpos.w = 1.0;
```

### Fragment Shader: 파장별 가우시안 블러 가중치
```hlsl
const float4 weight[7] = {
  {0.006, 0.0, 0.0, 0.0},     // R만 넓게 블러
  {0.061, 0.0, 0.0, 0.0},
  {0.242, 0.25, 0.25, 0.0},   // G,B는 중앙 근처만
  {0.383, 0.5, 0.5, 0.0},     // 중앙
  {0.242, 0.25, 0.20, 0.0},
  {0.061, 0.0, 0.0, 0.0},
  {0.006, 0.0, 0.0, 0.0}
};
```

## UE5 관점에서의 활용

- **UE5의 Subsurface Profile 셰이딩 모델**: 이 챕터의 Texture-Space Diffusion 개념을 발전시킨 **Separable SSS (Screen-Space Subsurface Scattering)**가 UE5의 기본 SSS 구현. Burley의 normalized diffusion 프로파일을 사용하여 더 물리적으로 정확
- **Wrap Lighting**: UE5에서는 직접 쓰이진 않지만, 커스텀 셰이딩 모델이나 NPR 렌더링에서 여전히 유용한 트릭
- **Depth Map 기반 기법**: UE5의 Transmission 기능(뒷면 조명)이 유사한 원리 사용. 얇은 재질(귀, 잎사귀)의 빛 투과를 표현
- **현대적 대안**: Screen-Space SSS (Jimenez et al. 2015)가 표준. 텍스처 공간 대신 스크린 공간에서 블러하여 UV 이음새 문제 해결. UE5는 이 방식 사용
- **LUT 기반 셰이딩**: Pre-Integrated Skin Shading으로 발전. UE5에서도 유사한 룩업 텍스처 활용

## 핵심 요약 (3줄)
- SSS의 실시간 근사는 Wrap Lighting(가장 저렴), Depth Map 흡수(중간), Texture-Space Diffusion(가장 정확)의 세 단계로 접근할 수 있다
- 파장별로 다른 블러 폭을 적용하는 것이 피부 렌더링의 핵심이며, 이것이 현대 Screen-Space SSS의 기초가 됐다
- 2D LUT에 diffuse+scatter+specular를 인코딩하는 방식은 Pre-Integrated Skin Shading으로 발전하여 현재도 모바일 등 저사양 환경에서 활용된다
