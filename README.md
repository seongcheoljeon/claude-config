# claude-config

내 Claude Code 환경(플러그인 · 전역 설정 · 지침/메모리)을 새 PC에서 그대로 재현하는 번들.
**MCP 서버는 제외** — 각 PC에서 다시 인증해야 함.

## 사전 조건

새 PC에 **Claude Code(`claude` CLI)가 이미 설치**되어 있어야 함.
→ https://docs.claude.com/en/docs/claude-code

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

1. 마켓플레이스 등록 + 플러그인 4개 설치 (context-mode, andrej-karpathy-skills, claude-dashboard, ponytail)
2. `~/.claude/settings.json` · `settings.local.json` 배치 (statusLine 경로 자동 탐색)
3. `~/.claude/hooks/` 배치 — SessionStart 훅 (context-mode 플러그인 캐시 자가복구)
4. `~/.claude/CLAUDE.md` 배치 — **어느 폴더에서 실행하든 항상 적용되는 전역 지침**
5. 메모리/지침을 `~/.claude/projects/<home>/memory/` 에 배치 (HOME에서 실행 시 로드 + 자가 갱신)

기존 `settings*.json` / `CLAUDE.md` 는 `*.bak.<타임스탬프>` 로 자동 백업됨.

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

- **계정** — claude.ai 커넥터. 같은 계정으로 로그인하면 목록에 자동으로 나타나고,
  새 PC에서 `/mcp` 로 OAuth 재인증만 하면 됨. 토큰은 이 repo에 없음(있어서도 안 됨).
- **플러그인** — context-mode 플러그인 설치 시 자동 등록. 별도 작업 불필요.
- 현재 목록 확인: `claude mcp list`

## 참고

- statusLine 경로가 자동 탐색되지 않으면, Claude Code에서 `/claude-dashboard:update` 한 번 실행.
