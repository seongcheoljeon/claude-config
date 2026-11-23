---
name: user-no-codex
description: Codex(OpenAI CLI) 사용 중단 — 2026-11-23 WSL/Windows 양쪽에서 완전 제거함
metadata:
  node_type: memory
  type: user
  originSessionId: c8ef4a14-8bf8-44af-af1d-22fa3e336587
  modified: 2026-11-23T09:03:47.304Z
---

2026-11-23에 Codex 사용을 그만두고 WSL과 Windows 양쪽에서 다 지웠다. 대시보드 codexUsage 위젯은 `~/.codex/auth.json`이 없으면 자동으로 숨겨진다.

**Why:** 사용자가 "이제 코덱스 사용 안 함"이라고 하고 전부 지워달라고 함.
**How to apply:** Codex 설치, 설정, 연동은 제안하지 말 것. 멀티 CLI 예시도 Claude 기준으로. 단, Orca의 codex-hook.cmd와 `~/.orca-wsl` 릴레이는 Orca 소유라서 일부러 남겨둠.
