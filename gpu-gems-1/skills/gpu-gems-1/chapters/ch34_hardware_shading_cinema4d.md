# Chapter 34: Integrating Hardware Shading into Cinema 4D
> 저자: Jörn Loviscach (Hochschule Bremen)

## 핵심 개념
- **해결하려는 문제**: 3D DCC 툴(Cinema 4D)에 프로그래머블 하드웨어 셰이딩을 통합하는 방법
- CgFX 툴킷을 활용해 Cinema 4D 플러그인(C4Dfx)으로 구현
- 기존 Gouraud 기반 프리뷰를 **Phong 셰이딩, 범프맵, 섀도우, 환경맵** 수준으로 향상
- 오프라인 렌더러의 셰이딩을 하드웨어로 에뮬레이션하는 접근법
- 지오메트리 처리, 탄젠트/바이노멀 계산, 셰이더 프로그래밍의 실전 문제 해결

## 기술적 세부사항

### C4Dfx 플러그인 아키텍처
- Cinema 4D의 플러그인 API를 통해 OpenGL 렌더링 파이프라인에 개입
- CgFX 프레임워크로 이펙트 파일 로딩 및 렌더링
- 호스트 애플리케이션의 씬 데이터를 셰이더 파라미터에 바인딩

### 탄젠트/바이노멀 계산
- 범프맵/노멀맵에 필수적인 탄젠트 공간(tangent space) 생성
- UV 좌표의 편미분으로부터 탄젠트 벡터 계산:
  - $\mathbf{t} = \frac{\partial \mathbf{P}}{\partial u}$ (탄젠트)
  - $\mathbf{b} = \mathbf{n} \times \hat{\mathbf{t}}$ (바이노멀)
- UV가 직교하지 않는 경우를 위한 대안: $(\mathbf{v} \times \mathbf{n})_0$, $(\mathbf{n} \times \mathbf{u})_0$

### 섀도우 매핑 통합
- 라이트 시점에서 뎁스 맵 렌더링
- 카메라 시점에서 프로젝티브 텍스처로 섀도우 비교
- CgFX의 멀티패스 시스템 활용

### 범프 매핑
- 기존 Cinema 4D의 범프맵을 노멀맵으로 변환
- 커스텀 소프트웨어 셰이더로 노멀을 RGBA로 인코딩
- 탄젠트 공간에서 퍼터베이션 적용

### 멀티패스 렌더링 파이프라인
CgFX의 technique/pass 구조를 활용한 렌더링:
```
technique ShadowedPhong {
    pass ShadowMap {
        // 1st pass: 라이트 시점에서 뎁스 렌더링
        VertexProgram = compile vp40 shadowVP();
        FragmentProgram = compile fp40 shadowFP();
    }
    pass FinalShading {
        // 2nd pass: 카메라 시점에서 최종 렌더링
        // 섀도우맵 + 범프맵 + 환경맵 조합
        VertexProgram = compile vp40 mainVP();
        FragmentProgram = compile fp40 mainFP();
    }
}
```
- Cinema 4D의 단일 패스 OpenGL을 멀티패스로 확장
- 각 pass에서 렌더 타겟, 블렌드 스테이트, 뎁스 스테이트를 개별 제어

### 머티리얼 파라미터 매핑
Cinema 4D의 네이티브 머티리얼 속성 → CgFX 파라미터로의 변환:

| Cinema 4D 속성 | CgFX 시맨틱 | 비고 |
|---------------|------------|------|
| Color | DIFFUSE | diffuse 텍스처 + 색상 |
| Luminance | EMISSIVE | 자체 발광 |
| Reflection | ENVMAP | 큐브맵 반사 |
| Bump | NORMAL | 노멀맵으로 변환 필요 |
| Specular | SPECULARPOWER | 광택 계수 |
| Alpha | OPACITY | 투명도 |

### 성능 고려사항
- 실시간 프리뷰가 목적이므로 오프라인 렌더 품질 100% 재현은 목표가 아님
- 복잡한 씬에서 패널별 렌더링 부하 → 프레임 드롭 시 셰이더 복잡도 자동 조절
- 텍스처 해상도를 프리뷰용으로 축소하여 VRAM 사용 절감

### Gouraud vs CgFX 비교
| 특성 | 기존 Gouraud | C4Dfx (CgFX) |
|------|-------------|--------------|
| 셰이딩 | per-vertex | per-pixel |
| 하이라이트 | 각진 형태 | 매끄러운 Phong |
| 범프맵 | 미지원 | 지원 |
| 섀도우 | 미지원 | Shadow Map |
| 환경맵 | 단순 반사 | 정확한 반사 |

## 수식 및 알고리즘
탄젠트 벡터 계산:
$$\mathbf{t} = \hat{\mathbf{u}}_t, \quad \mathbf{b} = \hat{\mathbf{n}} \times \hat{\mathbf{u}}_t$$

노멀맵 적용 (탄젠트 공간):
$$\mathbf{n}_{perturbed} = T \cdot \mathbf{n}_{tangent}$$
여기서 $T = [\mathbf{t}, \mathbf{b}, \mathbf{n}]$ 은 TBN 행렬

## UE5 관점에서의 활용
- DCC 툴에서의 실시간 프리뷰는 이제 표준 — Maya Viewport 2.0, Blender EEVEE 등
- UE5의 **Datasmith**가 DCC→엔진 간 머티리얼 변환을 자동화
- 탄젠트 공간 계산은 UE5에서도 동일하게 사용 — **MikkTSpace** 표준이 업계 표준
- 현대적 대안: **MaterialX**로 DCC와 실시간 엔진 간 셰이더 호환성 확보
- UE5는 CgFX 대신 **HLSL + Material Graph** 조합으로 동일 기능 제공

## 핵심 요약 (3줄)
1. CgFX 기반 플러그인으로 Cinema 4D에 per-pixel 셰이딩, 범프맵, 섀도우 맵을 통합했다.
2. 탄젠트 공간 생성과 오프라인→실시간 머티리얼 변환이 핵심 기술적 과제다.
3. 현대에는 DCC 실시간 프리뷰가 표준이며, Datasmith/MaterialX가 변환을 자동화한다.
