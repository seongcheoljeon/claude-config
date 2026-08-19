# Chapter 42: Deformers
> 저자: Eugene d'Eon (University of Waterloo)

## 핵심 개념
- **해결하려는 문제**: 3D DCC 툴의 메시 디포머(Bend, Twist, Lattice 등)를 GPU 버텍스 프로그램으로 오프로딩
- 디포머는 입력 좌표를 변형된 좌표로 매핑하는 연산 — 버텍스 셰이더에 완벽히 적합
- **핵심 난제: 변형 후 노멀 계산** — 야코비 행렬(Jacobian Matrix)을 활용한 해석적 방법 제시
- 유한 차분법(finite differences)보다 야코비 방법이 더 정확하고 효율적
- 모델링 도구의 인터랙티브 성능 향상과 실시간 애니메이션 지원

## 기술적 세부사항

### 디포머의 요구사항
GPU에서 구현 가능한 디포머의 3가지 조건:
1. **정점/엣지 생성·삭제 없음** — 토폴로지 변경 불가
2. **정점 독립성** — 각 정점의 변형이 다른 정점에 의존하지 않음 (스무딩은 디포머가 아님)
3. **결정론적** — 동일 입력에 항상 동일 출력

### 디포머 예시
- **Translation**: $\mathbf{f}(\mathbf{x}) = \mathbf{x} + \mathbf{d}$
- **Bend**: 축을 기준으로 곡률 적용
- **Twist**: 축을 따라 회전각이 변하는 변형
- **Lattice**: 컨트롤 포인트 격자로 자유형 변형 (FFD)
- **Bulge, Shear, Taper**: 각종 공간 왜곡

### 노멀 계산 문제
변형 후 노멀을 다시 계산해야 함. 두 가지 방법:

#### 방법 1: 유한 차분법 (Finite Differences)
- 각 정점마다 3개의 정점을 추가로 변형 (탄젠트 방향, 바이노멀 방향으로 약간 이동)
- 변형된 3점으로 탄젠트/바이노멀 근사 → 외적으로 노멀 계산
- 단점: 3배 이상의 연산량, 수치적 불안정성 (오프셋 크기 선택 문제)

#### 방법 2: 야코비 행렬 (Jacobian Matrix) — 이 챕터의 핵심
디포머 $\mathbf{f}(x,y,z) = (f_x, f_y, f_z)$의 야코비 행렬:

$$\mathbf{J} = \begin{bmatrix} \frac{\partial f_x}{\partial x} & \frac{\partial f_x}{\partial y} & \frac{\partial f_x}{\partial z} \\ \frac{\partial f_y}{\partial x} & \frac{\partial f_y}{\partial y} & \frac{\partial f_y}{\partial z} \\ \frac{\partial f_z}{\partial x} & \frac{\partial f_z}{\partial y} & \frac{\partial f_z}{\partial z} \end{bmatrix}$$

- $\mathbf{J}$는 디포머의 **국소 선형 근사** — 각 점에서의 선형 변환
- 변형된 탄젠트: $\mathbf{t}' = \mathbf{J} \cdot \mathbf{t}$
- 변형된 노멀: $\mathbf{n}' = (\mathbf{J}^{-1})^T \cdot \mathbf{n}$ 또는 $\mathbf{n}' = \text{normalize}(\mathbf{J}^T \cdot \mathbf{n})$의 특수 경우

### 구체적 예시: Twist 디포머

$y$축 중심 트위스트, 각도가 $y$에 비례:
$$\mathbf{f}(x,y,z) = \begin{pmatrix} x\cos(\theta y) - z\sin(\theta y) \\ y \\ x\sin(\theta y) + z\cos(\theta y) \end{pmatrix}$$

야코비 행렬:
$$\mathbf{J} = \begin{bmatrix} \cos\theta y & -\theta(x\sin\theta y + z\cos\theta y) & -\sin\theta y \\ 0 & 1 & 0 \\ \sin\theta y & \theta(x\cos\theta y - z\sin\theta y) & \cos\theta y \end{bmatrix}$$

야코비의 편미분 항들 중 많은 부분이 좌표 변환 계산에서 이미 계산된 것을 재사용할 수 있어 효율적.

### 디포머 체이닝
여러 디포머를 순차 적용할 때:
$$\mathbf{J}_{total} = \mathbf{J}_n \cdot \mathbf{J}_{n-1} \cdots \mathbf{J}_1$$
야코비 행렬의 곱으로 전체 변환의 노멀을 정확히 계산 가능.

## 수식 및 알고리즘

### 노멀 변환 (일반적 경우)
$$\mathbf{n}' = \text{normalize}\left((\mathbf{J}^{-1})^T \cdot \mathbf{n}\right)$$

### Lattice(FFD) 디포머
$4 \times 4 \times 4$ 격자의 Bernstein 다항식 기반:
$$\mathbf{f}(\mathbf{s}) = \sum_{i,j,k} B_i(s_x) B_j(s_y) B_k(s_z) \cdot \mathbf{P}_{ijk}$$
- $B_i$: 3차 Bernstein 기저 함수
- $\mathbf{P}_{ijk}$: 컨트롤 포인트
- 명령어 수가 많지만 야코비 방법이 유한 차분보다 여전히 효율적

## UE5 관점에서의 활용
- UE5의 **Skeletal Mesh Deformation**: 본 기반 스키닝도 디포머의 일종 (GPU 스키닝)
- **Morph Targets / Blend Shapes**: GPU에서 보간 처리
- UE5 **Geometry Cache**: 사전 계산된 메시 애니메이션 재생
- **Control Rig / Full Body IK**: 프로시저럴 변형의 현대적 구현
- 현대적 대안:
  - **Compute Shader 기반 변형**: 버텍스 셰이더 제약 없이 자유로운 구현
  - **Mesh Shader (DX12 Ultimate)**: 증폭 셰이더로 토폴로지 변경도 가능
  - **Physics-based Deformation**: Position-Based Dynamics (PBD)
- 야코비 행렬을 통한 노멀 계산은 **프로시저럴 메시 변형**에서 여전히 유효한 기법

## 핵심 요약 (3줄)
1. GPU 디포머는 각 정점을 독립적으로 변형하므로 버텍스 셰이더에 완벽히 적합하며, Bend/Twist/Lattice 등을 실시간 처리할 수 있다.
2. 변형 후 노멀 계산에 야코비 행렬을 사용하면 유한 차분법보다 정확하고, 기존 계산을 재활용하여 효율적이다.
3. 현대에는 Compute/Mesh Shader로 더 유연한 변형이 가능하지만, 야코비 기반 노멀 계산은 프로시저럴 변형의 핵심 수학으로 남아있다.
