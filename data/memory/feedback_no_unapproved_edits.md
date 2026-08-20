---
name: feedback-no-unapproved-edits
description: 파일 수정은 사용자의 명시적 승인 후에만 — 특히 빌드 스크립트
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 211674b5-2115-4ddb-8483-2aa081c4df99
---

수정을 제안하고 "바꿔줄까?"라고 물었으면, 사용자가 명시적으로 승인하기 전에는 절대 파일을 수정하지 않는다. 사용자가 다른 말을 이어가는 것은 승인이 아니다. (2026-06-10, ProjectGray Cooking.bat을 승인 없이 수정했다가 "왜 함부로 바꿔??"라는 강한 질책을 받고 원복함.)

**Why:** 빌드/쿠킹 스크립트는 [[project-projectgray-dual-workspace]] 같은 실제 파이프라인에서 돌아가는 파일이라, 임의 수정이 진행 중인 작업을 깨뜨릴 수 있다. 사용자는 변경 통제를 중요하게 여긴다.

**How to apply:** 진단·제안까지만 하고 diff를 보여준 뒤 멈춘다. "적용해", "바꿔줘" 같은 명시적 요청이 있을 때만 Edit를 실행한다.
