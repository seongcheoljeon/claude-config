# Chapter 22: Color Controls
> 저자: Kevin Bjorke, NVIDIA

## 핵심 개념
- **해결하려는 문제**: 영화/TV/인쇄 매체에서 사용하는 색상 보정(color correction) 기법을 실시간 그래픽스 파이프라인에서 픽셀 셰이더로 구현하는 것
- **핵심 아이디어**:
  1. **Per-Channel 보정**: R, G, B 각 채널을 독립적으로 조절 (Levels, Curves)
  2. **Color-Mixing 연산**: 출력 채널이 여러 입력 채널에 동시 의존 (색공간 변환, 채도 조절)
  3. **텍스처 기반 Curves**: Photoshop의 Curves를 1×256 텍스처로 베이킹하여 임의의 톤 매핑 구현
  4. **3D 컬러 큐브 텍스처**: 256³ 3D 텍스처로 RGB→RGB 임의 매핑 (메모리 많이 사용)
  5. **행렬 기반 색공간 조작**: 3×3 행렬로 밝기, 채도, 컬러 휠 회전, 대비 조절

## 기술적 세부사항

### Levels 조절
Photoshop의 Levels 대화상자를 셰이더로 직접 구현:

```hlsl
outPixel = (pow(((inPixel * 255.0) - inBlack) / (inWhite - inBlack), inGamma) *
            (outWhite - outBlack) + outBlack) / 255.0;
```
- `inBlack`, `inWhite`: 입력 흑점/백점
- `inGamma`: 감마 값
- `outBlack`, `outWhite`: 출력 흑점/백점
- CPU에서 정규화 항을 미리 나눠두면 셰이더 비용 절감

### Curves (텍스처 룩업 방식)
1. Photoshop에서 1×256 흑→백 그래디언트 이미지 생성
2. `.acv` Curves 파일을 적용
3. 결과 컬러 램프를 텍스처로 저장 (DDS/Targa)
4. 셰이더에서 입력 색상값을 텍스처 좌표로 사용하여 룩업

```hlsl
float3 InColor = tex2D(inSampler, IN.UV).xyz;
float3 OutColor;
OutColor.r = tex1D(ColorCorrMap, InColor.r).r;
OutColor.g = tex1D(ColorCorrMap, InColor.g).g;
OutColor.b = tex1D(ColorCorrMap, InColor.b).b;
```

### 그레이스케일 + 컬러 매핑
```hlsl
// ITU Rec 709 표준 가중치
float grayscale = dot(float3(0.222, 0.707, 0.071), inColor);
float3 OutColor = tex1D(ColorCorrMap, grayscale);
```
→ False-color, 듀오톤, 트리톤, 스타일화 효과 가능

### 3D 컬러 큐브
```hlsl
float3 InColor = tex2D(inSampler, IN.UV).xyz;
float3 OutColor = tex3D(colorSpaceSampler, inColor);
```
RGB 입력을 3D 텍스처 좌표로 사용하여 완전히 임의의 RGB→RGB 매핑. 256³ = 메모리 집약적.

### 행렬 기반 색공간 변환
```hlsl
float4 colorCubePS(vertexOutput IN, sampler2D ColorTex, float3x3 RGBxform) : COLOR
{
  float3 texColor = tex2D(ColorTex, IN.UV);
  float3 result = mul(RGBxform, texColor);
  return float4(result, 1.0);
}
```

### 색공간 조작 가이드
| 조작 | 방법 |
|------|------|
| 밝기 | 원점 (0,0,0) 기준 스케일 |
| 채도 | 대각선 (1,1,1) 기준 스케일 |
| 컬러 휠 회전 | (1,1,1) 방향 축 회전 |
| 대비 | 특정 점 기준 스케일. (0.5,0.5,0.5)=미드그레이 기준, (1,1,1)=화이트 기준 |

## 수식 및 알고리즘

### Levels 공식
$$\text{out} = \left(\left(\frac{\text{in} \times 255 - B_{in}}{W_{in} - B_{in}}\right)^\gamma \times (W_{out} - B_{out}) + B_{out}\right) / 255$$

### 그레이스케일 변환 (ITU Rec 709)
$$\text{gray} = 0.222 R + 0.707 G + 0.071 B$$

### 색공간 변환
$$\begin{pmatrix} R' \\ G' \\ B' \end{pmatrix} = M_{3 \times 3} \begin{pmatrix} R \\ G \\ B \end{pmatrix}$$

### 아티스트 워크플로우
1. 게임 스크린샷을 Photoshop에서 열기
2. 새 레이어에서 Levels/Curves 조절
3. 값을 추출하여 셰이더 프로그래머에게 전달
4. 셰이더로 동일한 보정 적용

## UE5 관점에서의 활용

- **UE5 Color Grading**: 이 챕터의 기법들이 직접 발전한 것. UE5의 Post Process Volume에 Color Grading 섹션이 있음
- **LUT (Look-Up Table)**: UE5는 3D LUT (보통 32³ 또는 64³)를 사용하여 임의의 색상 변환 적용 — 이 챕터의 3D 컬러 큐브와 동일
- **Tonemapping**: UE5의 ACES/Filmic 톤매핑이 Levels/Curves의 현대적 대안. 노출 보정 + S-커브
- **Color Grading 워크플로우**: UE5에서도 스크린샷 기반으로 DaVinci Resolve 등에서 LUT를 만들어 임포트하는 방식이 일반적
- **Per-Channel 조절**: UE5 Post Process의 Color Grading에서 Shadows/Midtones/Highlights 각각의 Saturation, Contrast, Gamma 등을 채널별로 조절 가능
- **현대적 대안**: HDR 디스플레이 지원으로 PQ/HLG 전달 함수가 추가되었으며, ACES 컬러 파이프라인이 영화 수준의 색 관리를 제공

## 핵심 요약 (3줄)
- Color Controls는 Levels, Curves, 행렬 변환 등 전통적인 영상/인쇄 색보정 기법을 GPU 픽셀 셰이더로 실시간 구현하는 기법이다
- 1D 텍스처 룩업으로 임의의 톤 커브를, 3D 텍스처로 완전한 RGB→RGB 매핑을, 3×3 행렬로 밝기/채도/컬러 휠 조작을 수행한다
- UE5의 Color Grading과 LUT 시스템이 이 기법들의 직접적 후속이며, 아티스트 친화적 워크플로우(스크린샷→보정→셰이더)는 지금도 동일하다
