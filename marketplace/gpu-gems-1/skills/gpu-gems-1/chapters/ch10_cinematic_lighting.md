# Chapter 10: Cinematic Lighting
> 저자: Fabio Pellacini (Pixar Animation Studios), Kiril Vidimce (Pixar Animation Studios)

## 핵심 개념
- **해결하려는 문제**: Pixar의 영화 제작용 조명 모델(Uberlight)을 실시간 GPU 셰이더로 구현
- **Uberlight**: Ronen Barzel이 설계한 조명 모델. Toy Story, Monsters Inc., Finding Nemo 등에서 사용.
- **시네마틱 조명 철학**: 물리 정확성보다 **예술적 제어**가 우선. 조명 감독이 분위기와 스토리텔링을 위해 물리를 속임.
- **빛의 형상 제어(Shaping)**: Barn doors, cookies, 거리 감쇠 등으로 빛이 닿는 영역을 정밀 제어
- **Super-Ellipse 기반 크로스 섹션**: 원~사각형~별 형태까지 연속적으로 변형 가능한 빛의 단면

## 기술적 세부사항

### 조명 모델 구성 요소

**1. 빛과 표면의 상호작용 (BRDF)**
- `lit()` 함수로 ambient, diffuse, specular 기여 계산
- 조명 가중치 (ambient, diffuse, specular)와 표면 가중치를 별도로 제어
- roughness 파라미터로 specular 하이라이트 폭 조절

**2. Shaping — Barn Doors (Super-Ellipse)**
- 빛의 단면을 **초타원(Super-Ellipse)**으로 정의
- width, height, edge width, edge height, roundness 파라미터
- roundness로 원 ↔ 사각형 ↔ 별 형태 연속 변형
- 소프트 엣지: 내부/외부 초타원 두 개의 보간으로 구현
- 피라미드 전단(shear)으로 창문/문 효과

**3. Distance Shaping**
- near/far 거리와 각각의 edge 폭으로 빛의 도달 범위 제어
- 스무스 감쇠로 자연스러운 falloff

**4. Slide Projector (Cookie)**
- 텍스처를 빛에 투영해 패턴 생성 (나뭇잎 그림자, 창살 등)
- 라이트 공간에서 텍스처 좌표 계산

**5. Shadow Map**
- 깊이 맵 기반 그림자
- PCF(Percentage-Closer Filtering)로 안티앨리어싱

### Cg Fragment Shader 구조
```
입력: 라이트 공간 위치(Plight), 법선(N), 시선 방향(V)
1. computeLightDir(Plight) → 조명 방향
2. lit(NdotL, NdotH, roughness) → ambient/diffuse/specular
3. computeSuperellipseShaping(Plight, params) → barn door 마스크
4. computeDistanceShaping(Plight, params) → 거리 감쇠
5. tex2Dproj(slideMap, Plight) → cookie 텍스처
6. tex2Dproj(shadowMap, Plight) → 그림자 팩터
7. 최종: BRDF × shaping × cookie × shadow × lightColor
```

## 수식 및 알고리즘

**Super-Ellipse 판정:**
$$\left|\frac{x}{w}\right|^{2/r} + \left|\frac{y}{h}\right|^{2/r} \leq 1$$
- r: roundness (r=1 → 원, r→0 → 사각형)

**소프트 엣지:**
$$shape = 1 - smoothstep(inner_{ellipse}, outer_{ellipse}, value)$$

**거리 감쇠:**
$$atten = smoothstep(near - nearEdge, near, z) \times (1 - smoothstep(far, far + farEdge, z))$$

**최종 조명:**
$$C = L_{color} \times BRDF(N, L, V) \times Shape_{barn} \times Atten_{dist} \times Cookie \times Shadow$$

## UE5 관점에서의 활용
- **Light Functions**: UE5의 Light Function은 이 챕터의 cookie/slide projector와 동일 개념. 머티리얼로 빛의 형상 제어.
- **IES Profiles**: 실제 조명 기구의 배광 데이터를 사용. Barn doors의 물리적 버전.
- **Rect Light**: UE5의 Rectangle Light가 barn door 형태의 빛을 직접 제공
- **시네마틱 파이프라인**: 시퀀서(Sequencer)에서 라이트 파라미터를 키프레임으로 애니메이션 → 영화 제작과 동일한 워크플로
- **Lumen GI**: 간접광까지 물리 기반으로 계산되지만, 직접 조명에서의 예술적 제어 (intensity, color, falloff)는 여전히 이 챕터의 철학과 일맥상통

## 핵심 요약 (3줄)
- Pixar의 Uberlight 조명 모델을 실시간 Cg 셰이더로 구현해 시네마틱 조명의 예술적 제어력을 GPU로 가져왔다.
- Super-ellipse 기반 barn doors, 거리 감쇠, cookie 프로젝션, 섀도우 맵을 하나의 통합 셰이더로 조합한다.
- 이 "물리보다 예술적 제어 우선" 철학은 현대 게임 엔진의 조명 시스템 설계에 지대한 영향을 미쳤다.
