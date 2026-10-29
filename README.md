# claude-config

내 Claude Code 환경(플러그인 · 전역 설정 · 지침/메모리)을 새 PC에서 그대로 재현하는 번들.
**MCP 서버는 제외** — 각 PC에서 다시 인증해야 함.

## 사전 조건

새 PC에 다음 **두 가지**가 설치되어 있어야 함 (설치 스크립트가 확인하고 없으면 중단):

1. **Claude Code (`claude` CLI)** → https://docs.claude.com/en/docs/claude-code
2. **Bun** — statusLine·SessionStart 훅·context-mode MCP의 런타임 (Node.js 불필요)
   - macOS/Linux: `curl -fsSL https://bun.sh/install | bash` (macOS는 `brew install oven-sh/bun/bun` 도 가능)
   - Windows: `powershell -c "irm bun.sh/install.ps1 | iex"`

## 실행 방법

이 폴더를 새 PC로 복사한 뒤, OS에 맞는 스크립트 **하나만** 실행.

### macOS / Linux
```bash
cd claude-config
chmod +x install.sh   # git clone 후 실행권한이 없을 수 있으므로 부여
./install.sh
```
> `Permission denied` 가 뜨면 `bash install.sh` 로 실행해도 됨.

### Windows (PowerShell)
```powershell
cd claude-config
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

## 실행하면 되는 일

1. `claude update` — CLI 자체 업데이트
2. 마켓플레이스 등록 + 플러그인 **14개** 설치
   - GitHub 마켓: context-mode, andrej-karpathy-skills, claude-dashboard, ponytail, document-skills(anthropics/skills)
   - 내장 마켓: swift-lsp, clangd-lsp
   - **로컬 마켓 `marketplace/`** (구 ClaudeSkills repo 통합본, claude-skills-jsc):
     unreal-dev-kb, ue5-rdg, ue5-shaders, ue5-coding-convention, gpu-fluid-sim,
     hdk-reference, gpu-gems-1 — **별도 clone 불필요**, repo 안에서 스킬을 직접 수정하면 즉시 반영
3. `~/.claude/settings.json` · `settings.local.json` · `claude-dashboard.local.json` · `keybindings.json` 배치
   - settings.json 의 `__CLAUDE_DIR__`/`__REPO_DIR__` 플레이스홀더를 실제 경로로 치환
   - claude-dashboard.local.json: 상태줄 표시 설정(detailed·한국어) — 이 파일이 없으면
     대시보드가 compact·영어 기본값으로 떠서 OS 간 정보량이 달라진다
4. `~/.claude/hooks/` 배치 — 훅 3개
   - `context-mode-cache-heal.mjs` (SessionStart) — context-mode 플러그인 캐시 자가복구
   - `dashboard-statusline.mjs` (statusLine) — 대시보드 최신 버전을 **매 호출마다** 해석
   - `block-claude-attribution.mjs` (PreToolUse: Bash|PowerShell) — 커밋/PR에 Claude attribution
     (`Co-Authored-By: Claude`, `noreply@anthropic.com` 등) 삽입을 차단. settings.json 의
     `attribution` 빈 값 설정과 함께 이중 차단
5. `~/.claude/CLAUDE.md` 배치 — **어느 폴더에서 실행하든 항상 적용되는 전역 지침**
6. 메모리를 **`data/memory` 로 symlink**(Windows: junction) — HOME 과 이 repo 폴더 두 곳
   - 메모리는 프로젝트 스코프라 폴더마다 경로가 다름. 두 곳 다 링크해야 설정 작업을
     어디서 하든 기존 메모리가 로드되고, 새 메모리가 git 안에 쌓인다.
   - 링크이므로 **이 repo 를 삭제/이동하면 안 됨.** 동기화는 `git pull/push` 가 전부 처리.
7. 레거시 정리 — 구버전 설치가 남긴 `~/.claude/statusline-*.sh`, `install.sh` 사본,
   `settings.json.bak` 삭제 (statusLine 은 이제 dashboard 플러그인 + 래퍼가 담당)

기존 `settings*.json` / `keybindings.json` / `CLAUDE.md` / `memory` 는 `*.bak.<타임스탬프>` 로 자동
백업되고, 원본별 **최신 3개만** 유지된다(재실행마다 누적되는 것을 방지).

## 무엇이 어디까지 적용되는가

| 항목 | 범위 | 로드 시점 |
|---|---|---|
| `CLAUDE.md` 전역 지침 | **모든 폴더** | 매 세션 항상 |
| 플러그인 14개 (user scope) | **모든 폴더** | 매 세션 (스킬은 description 이 맞을 때만) |
| statusLine · SessionStart 훅 · 권한 · theme/voice · keybindings | **모든 폴더** | 매 세션 |
| `memory/` | **HOME + 이 repo 뿐** | 해당 폴더 세션에서만 |

메모리는 Claude Code 설계상 **프로젝트 스코프**다(`projects/<경로치환>/memory/`). 폴더마다
독립적인 게 정상 동작이라 전 폴더 공용화는 하지 않는다 — 프로젝트별 진행상황이 섞이면
오히려 해롭다. 그래서 성격에 따라 자리를 나눈다:

- **항상 적용돼야 하는 지시** → `data/CLAUDE.md`
- **전역이지만 필요할 때만 볼 도메인 지식** → `marketplace/<플러그인>/skills/` (claude-skills-jsc)
- **그 폴더에서만 유효한 진행상황** → 해당 프로젝트의 memory (그대로 둠)

## clangd-lsp — C/C++ 은 `compile_commands.json` 이 있어야 의미가 있다

clangd 는 컴파일 DB에서 include 경로·매크로·`-std` 를 받는다. DB가 없으면 UE 코드는
`*.generated.h` 를 못 찾고 UHT 매크로가 미해석되어 **가짜 진단만 쏟아진다.**

### UE 프로젝트 (검증: UE 5.8.1 런처 설치 + Apple clangd 21, macOS arm64)

```bash
"/Users/Shared/Epic Games/UE_5.8/Engine/Build/BatchFiles/RunUBT.sh" \
  -mode=GenerateClangDatabase \
  -OutputDir="$HOME/Documents/Unreal Projects/<Proj>" \
  -project="$HOME/Documents/Unreal Projects/<Proj>/<Proj>.uproject" \
  <Proj>Editor Mac Development
```
- `-OutputDir=` 를 빼면 **엔진 루트**(`/Users/Shared/Epic Games/UE_5.8/`)에 생성된다.
  clangd 는 소스 파일의 상위 디렉토리에서만 DB를 찾으므로, 프로젝트 코드에 적용하려면
  프로젝트 루트로 출력해야 한다. (`-OutputDir` 은 `-help` 에 안 나오지만 UBT가 받는다)
- 엔진 소스를 열어볼 목적이라면 엔진 루트 쪽 DB도 그대로 두면 된다.
- 헤더/소스가 늘거나 모듈 의존성이 바뀌면 **다시 돌려야** 한다.
- UBT 명령의 엔트리는 `@...rsp` 응답 파일을 참조하는데, clangd 가 이를 펼쳐서 읽는다
  (검증: `clangd --check` 로그에 확장된 플래그가 찍히고 `All checks completed, 0 errors`).
- 생성된 `compile_commands.json` 은 빌드 산출물이므로 `.gitignore` 대상.

### CMake 프로젝트

```bash
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -sf build/compile_commands.json .
```

### 동작 확인

```bash
clangd --check=<파일.cpp> 2>&1 | tail -3     # "All checks completed, N errors"
```

## MCP 서버 (설치 스크립트 대상 아님 — 기록용)

이 번들은 MCP 서버를 **설정하지 않는다.** 아래 서버들은 로컬 설정 파일에 저장되지
않기 때문(`~/.claude.json` 의 모든 `mcpServers` 가 비어 있음) — 스크립트로 재현할
대상 자체가 없다.

| 서버 | 엔드포인트 | 출처 |
|---|---|---|
| claude.ai Slack | `https://mcp.slack.com/mcp` | 계정 |
| claude.ai Notion | `https://mcp.notion.com/mcp` | 계정 |
| claude.ai Asana | `https://mcp.asana.com/v2/mcp` | 계정 |
| claude.ai Miro | `https://mcp.miro.com` | 계정 |
| claude.ai Microsoft 365 | `https://microsoft365.mcp.claude.com/mcp` | 계정 |
| plugin:context-mode | `bun <plugin cache>/start.mjs` | 플러그인 |
| ue-mcp | `npx ue-mcp <UE프로젝트>.uproject` | UE 프로젝트 |

- **계정** — claude.ai 커넥터. 같은 계정으로 로그인하면 목록에 자동으로 나타나고,
  새 PC에서 `/mcp` 로 OAuth 재인증만 하면 됨. 토큰은 이 repo에 없음(있어서도 안 됨).
- **플러그인** — context-mode 플러그인 설치 시 자동 등록. 별도 작업 불필요.
- **UE 프로젝트** — 전역이 아닌 UE 프로젝트 단위. 각 UE 프로젝트 폴더에서
  `npx ue-mcp init` 실행(브리지 플러그인 + 프로젝트 `.mcp.json` 자동 구성, Node 18+,
  UE 5.4–5.8). https://ue-mcp.com/docs/getting-started
- 현재 목록 확인: `claude mcp list`

## 참고

- **statusLine 은 플러그인 버전에 묶여 있지 않다.** `settings.json` 에 캐시 경로를
  박으면(`.../claude-dashboard/1.30.1/dist/index.js`) 플러그인 업데이트로 버전 폴더가
  교체되는 순간 상태줄이 조용히 죽는다. 그래서 래퍼(`hooks/dashboard-statusline.mjs`)가
  실행 시점에 최신 버전을 찾아 위임한다 — `claude plugin update` 후 아무 작업도 필요 없음.
- 래퍼 동작 확인: `./test-statusline.sh`
- 플러그인 업데이트 확인: `claude plugin marketplace update` → `claude plugin list`
