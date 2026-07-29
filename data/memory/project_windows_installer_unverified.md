---
name: windows-installer
description: install.ps1 은 2026-07-29 기준 Windows 에서 한 번도 실행/문법검증되지 않음 — 첫 실행 시 확인 필요
metadata: 
  node_type: memory
  type: project
  originSessionId: 3c43bfcb-9cfe-4906-9656-168881ccb5ed
  modified: 2026-07-29T14:29:03.367Z
---

`install.ps1` 의 `Prune-Baks`, `Link-Mem`, 스킬 junction 블록은 2026-07-29 에
macOS 에서 작성됐고 **PowerShell 파서로도 검증되지 않았다**(작업 머신에 `pwsh` 없음).
`install.sh` 와 1:1 대응해 작성했을 뿐이다.

**Why:** bash 쪽은 `bash -n` + 실제 실행으로 검증했지만 PowerShell 쪽은 근거가 없다.
검증되지 않은 것을 검증된 것처럼 취급하면 새 PC 셋업이 조용히 반쯤 깨진다.

**How to apply:** Windows 에서 `powershell -ExecutionPolicy Bypass -File .\install.ps1`
첫 실행 시 — 출력에 `스킬 junction`, `메모리 junction` 두 줄이 나오는지 확인.
의심 지점: (1) PS 5.1 은 `DirectoryInfo.Target` 이 없어 링크 재생성으로 폴백,
(2) 경로에 공백("Unreal Projects")이 섞일 때 `cmd /c mklink /J` 인용,
(3) `Prune-Baks` 의 `Sort-Object Name -Descending` 은 타임스탬프 이름 정렬에 의존.
확인 후 이 메모리는 삭제할 것. 관련: [[user-role]]
