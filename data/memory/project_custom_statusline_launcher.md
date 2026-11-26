---
name: custom-statusline-launcher
description: "statusLine은 자작 런처(~/.claude/hooks/dashboard-statusline.mjs, bun) — /claude-dashboard:update의 shim 덮어쓰기 금지"
metadata:
  node_type: memory
  type: project
  originSessionId: 2af0e301-c26a-4822-9ae5-a20685e4db53
  modified: 2026-11-24T07:27:29.082Z
---

settings.json `statusLine.command` = `bun "~/.claude/hooks/dashboard-statusline.mjs"`. claude-dashboard 최신 버전을 런타임에 찾아 실행하고(버전 무관, plugin shim과 같은 역할) 첫 줄 앞에 ponytail 배지를 붙인다.

**Why:** `/claude-dashboard:update` 2단계는 statusLine을 plugin shim(`plugins/data/claude-dashboard-claude-dashboard/statusline.mjs`)으로 무조건 덮어써서 ponytail 배지가 사라진다.
**How to apply:** update 명령이 와도 2단계는 건너뛰고, 3단계(해석될 빌드 확인)와 런처 실행 테스트만 한다. 덮어쓰려면 먼저 사용자에게 묻는다.
