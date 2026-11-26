---
name: feedback-rm-alias
description: zsh에서 rm이 rm -i alias라서 Bash 도구에서 확인 프롬프트 때문에 조용히 안 지워짐 — command rm 사용
metadata:
  node_type: memory
  type: feedback
  originSessionId: c8ef4a14-8bf8-44af-af1d-22fa3e336587
  modified: 2026-11-26T09:16:05.900Z
---

Bash 도구 셸(zsh)에서 `rm`은 `rm -i` alias다. stdin이 없으면 "remove ...?" 프롬프트가 거절로 끝나서 파일이 안 지워지는데, 종료 코드는 0이라 `&&` 체인도 계속 진행된다. `-rf`를 붙이면 -i가 무시되지만 단일 파일 `rm`에서는 이렇게 실패한다. `cp`도 `cp -i` alias로 확인됨(덮어쓰기 프롬프트 → 복사 안 됨). `mv`도 같을 가능성 높음.

**Why:** 2026-11-23 codex 심링크 삭제가 이 때문에 조용히 실패했다가 검증 단계에서 발견됨. 2026-11-26 claude-config 훅 동기화에서 plain `cp`로 덮어쓰기가 또 조용히 실패(이 메모리가 있었는데도 반복).
**How to apply:** 삭제나 덮어쓰기는 `command rm -f`, `command cp -f`로 하고, 끝나면 `ls`로 실제 결과를 확인할 것.
