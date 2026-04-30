# unreal-dev-kb

UnrealEngine 개발자 지식 베이스 — Claude Code Plugin

## 소개

UE 셰이더/렌더링/머티리얼/이펙트/디버깅 작업 시 정확한 cvar/매크로/명령을 즉시 제공하는 Claude Code 플러그인입니다.

**약 2,000+ 카탈로그 항목**을 9개 영역으로 정리:

| 영역 | 항목 수 | 주요 cvar 접두어 |
|---|---|---|
| RDG (Render Dependency Graph) | cvar 31 + 매크로 21 | `r.RDG.*` |
| Shader Compiler | cvar 165 | `r.Shaders.*`, `r.ShaderCompiler.*` |
| Material 시스템 | cvar 28 | `r.Material*` |
| Niagara FX | cvar 327 | `fx.Niagara.*` |
| GPU 디버깅 | cvar 48 + 명령 3 | `renderdoc.*`, `r.DumpGPU.*` |
| 렌더링 파이프라인 | 핵심 180 (전체 705+) | `r.Lumen.*`, `r.Nanite.*`, `r.RayTracing.*`, `r.Shadow.Virtual.*` |
| Profiling / Stats | stat 110 + cvar/명령 105 | `r.ProfileGPU.*`, `csv.*`, `Trace.*` |
| Visualization | ShowFlag 180 + ViewMode 36 + 기타 70 | `r.Visualize*`, `viewmode`, `vis` |
| HLSL Custom Node | 멤버/함수/매크로 180 | (HLSL 헬퍼 함수, Parameters 멤버) |

모든 cvar는 **소스 빌드 엔진에서 직접 추출** (추정 X, 코드 기반 O).

## 설치 (다른 PC)

### 옵션 1: Claude Code Marketplace로 설치 (권장)

```bash
# 로컬 디렉토리를 마켓플레이스로 추가
claude plugin marketplace add /path/to/ClaudeSkills/unreal-dev-kb

# 플러그인 설치
claude plugin install unreal-dev-kb@unreal-dev-kb

# 활성화
/reload-plugins
```

### 옵션 2: Git Clone 후 설치

```bash
# 다른 PC에서 동일한 위치로 clone
git clone <repo-url> ~/source/repos/ClaudeSkills

# 마켓플레이스 추가
claude plugin marketplace add ~/source/repos/ClaudeSkills/unreal-dev-kb
claude plugin install unreal-dev-kb@unreal-dev-kb
/reload-plugins
```

### 설치 확인

Claude Code 실행 후:
```text
/plugin
```
→ `unreal-dev-kb`가 목록에 보이면 성공.

또는 다음 질문으로 자동 트리거 테스트:
```text
"RDG 패스 디버깅용 cvar 추천해줘"
```
→ 스킬이 자동 활성화되어 시나리오별 cvar 셋 응답.

## 사용 방법

### 자동 트리거 (대부분의 경우)

다음 키워드를 포함한 질문에 자동 활성화:

- **렌더링**: 셰이더, 머티리얼, RDG, Lumen, Nanite, Ray Tracing, VSM
- **이펙트**: Niagara, fx.*
- **디버깅**: RenderDoc, PIX, RGP, DumpGPU, GPU 크래시
- **프로파일링**: stat gpu, ProfileGPU, CSV, Insights
- **시각화**: ShowFlag, ViewMode, vis, BufferVisualization
- **셰이더 작성**: Custom Node, MaterialTemplate, TangentToWorld, RotateAboutAxis

### 명시적 호출

```text
/unreal-dev-kb
```

또는 자연어로:
```text
"unreal-dev-kb 스킬 사용해서 Lumen 시각화 모드 알려줘"
```

## 디렉토리 구조

```text
unreal-dev-kb/
├── .claude-plugin/
│   ├── marketplace.json       ← 마켓플레이스 메타
│   └── plugin.json            ← 플러그인 메타
├── skills/
│   └── unreal-dev-kb/
│       ├── SKILL.md           ← 스킬 정의 + 트리거
│       └── notes/
│           ├── INDEX.md       ← 마스터 인덱스 (먼저 읽기)
│           ├── rdg-developer-reference.md
│           ├── shader-compiler-reference.md
│           ├── material-reference.md
│           ├── niagara-reference.md
│           ├── gpu-debugging-reference.md
│           ├── rendering-pipeline-reference.md
│           ├── profiling-reference.md
│           ├── visualization-reference.md
│           └── hlsl-custom-node-reference.md
└── README.md
```

## 적용 범위

- **모든 UnrealEngine 5.x 프로젝트** (소스 빌드 + 런처 설치 동일 cvar)
- 추출 시점: UE 5.7 기준
- Shipping 빌드에서 무력화되는 디버그 cvar는 노트에 명시

## 출처

소스 빌드 엔진(`C:\Users\admin\source\repos\UnrealEngine\`)에서 직접 추출:
- `Engine/Source/Runtime/RenderCore/` (RDG)
- `Engine/Source/Developer/ShaderCompiler/` (셰이더)
- `Engine/Source/Runtime/Engine/Private/Materials/` (머티리얼)
- `Engine/Plugins/FX/Niagara/` (Niagara)
- `Engine/Source/Runtime/Renderer/Private/` (Lumen/Nanite/RT/VSM)
- `Engine/Plugins/Developer/RenderDocPlugin/` (RenderDoc)
- `Engine/Source/Runtime/Core/Stats/` (Profiling)
- `Engine/Shaders/Private/MaterialTemplate.ush` (HLSL)

## 갱신

엔진 버전 업그레이드 시 (5.7 → 5.8 등) cvar 추가/제거 가능. 다음 단계로 갱신:

1. 새 엔진 버전에서 cvar 재추출
2. 해당 노트 파일 업데이트
3. `INDEX.md`의 통계 갱신
4. `version` 필드 bump (plugin.json, marketplace.json, SKILL.md)
5. Git commit + push

## 라이선스

MIT License

## 작성자

Seongcheol Jeon (`seongcheoljeon@mistilgames.com`)
