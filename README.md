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

1. 마켓플레이스 등록 + 플러그인 3개 설치 (context-mode, andrej-karpathy-skills, claude-dashboard)
2. `~/.claude/settings.json` · `settings.local.json` 배치 (statusLine 경로 자동 탐색)
3. `~/.claude/CLAUDE.md` 배치 — **어느 폴더에서 실행하든 항상 적용되는 전역 지침**
4. 메모리/지침을 `~/.claude/projects/<home>/memory/` 에 배치 (HOME에서 실행 시 로드 + 자가 갱신)

기존 `settings*.json` / `CLAUDE.md` 는 `*.bak.<타임스탬프>` 로 자동 백업됨.

## 참고

- statusLine 경로가 자동 탐색되지 않으면, Claude Code에서 `/claude-dashboard:update` 한 번 실행.
- MCP 서버(Slack/Notion 등)는 이 번들에 포함되지 않음 — 새 PC에서 재인증 필요.
