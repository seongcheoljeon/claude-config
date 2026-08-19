# Chapter 3: Skin in the "Dawn" Demo
> 저자: Curtis Beeson (NVIDIA), Kevin Bjorke (NVIDIA)

## 핵심 개념
- **해결하려는 문제**: 프로그래머블 셰이더를 사용해 사실적인 인간 피부를 실시간으로 렌더링하는 것. GeForce FX 출시 데모 "Dawn"에서 사용.
- **피부의 어려움**: 인간은 피부의 미묘한 차이를 매우 잘 감지함. Subsurface scattering, rim lighting 등이 틀리면 바로 "플라스틱 같다"고 느낌.
- **HDR 환경 조명**: 고동적 범위(HDR) 환경 맵을 diffuse/specular 큐브맵으로 분리해 조명
- **다층 텍스처 시스템**: 베이스 컬러, 디테일, 범프 등 여러 텍스처 레이어를 조합
- **Wrap Lighting + Rim Lighting**: 서브서피스 산란을 근사하는 핵심 기법

## 기술적 세부사항

### HDR 환경 조명
1. HDR 환경맵을 **diffuse 큐브맵** (넓게 blur)과 **specular 큐브맵** (날카로운 반사)으로 분리
2. Vertex shader에서 법선을 변환해 큐브맵 조회 좌표 생성
3. Fragment shader에서 두 큐브맵을 각각 조회해 조합

### 피부 셰이딩 기법
- **Wrap Lighting**: N·L 계산을 변형해 빛이 표면 뒤쪽까지 감싸는 효과
  - `NdotL_wrap = (NdotL + wrap) / (1 + wrap)` (wrap ≈ 0.2)
  - 빛-그림자 경계에서 붉은 색조 추가 (피부 아래 혈액 표현)
- **Rim Lighting**: 시선 방향과 법선이 거의 수직인 가장자리에서 밝아지는 효과
  - 귀, 코 등 얇은 부분에서 빛이 투과하는 느낌
- **Subsurface Scattering 근사**: 실제 SSS 대신 wrap lighting + scatter color로 근사
  - 밝음→어둠 전환 영역에서 `smoothstep`으로 scatter color 추가

### 텍스처 구성
- 베이스 컬러맵 (전체 피부 색상)
- 디테일 맵 (닭살, 모공 등 미세 디테일)
- 범프맵 (표면 요철)
- Specular 마스크 (부위별 반사율 제어)

### 셰이더 구조
```
Vertex: 법선/탄젠트 변환, 큐브맵 좌표 생성
Fragment:
  1. diffuse 큐브맵 조회 → 기본 조명
  2. specular 큐브맵 조회 → 반사 하이라이트
  3. wrap lighting 계산 → SSS 근사
  4. 베이스 컬러 × 조명 + scatter + rim + specular
  5. 디테일/범프 적용
```

### Fresnel 기반 Rim Lighting
```hlsl
float fresnel = pow(1.0 - saturate(dot(N, V)), fresnelPower);
float rim = fresnel * rimIntensity;
```
- `fresnelPower` ≈ 2~4 (값이 클수록 가장자리만 밝아짐)
- 시선(V)과 법선(N)이 수직에 가까운 영역 = 피부가 얇은 부위(귀, 코끝) → 빛 투과 느낌
- 광원 방향 고려: `rim *= saturate(dot(L, -V))` 로 뒤에서 빛이 올 때만 활성화

### SSS 근사 품질 비교
| 기법 | 비용 | 품질 | 적용 대상 |
|------|------|------|----------|
| Wrap Lighting만 | 매우 낮음 | 낮음 | 모바일, 배경 NPC |
| Wrap + Scatter + LUT | 낮음 | 중간 | Dawn 데모, PS2/PS3 세대 |
| Texture-Space Diffusion | 중간 | 높음 | Ch.16 기법, pre-UE4 |
| Screen-Space SSS (Jimenez) | 중간 | 매우 높음 | UE5 기본, AAA 표준 |
| Monte Carlo Path Tracing | 매우 높음 | 최고 | 오프라인, 시네마틱 |

### 한계
- HDR 환경맵 기반이므로 **동적 라이팅 변화에 약함** — 큐브맵 재생성이 필요
- Wrap Lighting은 재질 내부의 실제 산란 경로를 무시 — 두께에 따른 투과량 차이를 표현 못함
- 단일 LUT로는 피부 부위별 특성(이마 vs 볼 vs 입술) 차이를 표현하기 어려움

## 수식 및 알고리즘

**Wrap Lighting:**
$$NdotL_{wrap} = \frac{N \cdot L + wrap}{1 + wrap}$$

**Scatter (SSS 근사):**
$$scatter = smoothstep(0, w, NdotL_{wrap}) \times smoothstep(2w, w, NdotL_{wrap})$$
- 밝음→어둠 전환 구간에서만 활성화되는 벨 커브

**2D LUT 기반 피부 셰이딩:**
$$s.x = N \cdot L, \quad s.y = N \cdot H$$
$$color = tex2D(skinLUT, s \times 0.5 + 0.5)$$
- diffuse + scatter를 RGB에, specular를 alpha에 인코딩

## UE5 관점에서의 활용
- **Subsurface Profile Shading**: UE5는 전용 SSS 프로파일 셰이딩 모델을 제공. Dawn의 wrap lighting 근사보다 훨씬 물리적으로 정확
- **Pre-Integrated Skin Shading**: Dawn의 2D LUT 접근법은 현대의 pre-integrated skin BRDF의 선구자
- **Screen-Space SSS**: Separable SSS (Jimenez et al.)가 UE5에서 사용됨. 스크린 공간에서 가우시안 블러로 SSS 근사
- **캐릭터 파이프라인**: 다층 텍스처 시스템은 UE5의 Material Layer 시스템과 개념적으로 유사

## 핵심 요약 (3줄)
- HDR 환경 큐브맵과 wrap lighting을 결합해 실시간 피부 렌더링의 초기 모범을 보여줬다.
- Subsurface scattering을 LUT 기반 근사로 처리해 빛-그림자 전환부에 피부 특유의 붉은 색조를 표현했다.
- 이 접근법은 현대 pre-integrated skin shading과 screen-space SSS의 직접적 선조다.
