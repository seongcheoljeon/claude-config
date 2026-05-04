# Chapter 18: Spatial BRDFs
> 저자: David McAllister, NVIDIA

## 핵심 개념
- **해결하려는 문제**: 실제 표면은 공간적(spatial)으로도 각도적(angular)으로도 반사 특성이 변한다. BRDF와 텍스처 매핑을 결합한 컴팩트하고 하드웨어 렌더링 가능한 표현을 만드는 것
- **핵심 아이디어**:
  1. **Spatial BRDF (SBRDF)**: 각 텍셀마다 다른 BRDF 파라미터를 가지는 표면 표현. 공간 변화(텍스처) + 각도 변화(BRDF)의 결합
  2. **Lafortune BRDF 모델**: 일반화된 내적(generalized dot product)을 사용한 컴팩트한 BRDF 표현. 여러 specular lobe의 합 + diffuse 항
  3. **행렬 C 계수**: 로브의 형태와 방향을 제어 (등방/이방성, 정반사/역반사 등)
  4. **사전 컨볼루션 환경맵**: Phong 지수별로 컨볼루션된 환경맵을 큐브맵 밉맵 레벨에 저장
  5. **텍셀당 BRDF 파라미터 저장**: diffuse 컬러, lobe albedo, C 계수, 지수를 별도 텍스처맵에 저장

## 기술적 세부사항

### SBRDF 구조
텍셀마다 다음 파라미터를 저장:
- **Diffuse 텍스처**: diffuse albedo `d` (RGB + alpha)
- **Lobe별 albedo 텍스처**: 각 specular lobe의 세기 `sⱼ`
- **Lobe별 shape 텍스처**: `Cx, Cy, Cz, n` (C 계수 3개 + 지수)

8비트 텍스처의 경우 스케일/바이어스 필요: 96으로 스케일, 128으로 바이어스 (범위 -1.1~1.1).

### Lafortune 모델의 C 행렬 의미
| Cx, Cy, Cz 값 | 의미 |
|---|---|
| Cx=-1, Cy=-1, Cz=1 | 표준 정반사 |
| Cx=Cy | 등방성 BRDF |
| Cz<0 | 비정반사(off-specular) 반사 |
| Cx>0, Cy>0 | 역반사(retroreflection) |
| Cx, Cy 부호 반대 | 이방성(anisotropic) 산란 |

### 로컬 표면 좌표계
평가는 X, Y축이 이방성 방향(스크래치/실 방향)에 정렬되고 Z축이 표면 노멀에 정렬된 좌표계에서 수행.

### 텍스처 샘플링 주의사항
C 계수와 n은 비선형 함수 파라미터이므로 바이리니어/트리리니어 보간 시 반짝임(sparkly) 아티팩트 발생. **포인트 샘플링 권장**.

### 환경맵 사전 컨볼루션
Phong lobe를 다양한 지수값으로 환경맵과 컨볼루션:
- 큐브맵 밉맵 레벨에 저장: n=0(가장 거친 레벨) ~ n=256(가장 세밀한 레벨)
- 또는 3D 텍스처 사용: s,t = 파라볼릭 맵, r = 지수 n

### Vertex Shader 역할
- 라이트 벡터를 로컬 표면 좌표계로 변환
- 뷰 벡터를 로컬 표면 좌표계로 제공
- 월드 공간의 노멀, 탄젠트 벡터 전달

### Fragment Shader: 이산 광원
각 광원마다 각 lobe에 대해:
1. 텍스처에서 diffuse, albedo, lobe shape 파라미터 샘플링
2. 뷰/라이트 벡터 정규화 (로컬 좌표)
3. 스케일된 내적 계산: `Cwr_local = C · toeye`
4. Lobe 기여도: `thedot = dot(Cwr_local, tolight)`
5. Lobe 평가: `lobe_shape = lit(thedot, thedot, n).z`
6. 조도: `NdotL = max(0, tolight.z)`
7. 누적: `exitant_radiance = reflectance × irradiance`

## 수식 및 알고리즘

### 기본 SBRDF 공식
$$\rho(\mathbf{i}, \mathbf{r}) = \mathbf{d} + \sum_j s_j \cdot \rho_j(\mathbf{i}, \mathbf{r})$$

### Lobe 형태 (Phong과 유사)
$$\rho_j(\mathbf{i}, \mathbf{r}) = \left[(C \cdot \mathbf{i}) \cdot (C \cdot \mathbf{r})\right]^n$$

### 환경맵 기반 최종 렌더링
$$L(\mathbf{r}) = \mathbf{d} \cdot D(\mathbf{N}) + \sum_j s_j \cdot S_j(p_j(\mathbf{r}), n_j) \cdot |p_j(\mathbf{r})|^n \cdot (\mathbf{N} \cdot p_j(\mathbf{r}))$$

- $D(\mathbf{N})$: diffuse 환경맵 (노멀로 룩업)
- $S_j$: specular 환경맵 (lobe 피크 방향으로 룩업)
- $|p_j(\mathbf{r})|^n$: 정규화된 p로 인한 크기 보정

### 사전 컨볼루션 환경맵 계산
$$S_j(\mathbf{p}, n) = \frac{\int L_i(\mathbf{i}) \cdot (\mathbf{p} \cdot \mathbf{i})^n \, d\mathbf{i}}{\int (\mathbf{p} \cdot \mathbf{i})^n \, d\mathbf{i}}$$

### 환경맵 컨볼루션 의사코드
```hlsl
float3 S(float3 Wp, float n) {
  float3 Sum = 0; float WgtSum = 0;
  for each incident direction i in hemisphere:
    dp = dot(Wp, i);
    if (dp < 0) continue;
    lobe_shape = pow(dp, n);
    Irrad = Li(i) * dp / length²(i);
    Sum += Irrad * lobe_shape;
    WgtSum += lobe_shape;
  return Sum / WgtSum;
}
```

## UE5 관점에서의 활용

- **UE5의 Material Layer 시스템**: SBRDF의 "텍셀마다 다른 BRDF" 개념이 UE5의 Material Layer Blend로 발전. 각 레이어가 다른 PBR 파라미터 세트를 가짐
- **Lafortune → GGX**: Lafortune 모델은 현재 거의 사용되지 않음. UE5는 GGX (Trowbridge-Reitz) 분포를 사용하는 Cook-Torrance BRDF가 표준
- **이방성 반사**: UE5의 Anisotropy 파라미터가 이 챕터의 Cx≠Cy 개념을 현대적으로 구현
- **사전 필터링된 환경맵**: UE5의 Reflection Capture도 roughness별로 사전 필터링된 큐브맵 밉맵을 사용 — 동일한 원리
- **Split-Sum Approximation**: Epic의 Brian Karis가 제안한 방식으로, 이 챕터의 환경맵 사전 컨볼루션을 PBR에 맞게 발전시킨 것
- **컴팩트한 표현**: 10개 계수로 RGB 텍스처의 3배 크기라는 장점은 현재 PBR의 metallic/roughness/normal/AO 텍스처 세트와 유사한 발상

## 핵심 요약 (3줄)
- Spatial BRDF는 텍셀마다 독립적인 BRDF 파라미터를 저장하여 공간적+각도적 반사 변화를 동시에 표현하는 기법이다
- Lafortune 모델의 C 행렬로 정반사, 역반사, 이방성 등 다양한 반사 특성을 컴팩트하게 인코딩하고, 사전 컨볼루션된 환경맵으로 실시간 IBL을 구현한다
- 이 아이디어는 현대 PBR 워크플로우(텍셀당 roughness/metallic + 사전 필터링된 큐브맵)의 직접적인 선조이며, UE5의 Material 시스템과 Reflection Capture에 그 DNA가 남아있다
