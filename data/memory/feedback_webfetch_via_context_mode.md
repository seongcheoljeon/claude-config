---
name: feedback-webfetch-via-context-mode
description: WebFetch 대신 처음부터 ctx_fetch_and_index 사용 (context-mode hook이 WebFetch를 차단함)
metadata:
  node_type: memory
  type: feedback
  originSessionId: bec98b07-9e12-4b7f-a282-cba3712af9c0
  modified: 2026-11-03T07:26:53.267Z
---

웹 페이지 가져올 땐 WebFetch 말고 처음부터 `mcp__plugin_context-mode_context-mode__ctx_fetch_and_index` 사용. WebSearch는 그대로 써도 됨.

**Why:** context-mode 플러그인 PreToolUse hook이 WebFetch를 deny하고 리다이렉트해서 "hook error"가 매번 뜸. 사용자가 이를 에러로 인식했고, 리다이렉트는 유지하기로 결정(2026-11-03).

**How to apply:** URL 내용이 필요하면 ToolSearch로 ctx_fetch_and_index 로드 → 호출 → ctx_search로 필요한 부분만 조회.
