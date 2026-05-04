# Chapter 20: Texture Bombing
> 저자: R. Steven Glanville, NVIDIA

## 핵심 개념
- **해결하려는 문제**: 넓은 영역(꽃밭, 도시 건물)에 텍스처를 반복 타일링하면 눈에 띄는 규칙적 패턴이 생기는 문제. 거대한 텍스처 데이터 없이 비반복적 외관을 만드는 것
- **핵심 아이디어**:
  1. **셀 기반 배치**: UV 공간을 정규 그리드로 나누고, 각 셀 내 무작위 위치에 이미지를 배치
  2. **의사난수 텍스처**: 셀 좌표를 시드로 사용하여 난수 텍스처에서 오프셋/색상 등을 샘플링
  3. **우선순위 기반 합성**: 겹치는 이미지들을 난수 우선순위로 정렬하여 합성
  4. **프로시저럴 이미지 생성**: 텍스처 대신 수학적 도형(원 등)을 프로시저럴하게 생성
  5. **3D 확장 & Voronoi**: 오브젝트 공간 좌표로 3D 확장, 거리 기반 Voronoi 셀룰러 패턴

## 기술적 세부사항

### 기본 알고리즘 (4셀 샘플링)
1. UV를 스케일하고 floor로 셀 인덱스 계산
2. 셀 내 오프셋 계산
3. 현재 셀 + 왼쪽/아래 이웃 포함 4개 셀 순회
4. 각 셀에서 난수 텍스처로 오프셋 조회, 이미지 겹침 확인
5. 알파 + 우선순위 기반 합성

```hlsl
float2 scaledUV = UV * scale;
int2 cell = floor(scaledUV);
float2 offset = scaledUV - cell;

for (i = -1; i <= 0; i++) {
  for (j = -1; j <= 0; j++) {
    float2 cell_t = cell + float2(i, j);
    float2 offset_t = offset - float2(i, j);
    randomUV = cell_t.xy * float2(0.037, 0.119);
    random = tex2D(randomTex, randomUV);
    image = tex2D(imageTex, offset_t - random.xy);
    if (random.w > priority && image.w > 0.0) {
      color = image;
      priority = random.w;
    }
  }
}
```

### 난수 생성
셀 좌표에 `float2(0.037, 0.119)` 같은 스케일 팩터를 곱하여 난수 텍스처의 비상관 위치를 샘플링. 인접 셀이 1텍셀 이상 떨어지면 충분.

### 셀당 복수 샘플
```hlsl
randomUV = cell_t.xy * float2(0.037, 0.119);
for (k = 0; k < NUMBER_OF_SAMPLES; k++) {
  random = tex2D(randomTex, randomUV);
  randomUV += float2(0.03, 0.17);  // 중복 방지 오프셋
  // ... 이미지 처리
}
```

### 복수 이미지 선택 (타일 아틀라스)
```hlsl
float index = floor(random.z * NUM_IMAGES_PER_ROW);
uv.x = (saturate(uv.x) + index) / NUM_IMAGES_PER_ROW;
image = tex2D(imageTex, uv);
```

### 프로시저럴 원 생성
```hlsl
offset_t -= float2(0.5, 0.5) + (float2)random;
fixed radius2 = dot(offset_t, offset_t);
if (random.w > priority && radius2 < 0.25) {
  color = tex2D(randomTex, randomUV + float2(0.13, 0.4));
  priority = random.w;
}
```

### 3D 텍스처 바밍
오브젝트 공간 좌표를 사용하여 2×2×2 = 8셀 샘플링:
```hlsl
for (i = -1; i <= 0; i++)
  for (j = -1; j <= 0; j++)
    for (k = -1; k <= 0; k++) {
      cell_t = cell + float3(i, j, k);
      offset_t = offset - float3(i, j, k);
      randomUV = cell_t.xy * float2(0.037, 0.119) + cell_t.z * 0.003;
      // ... 처리
    }
```

### Voronoi 패턴
우선순위 대신 거리 비교:
```hlsl
radius2 = dot(offset_t, offset_t);  // 제곱근 계산 회피
if (radius2 < priority) {           // 가장 가까운 셀이 승리
  color = tex2D(randomTex, randomUV + float2(0.13, 0.4));
  priority = radius2;
}
```

## 수식 및 알고리즘

### 셀 좌표 계산
$$\text{cell} = \lfloor UV \times \text{scale} \rfloor$$
$$\text{offset} = UV \times \text{scale} - \text{cell}$$

### 난수 텍스처 인덱싱
$$\text{randomUV} = \text{cell} \times (0.037, 0.119)$$

### Voronoi 거리 (제곱)
$$d^2 = (\Delta x)^2 + (\Delta y)^2 = \text{dot}(\text{offset}, \text{offset})$$

### 3D 난수 인덱싱
$$\text{randomUV} = \text{cell.xy} \times (0.037, 0.119) + \text{cell.z} \times 0.003$$

### 성능 수치
- 데이지 이미지 (texbomb_2): 8 텍스처 샘플, 44 수학 명령어
- 프로시저럴 원 (gem_proc_2): 8 텍스처 샘플, 62 수학 명령어

## UE5 관점에서의 활용

- **Material 노드**: UE5의 Material Editor에서 World Position 기반 타일링 + 랜덤 오프셋으로 동일한 효과 구현 가능
- **Texture Bombing → Virtual Texturing**: UE5의 Runtime Virtual Texturing이 거대 영역의 비반복 텍스처링을 더 근본적으로 해결
- **Procedural Content**: UE5의 PCG (Procedural Content Generation) 프레임워크와 연관. 프로시저럴 배치의 개념적 선조
- **Nanite + 인스턴싱**: 개별 오브젝트 인스턴싱으로 텍스처 반복 문제를 지오메트리 레벨에서 해결하는 것이 현대적 접근
- **Voronoi 패턴**: UE5 Material의 Voronoi 노이즈 노드가 이 챕터의 Voronoi 알고리즘과 동일한 원리
- **Stochastic Tiling**: 최근 연구(Heitz & Neyret 2018)에서 이 아이디어를 발전시킨 Stochastic Texture Tiling이 등장. 통계적으로 반복 패턴을 제거

## 핵심 요약 (3줄)
- Texture Bombing은 UV 공간을 셀로 나누고 각 셀에 무작위 오프셋으로 이미지를 배치하여 텍스처 반복을 숨기는 프로시저럴 기법이다
- 우선순위 기반 합성, 멀티 샘플, 프로시저럴 생성, 3D 확장, Voronoi 패턴 등 다양한 변형이 가능하며, 난수 텍스처 하나로 모든 무작위성을 구동한다
- 이 개념은 현대의 Stochastic Texture Tiling, Virtual Texturing, PCG 등으로 발전했으며, UE5 Material의 Voronoi/랜덤 타일링 노드에 그 원리가 살아있다
