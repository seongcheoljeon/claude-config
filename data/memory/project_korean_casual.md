---
name: project-korean-casual
description: "KoreanCasual — UE5 모바일 한국어 학습 앱(글로벌 K-팬 타겟), BlindDate와 MistilCommonCore plugin 공유"
metadata: 
  node_type: memory
  type: project
  originSessionId: 828fafbd-d707-4ed9-8132-cb635cda9053
---

UE5 5.7+ 기반 글로벌 한국어 학습 캐주얼 모바일 앱 (iOS/Android). 타겟은 K-pop·K-drama 친숙층 외국인.

**Why:** 듀오링고류 2D 학습이 못 살리는 K-콘텐츠 공간감·캐릭터 몰입을 UE5 3D 아바타로 차별화. 글로벌 한국어 학습 수요 상승세.

**How to apply:**
- 신규 UE5 프로젝트라 한국어로 묻거나 작성할 때 이 앱과 [[project-dating-app]](BlindDate) 둘 중 어느 쪽 컨텍스트인지 먼저 구분
- 공통 인프라(Supabase, Avatar, Auth, CommonUI)는 `MistilCommonCore` plugin으로 두 앱이 공유 — 한 쪽에만 코드 추가 제안 금지, plugin 적합성부터 검토
- MVP 범위: 한글 자모 학습 + K-카페 시나리오 1개. 듀오링고 트리 흉내 제안 금지
- LLM은 프리미엄만, 무료층은 스크립트 분기. STT는 온디바이스 Whisper.cpp tiny
- 실행 계획 파일: `~/.claude/plans/unreal-engine-snug-milner.md`
- WSL 사전 산출물 위치: `~/KoreanCasual_Starter/` (Windows로 이전 예정)
- 실제 UE5 빌드/실행은 Windows 호스트에서. WSL은 코드·문서·데이터 작성 전용
