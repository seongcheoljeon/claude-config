---
name: project-projectgray-dual-workspace
description: ProjectGray(회사 UE 프로젝트)에서 런처 엔진과 source 빌드 엔진을 병행하기 위한 A/B 워크스페이스 + git 브리지 + SVN 마스터 구성
metadata:
  type: project
  originSessionId: 0406682b-7864-40fa-97af-4bd981de1dba
modified: 2026-08-10T09:51:48.334Z
---
회사 프로젝트 `ProjectGray`는 팀 표준이 Epic Launcher 설치본. 팀 VCS는 **SVN**. 개인 작업용으로 엔진 private 코드 디버깅이 필요해서 GitHub source 빌드를 병행.

**버전 이력:** 2026-04 시점 5.7.4 → 2026-08-10 확인 시 **5.8.1**로 이행 완료 (A 워크스페이스 `.uproject` EngineAssociation = `"5.8"`, 런처 `C:\Program Files\Epic Games\UE_5.8` = 5.8.1 / CL 56057345). Source 클론은 `C:\Users\admin\source\repos\UnrealEngine` (origin = EpicGames/UnrealEngine, fork 아님, 로컬 엔진 수정 없음), 레지스트리 등록 GUID `{238203FC-4C26-BDDF-3534-95A6FFCAF357}`는 **경로 기준**이라 엔진 버전을 올려도 유지됨 → B의 `.uproject`는 손댈 필요 없음.

**Why:** 엔진 private 코드 스텝인은 source 빌드에서만 가능. 그러나 `.uproject`의 `EngineAssociation`이 팀 표준(현재 `"5.8"`)과 달라지면 SVN에 올라가는 순간 팀 전원의 빌드가 깨짐. 또한 엔진 수정 후 DLL만 배포하면 BuildId/ABI 불일치로 팀원 PC에서 로드 실패.

**How to apply:**
- 듀얼 워크스페이스 채택:
  - **A** (`D:\source\ProjectGray`): 런처 엔진 바인딩, SVN 작업 사본, 팀과 완전 호환. 최종 `svn commit`은 A에서만.
  - **B** (`D:\source\ProjectGray_for_source`): Source 엔진 바인딩, SVN full checkout (에셋 10GB+ 포함), 개인 디버깅 전용.
- 중간 경유 bare repo: `D:\source\ProjectGray.git` — A/B가 코드를 git으로 주고받음.
- `.uproject` 격리: B 쪽은 git `skip-worktree` + SVN `ignore-on-commit` changelist 이중 방어. `EngineAssociation`은 source 빌드 GUID 로컬 전용.
- 에셋(`Content/`, `Plugins/*/Content/`)은 SVN 전담, git에서 제외. 에셋 편집은 **항상 A**에서 (B에서 엔진 수정했을 경우 직렬화 호환 깨질 수 있음).
- 코드 흐름: B 디버깅/수정 → git push(bare) → A git pull → A 런처 엔진 빌드 검증 → A `svn commit`.
- A의 SVN→git 동기화는 수동 (`svn update` 후 `git add && git commit && git push`).
- 두 워크스페이스 에디터 동시 실행 금지. DDC 공유 설정으로 셰이더 재컴파일 중복 제거 가능.
- 상세 런북: `/home/seongcheoljeon/.claude/plans/lucky-knitting-cherny.md`.

**주의:** 엔진 수정 실험 중에는 B에서 에셋 저장하지 말 것. UPROPERTY 추가 등이 있으면 A(런처)에서 해당 에셋 로드 실패 가능.
