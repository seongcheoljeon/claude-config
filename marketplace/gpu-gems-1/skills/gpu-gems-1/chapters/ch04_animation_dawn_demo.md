# Chapter 4: Animation in the "Dawn" Demo
> 저자: Curtis Beeson (NVIDIA)

## 핵심 개념
- **해결하려는 문제**: 고해상도 캐릭터 메시의 애니메이션(스키닝 + 모프 타겟)을 CPU 대신 GPU vertex shader에서 수행
- **Indexed Skinning**: 본(bone) 인덱스와 가중치를 이용한 스켈레탈 애니메이션을 GPU에서 처리
- **Morph Targets (Blend Shapes)**: 표정 등 세밀한 변형을 차이 벡터(difference vector) 합산으로 구현
- **CPU vs GPU 트레이드오프**: 섀도우 볼륨 등 CPU에서 변형된 메시가 필요한 경우 판단 필요
- **입력 레지스터 제한**: 당시 GPU 최대 16개 per-vertex 입력 속성 → 리소스 할당 전략 필요

## 기술적 세부사항

### Indexed Skinning (GPU)
1. 각 정점에 최대 4개 본의 인덱스 + 가중치 저장
2. 본 행렬을 상수 레지스터에 로드
3. Vertex shader에서 각 본 행렬로 정점 변환 후 가중치 합산
4. **누적 스키닝(Accumulated Skinning)**: 행렬을 미리 합산하지 않고, 정점별로 가중 합산

### Morph Targets
1. 중립 포즈(neutral pose)와의 **차이 벡터**를 per-vertex 입력으로 전달
2. 각 모프 타겟에 블렌드 가중치를 곱해 합산:
   ```
   position = neutral_pos + w1*delta1 + w2*delta2 + ... + wN*deltaN
   normal = normalize(neutral_nml + w1*dnml1 + w2*dnml2 + ...)
   ```
3. Dawn 데모에서는 5개 블렌드 셰이프 사용 (위치 + 법선 영향)
4. 탄젠트는 새 법선에 대해 직교화(orthonormalization)로 재계산:
   ```
   tangent = neutralTangent - dot(neutralTangent, normal) * normal
   tangent = normalize(tangent)
   binormal = cross(normal, tangent)
   ```

### 입력 레지스터 할당
- 16개 중: position, normal, binormal, texcoord, bone weights, bone indices = 6개 사용
- 나머지 10개로 모프 타겟 할당
- 위치만: 10개, 위치+법선: 5개, 위치+법선+바이노멀: 3개
- Dawn은 위치+법선 5개 선택 (바이노멀은 cross product로 계산)

### CPU vs GPU 판단 기준
- 스텐실 섀도우 볼륨: 실루엣 엣지 탐색에 CPU 변형 메시 필요
- 멀티패스 렌더링(섀도우 버퍼, 글로우 등): GPU에서 매번 스키닝 반복 → vertex-limited 시 CPU가 유리
- 애플리케이션별로 프로파일링 후 결정

## 수식 및 알고리즘

**Indexed Skinning:**
$$P_{skinned} = \sum_{i=0}^{3} w_i \cdot M_{bone[i]} \cdot P_{local}$$
- $w_i$: 가중치 (합 = 1), $M_{bone[i]}$: 본 행렬

**Morph Target Blending:**
$$P_{final} = P_{neutral} + \sum_{j=1}^{N} \alpha_j \cdot \Delta P_j$$
$$N_{final} = normalize\left(N_{neutral} + \sum_{j=1}^{N} \alpha_j \cdot \Delta N_j\right)$$

**Tangent Orthonormalization:**
$$T' = T_{neutral} - (T_{neutral} \cdot N_{final}) \cdot N_{final}$$
$$T_{final} = normalize(T')$$
$$B_{final} = N_{final} \times T_{final}$$

## UE5 관점에서의 활용
- **GPU Skinning**: UE5에서 스켈레탈 메시 스키닝은 기본적으로 GPU에서 수행. 이 챕터가 설명한 접근법의 직접적 후손.
- **Morph Targets**: UE5의 Morph Target 시스템은 동일한 차이 벡터 합산 방식 사용. MetaHuman에서 수십 개의 페이셜 모프 타겟 활용.
- **Compute Shader Skinning**: 현대 UE5는 Compute Shader로 스키닝을 수행해 vertex shader 부담 감소
- **입력 제한 극복**: 현대 GPU는 버퍼(SSBO/SRV)에서 자유롭게 데이터를 읽을 수 있어 16개 attribute 제한 없음
- **ML Deformer**: UE5.4+에서는 머신러닝 기반 메시 변형으로 관절 볼륨 손실 문제 해결

## 핵심 요약 (3줄)
- GPU vertex shader에서 indexed skinning과 morph target blending을 수행해 CPU 부담을 덜어주는 방법을 다룬다.
- 제한된 입력 레지스터(16개) 내에서 본 스키닝 + 5개 모프 타겟을 효율적으로 배치하는 전략을 보여준다.
- 탄젠트 직교화로 범프 매핑 품질을 유지하면서 모프 타겟을 적용하는 실용적 기법을 제시했다.
