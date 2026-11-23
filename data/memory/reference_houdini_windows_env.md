---
name: houdini-windows-env
description: "Houdini는 Windows 쪽 설치(21.0.559/22.0.368), WSL에서 interop로 제어 — uv.exe, MCP bridge 경로"
metadata:
  node_type: memory
  type: reference
  originSessionId: ae2bed8b-ed05-4051-9bd8-e1b336d00dea
  modified: 2026-11-05T03:44:02.908Z
---

- Houdini 설치: `C:\Program Files\Side Effects Software\Houdini 22.0.368`, `Houdini 21.0.559`. prefs: `C:\Users\admin\Documents\houdini22.0`
- WSL2 networkingMode=mirrored (WSL localhost = Windows localhost)
- Windows uv: `C:\Program Files\Python313\Scripts\uv.exe`. Windows에 ffmpeg 없음
- Houdini MCP: JTCHE/houdini-mcp (`houdini-mcp-server` 0.8.1)를 Windows uv tool로 설치(2026-11-05). bridge: `/mnt/c/Users/admin/.local/bin/houdinimcp-bridge.exe`를 WSL Claude Code에 stdio로 등록. 플러그인은 127.0.0.1에만 bind
- auto mode classifier가 `houdinimcp-install.exe`(외부 코드가 Houdini prefs에 기록) 실행을 차단함 → 사용자가 `!`로 직접 실행해야 함
