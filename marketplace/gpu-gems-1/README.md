# gpu-gems-1

NVIDIA *GPU Gems 1* (2004, Addison-Wesley) 42개 챕터의 한글 학습 노트 + 라우터 스킬.

## 다루는 영역

- **자연 시뮬레이션** — 물(Gerstner/caustics), 불, 잔디, 회절, Stable Fluids
- **노이즈/프로시저럴** — Perlin, Voronoi(texture bombing)
- **캐릭터** — 피부 셰이딩, skinning, SSS
- **섀도우** — Volume, PCF, omnidirectional, soft, PSM
- **라이팅/BRDF** — Uberlight, AO, spatial BRDF, IBL
- **포스트프로세스** — Glow, DoF, color grading, bicubic, OpenEXR
- **GPGPU/파이프라인** — 스트림 프로세싱, 볼륨 렌더링, 디포머
- **레거시 도구** ⚠️ — FX Composer, RenderMan interop, register combiner (참고용)

## 자동 트리거

다음 키워드를 포함한 질문에 자동 활성화:
- 알고리즘 이름: "Gerstner wave", "Perlin noise", "Stable Fluids", "PCF", "PSM", "SSS", "depth of field"
- 영역명: "subsurface scattering", "ambient occlusion", "image-based lighting", "shadow volume"
- 한글: "물 시뮬레이션", "그림자 볼륨", "표면 산란", "이미지 기반 조명", "회절 시뮬레이션"

## 명시적 호출

```text
/gpu-gems-1
```

## 함께 사용하면 좋은 plugin

- `gpu-fluid-sim` — Stable Fluids/MacCormack/BFECC 현대 구현 (UE5 Niagara/Houdini Pyro)
- `ue5-shaders` — GPU Gems 알고리즘을 UE5 Engine/Shaders 트리에 매핑
- `unreal-dev-kb` — UE5 시각화/디버깅 cvar
- `hdk-reference` — Houdini HDK 알고리즘 적용
- `ue5-rdg` — UE5 RDG C++ 패스에서 셰이더 호출

## 구조

```text
gpu-gems-1/
├── .claude-plugin/plugin.json
├── skills/gpu-gems-1/
│   ├── SKILL.md             ← 라우팅 테이블 (42챕터 → 11그룹)
│   └── chapters/            ← ch01~ch42.md 한글 학습 노트
└── README.md
```

## 한계

- GPU Gems 1은 2004년 출간 — 일부 구현 디테일(pbuffer, register combiner, FX Composer, Cg, RenderMan interop)은 obsolete
- 알고리즘 아이디어 자체는 여전히 유효, 현대 API(D3D12/Vulkan/UE5/Metal)로 재해석 필요
- 레거시 챕터(ch27, ch30-31, ch33, ch36)는 SKILL.md에서 ⚠️ 명시
