# ClaudeSkills

> Marketplace ID: `claude-skills-jsc` · Version: 1.1.0

Seongcheol Jeon의 Claude Code 플러그인 마켓플레이스. UE5 / Houdini / HDK / GPU 시뮬레이션 작업용 6개 플러그인.

## 플러그인 목록

| 플러그인 | 설명 | 카테고리 |
|---|---|---|
| [unreal-dev-kb](unreal-dev-kb/) | UE 셰이더/렌더링 cvar/매크로/명령 카탈로그 약 2,000+ 항목 (9개 영역) | reference |
| [ue5-rdg](ue5-rdg/) | UE5 Render Dependency Graph 전문 레퍼런스 | reference |
| [ue5-shaders](ue5-shaders/) | UE 5.7.4+ Engine/Shaders HLSL 트리 레퍼런스 | reference |
| [ue5-coding-convention](ue5-coding-convention/) | UE5 C++ 코딩 컨벤션 | workflow |
| [gpu-fluid-sim](gpu-fluid-sim/) | GPU Eulerian Fluid Simulation 가이드 (UE5/Houdini) | reference |
| [hdk-reference](hdk-reference/) | Houdini 21.0 HDK C++ 레퍼런스 | reference |

## 설치 방법

### 옵션 1: Claude Code Marketplace (권장)

```bash
# 마켓플레이스 추가 (한 번만)
claude plugin marketplace add /mnt/c/Users/admin/source/repos/ClaudeSkills
# Windows 경로 직접: claude plugin marketplace add C:\Users\admin\source\repos\ClaudeSkills

# 원하는 플러그인 설치
claude plugin install unreal-dev-kb@claude-skills-jsc
claude plugin install ue5-rdg@claude-skills-jsc
claude plugin install ue5-shaders@claude-skills-jsc
claude plugin install ue5-coding-convention@claude-skills-jsc
claude plugin install gpu-fluid-sim@claude-skills-jsc
claude plugin install hdk-reference@claude-skills-jsc

# 모두 활성화
/reload-plugins
```

### 옵션 2: Git Clone (다른 PC)

```bash
# 1. 저장소 clone
git clone <repo-url> ~/source/repos/ClaudeSkills

# 2. 마켓플레이스 추가
claude plugin marketplace add ~/source/repos/ClaudeSkills

# 3. 플러그인 설치 (위 옵션 1과 동일)
```

## 디렉토리 구조

```text
ClaudeSkills/
├── .claude-plugin/
│   └── marketplace.json              ← 6개 플러그인 등록
├── unreal-dev-kb/                    ← 플러그인
│   ├── .claude-plugin/plugin.json
│   ├── skills/unreal-dev-kb/
│   │   ├── SKILL.md
│   │   └── notes/                    ← 9개 .md 노트
│   └── README.md
├── ue5-rdg/
│   ├── .claude-plugin/plugin.json
│   └── skills/ue5-rdg/
│       ├── SKILL.md
│       └── references/               ← 추가 레퍼런스 .md
├── ue5-shaders/
│   ├── .claude-plugin/plugin.json
│   └── skills/ue5-shaders/
│       ├── SKILL.md
│       ├── api.md
│       ├── catalog.md
│       ├── defines.md
│       ├── flows/
│       └── quirks.md
├── ue5-coding-convention/
│   ├── .claude-plugin/plugin.json
│   └── skills/ue5-coding-convention/SKILL.md
├── gpu-fluid-sim/
│   ├── .claude-plugin/plugin.json
│   └── skills/gpu-fluid-sim/SKILL.md
├── hdk-reference/
│   ├── .claude-plugin/plugin.json
│   └── skills/hdk-reference/SKILL.md
└── README.md
```

## 자동 트리거

각 플러그인의 `SKILL.md` description에 키워드가 등록되어 있어, 사용자 질문에 매칭되면 자동 활성화:

| 플러그인 | 트리거 키워드 (일부) |
|---|---|
| unreal-dev-kb | "셰이더 cvar", "Lumen 디버깅", "Niagara cvar", "RenderDoc", "Custom Node", "RDG cvar 추천" |
| ue5-rdg | "FRDGBuilder", "AddPass", "RDG 패스 작성", "Compute Pass" |
| ue5-shaders | "BasePass", "Vertex Factory", "Substrate", "Lumen 셰이더", "Nanite 셰이더" |
| ue5-coding-convention | "UE5 C++ 작성", "check 매크로", "UPROPERTY 명명" |
| gpu-fluid-sim | "Navier-Stokes", "Stable Fluids", "Pyro", "Gas OpenCL", "smoke simulation" |
| hdk-reference | "Houdini HDK", "SOP plugin", "VEX", "DSO" |

## 플러그인 간 영역 관계

각 plugin은 **다른 관점**을 다루며, 영역명이 같아 보여도 정보 종류가 다름:

| 영역 | 관련 플러그인 | 다루는 정보 차이 |
|---|---|---|
| **RDG** | `unreal-dev-kb` + `ue5-rdg` | cvar (debug 옵션) vs C++ API 코드 패턴 |
| **셰이더** | `unreal-dev-kb` + `ue5-shaders` | 컴파일러 cvar vs HLSL 코드 자체 |
| **머티리얼** | `unreal-dev-kb` + `ue5-shaders` | Custom Node 헬퍼 vs 엔진 Material translator |
| **코딩 스타일** | `ue5-coding-convention` | 단독 영역 |
| **GPU 시뮬** | `gpu-fluid-sim` | 단독 영역 (UE/Houdini 양쪽 적용) |
| **Houdini** | `hdk-reference` | 단독 영역 |

## 시나리오별 plugin 조합 매트릭스

작업 상황별로 **어떤 plugin이 자동 활성화되는지** + **무엇을 묻기 좋은지**:

| 작업 상황 | 활성화 plugin | 사용 예시 |
|---|---|---|
| RDG 패스 신규 작성 | `ue5-rdg` + `unreal-dev-kb` | "Compute Pass 작성 + ImmediateMode 디버깅 cvar" |
| RDG 패스 크래시 디버깅 | `unreal-dev-kb` (+ `ue5-rdg`) | "RDG lambda에서 죽는데 cvar 셋?" |
| 엔진 셰이더 코드 분석 | `ue5-shaders` (+ `unreal-dev-kb`) | "BasePass HLSL 어디 정의돼? Substrate 분기는?" |
| Lumen GI 디버깅 | `unreal-dev-kb` + `ue5-shaders` | "Lumen visualize cvar + HLSL 흐름" |
| Niagara 이펙트 작업 | `unreal-dev-kb` (+ `gpu-fluid-sim`) | "Niagara Solo 모드 + GPU Grid fluid 알고리즘" |
| 머티리얼 Custom Node | `unreal-dev-kb` (+ `ue5-shaders`) | "Custom Node에서 ScreenPosition + MaterialTemplate" |
| UE5 신규 클래스 작성 | `ue5-coding-convention` (+ `unreal-dev-kb`) | "UCLASS 명명 + 데이터 검증 패턴" |
| GPU 프로파일링 | `unreal-dev-kb` | "stat gpu vs ProfileGPU 차이" |
| RenderDoc/PIX 캡처 | `unreal-dev-kb` | "RenderDoc 캡처 명령 + 셰이더 이름 표시 cvar" |
| 메모리 누수 추적 | `unreal-dev-kb` | "memreport 명령 + r.MemReport.* 옵션" |
| Houdini SOP plugin | `hdk-reference` | "newSopOperator 진입점 + Data ID 관리" |
| Houdini Pyro/Gas | `hdk-reference` + `gpu-fluid-sim` | "Gas OpenCL DOP에서 Stable Fluids 구현" |
| GPU Fluid Sim (UE5) | `gpu-fluid-sim` + `ue5-rdg` (+ `unreal-dev-kb`) | "Niagara Grid2D로 Pyro 포팅 + Compute Pass + 셰이더 cvar" |

→ 자동 트리거가 정확하지 않으면 명시적 호출: `/<plugin-name>` 또는 "<plugin-name> 사용해서 ..."

## 명시적 트리거 (자동 트리거 우회)

특정 plugin만 활성화하고 싶을 때:
```text
/unreal-dev-kb        # 마켓플레이스 prefix 없는 짧은 형식
/ue5-rdg
```

또는 자연어:
```text
"unreal-dev-kb 사용해서 Lumen 시각화 명령 알려줘"
```

## 갱신 / 유지보수

엔진/도구 버전 업그레이드 시:

1. 해당 플러그인의 SKILL.md 또는 부속 .md 파일 갱신
2. `plugin.json`의 `version` bump (예: 1.1.0 → 1.1.1)
3. `.claude-plugin/marketplace.json`의 해당 항목 `version` bump
4. Git commit + push
5. 다른 PC에서: `git pull` + `claude plugin update <plugin-name>`

## 변경 이력

### v1.1.0 (2026-04-30)
- SKILL.md description 압축 (트리거 정확도 ↑) — 6개 plugin
- 각 SKILL.md에 "협력 plugin" 섹션 추가 (시너지 가이드)
- 마스터 README에 시나리오별 plugin 조합 매트릭스 추가
- 단일 SKILL.md plugin 3개에 README 추가 (ue5-coding-convention, gpu-fluid-sim, hdk-reference)
- 레거시 `.skill` ZIP 패키지 제거 (이미 plugin으로 변환됨)

### v1.0.0 (2026-04-30)
- 6개 plugin 표준 marketplace 구조로 변환
- `unreal-dev-kb` 신규 추가 (UE5 cvar/매크로 카탈로그 약 2,000+ 항목)
- 기존 `.skill` 5개를 plugin 디렉토리로 압축 해제

## 다른 PC 셋업 가이드

### Windows (네이티브)
```cmd
cd C:\Users\<user>\source\repos
git clone <repo-url> ClaudeSkills
claude plugin marketplace add C:\Users\<user>\source\repos\ClaudeSkills
```

### WSL / Linux / Mac
```bash
cd ~/source/repos  # 또는 원하는 위치
git clone <repo-url> ClaudeSkills
claude plugin marketplace add ~/source/repos/ClaudeSkills
```

이후 `claude plugin install <name>@claude-skills-jsc`로 원하는 플러그인 설치.

## 라이선스

MIT License

## 작성자

Seongcheol Jeon (`seongcheoljeon@mistilgames.com`)
