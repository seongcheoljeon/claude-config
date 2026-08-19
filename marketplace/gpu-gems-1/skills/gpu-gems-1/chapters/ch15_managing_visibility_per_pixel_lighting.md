# Chapter 15: Managing Visibility for Per-Pixel Lighting
> 저자: John O'Rorke (Monolith Productions)

## 핵심 개념
- **해결하려는 문제**: Per-pixel 라이팅에서 폭증하는 배치(batch) 수를 가시성(visibility) 관리로 줄여 성능 향상
- **배치 병목**: GPU는 배치 내부는 빠르지만 배치 전환(state change)은 느림. Per-pixel 라이팅은 (오브젝트 × 광원) 배치 필요 → 폭발적 증가.
- **가시성 활용**: 카메라에 안 보이는 것, 광원 범위 밖인 것, 그림자에 완전히 가려진 것을 렌더링하지 않으면 배치 대폭 절감
- **포탈 가시성**: 포탈 기반 PVS(Potentially Visible Set)를 카메라와 광원 모두에 적용
- **시저 클리핑**: 광원의 화면 영향 범위를 2D 사각형으로 제한

## 기술적 세부사항

### Per-Pixel Lighting의 배치 문제
1. **Ambient Pass**: 전역 앰비언트 + 깊이 버퍼 확립 (오브젝트당 1배치)
2. **각 광원에 대해**:
   - Shadow Pass: 섀도우 볼륨 또는 섀도우 맵 (캐스터당 1배치)
   - Light Pass: 조명 계산 (수신 오브젝트당 1배치)
3. 총 배치 = 오브젝트수 + Σ(광원별 캐스터수 + 수신자수)
4. 10개 광원 × 50개 오브젝트 → 수백~수천 배치

### 가시성 최적화 단계

**1. 카메라 가시성 (View Frustum Culling)**
- 카메라 절두체 밖 오브젝트 제거
- 포탈/PVS(Potentially Visible Set) 시스템으로 실내 환경에서 강력한 컬링
- 기본이지만 효과가 큼

**2. 광원 가시성 (Light Volume Culling)**
- 각 광원의 영향 범위(구 또는 절두체) 밖의 오브젝트 제거
- 포탈 시스템을 광원에도 적용: 광원이 보는 영역의 PVS 계산
- 광원의 PVS ∩ 카메라의 PVS = 실제 렌더링할 오브젝트

**3. 섀도우 가시성**
- 오브젝트가 광원에 대해 완전히 그림자에 가려져 있으면 라이트 패스 생략
- 섀도우 볼륨의 특성 활용: 특정 영역이 확실히 그림자임을 빠르게 판단

**4. 시저 클리핑**
- 광원의 화면 투영 바운딩 박스 계산
- `glScissor`로 해당 영역만 렌더링 → 필레이트 절감
- 특히 화면 일부만 차지하는 점/스팟 광원에서 효과적

### 포탈 시스템과 광원
- 실내 환경: 방(cell) + 문(portal) 구조
- 카메라가 있는 방에서 포탈을 통해 보이는 방만 렌더링
- **광원도 동일 로직**: 광원이 있는 방에서 포탈을 통해 빛이 도달하는 방만 계산
- 같은 가시성 시스템을 카메라와 광원 모두에 재사용

### 성능 결과 (정규화)
| 설정 | FPS | 배치 수 |
|---|---|---|
| 가시성 없음 | 1.0× | 최대 |
| 카메라 가시성만 | ~2× | 중간 |
| 카메라 + 광원 가시성 | ~3× | 적음 |
| + 섀도우 가시성 | ~4× | 매우 적음 |
| + 시저 클리핑 | ~5× | 최소 |

## 수식 및 알고리즘

**총 배치 수 (최적화 없음):**
$$B = N_{objects} + \sum_{l=1}^{N_{lights}} (N_{casters}(l) + N_{receivers}(l))$$

**가시성 적용 후:**
$$B_{opt} = |S_{cam}| + \sum_{l \in L_{vis}} (|S_{cam} \cap S_{light}(l) \cap C(l)| + |S_{cam} \cap S_{light}(l) \cap R(l)|)$$
- $S_{cam}$: 카메라 PVS
- $S_{light}(l)$: 광원 l의 PVS
- $C(l), R(l)$: 캐스터/수신자 세트

**시저 영역 계산:**
```
lightBBox = project(lightVolume, viewMatrix, projMatrix)
clamp(lightBBox, viewport)
scissor = bounding_rect(lightBBox)
```

## UE5 관점에서의 활용
- **Frustum Culling**: UE5의 기본 컬링. 오브젝트 바운딩 박스 vs 절두체 테스트.
- **Distance Culling**: 광원/오브젝트 거리 기반 컬링이 자동 적용됨
- **Light Complexity**: UE5의 r.ShowLightComplexity로 픽셀당 영향받는 광원 수 시각화
- **Tiled/Clustered Deferred Rendering**: 화면을 타일/클러스터로 나눠 각 영역에 영향을 주는 광원 리스트를 GPU에서 구축 → 이 챕터의 "광원별 영향 영역 제한" 아이디어의 현대적 확장
- **Lumen GI**: 간접광 계산에서도 가시성이 핵심. 소프트웨어 RT + SDF로 효율적 가시성 판단.
- **Nanite**: Nanite의 GPU-driven 컬링이 오브젝트 단위가 아닌 클러스터 단위로 가시성 판단

## 핵심 요약 (3줄)
- Per-pixel 라이팅에서 (오브젝트 × 광원) 배치 폭증 문제를 가시성 컬링으로 해결하는 체계적 접근법이다.
- 카메라 PVS, 광원 PVS, 섀도우 가시성, 시저 클리핑을 단계적으로 적용해 5배 이상의 성능 향상을 달성했다.
- 이 "광원별 영향 영역 제한" 원리는 현대 Tiled/Clustered Deferred Rendering의 핵심 아이디어로 발전했다.
