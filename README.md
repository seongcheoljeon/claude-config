# ClaudeSkills

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
├── *.skill                           ← (레거시 ZIP 패키지, 백업용 보존)
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

| 영역 | 관련 플러그인 | 차이 |
|---|---|---|
| **RDG** | `unreal-dev-kb` (cvar 카탈로그) + `ue5-rdg` (API 패턴) | 카탈로그 vs 코드 작성 패턴 |
| **셰이더** | `unreal-dev-kb` (Shader Compiler cvar) + `ue5-shaders` (HLSL 트리) | cvar vs 셰이더 코드 자체 |
| **머티리얼** | `unreal-dev-kb` (HLSL Custom Node) + `ue5-shaders` (Material translator) | Custom Node vs 엔진 셰이더 |
| **코딩** | `ue5-coding-convention` (C++ 스타일) | 단독 |
| **GPU 시뮬** | `gpu-fluid-sim` (알고리즘) | 단독 |
| **Houdini** | `hdk-reference` (C++ HDK) | 단독 |

→ 영역 겹치는 플러그인은 **함께 사용**하면 시너지 (cvar 추천 + 코드 패턴 동시 제공).

## 갱신 / 유지보수

엔진/도구 버전 업그레이드 시:

1. 해당 플러그인의 SKILL.md 또는 부속 .md 파일 갱신
2. `plugin.json`의 `version` bump
3. `.claude-plugin/marketplace.json`의 해당 항목 `version` bump
4. Git commit + push
5. 다른 PC에서: `git pull` + `claude plugin update <plugin-name>`

## 레거시 `.skill` 파일

기존 ZIP 형식 `.skill` 파일 (5개)은 **백업용으로 보존**:
- `gpu-fluid-sim.skill`
- `hdk-reference.skill`
- `ue5-coding-convention.skill`
- `ue5-rdg.skill`
- `ue5-shaders.skill`

이 파일들은 압축 해제되어 위의 plugin 디렉토리로 이전됨. 향후 안정성 확인 후 삭제 가능.

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
