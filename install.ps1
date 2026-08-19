# Claude Code 설정 이식 스크립트 (Windows PowerShell 5.1 / 7 모두 지원)
# - CLI 업데이트, 마켓플레이스(로컬 marketplace\ 포함)·플러그인 14개 설치,
#   settings/keybindings/훅 배치, 전역 CLAUDE.md 배치, 메모리 junction, 레거시 정리
# 실행: powershell -ExecutionPolicy Bypass -File .\install.ps1
#
# 인코딩 정책:
#  - 한글 포함 파일(CLAUDE.md, memory/*.md, settings.local.json)은 Copy-Item으로
#    바이트 그대로 복사 (텍스트 재해석 없음 → mojibake 원천 차단)
#  - 치환이 필요한 settings.json만 [IO.File]::ReadAllText/WriteAllText 사용
#    (.NET 기본이 UTF-8이며, 쓰기는 BOM 없는 UTF-8로 고정)

$ErrorActionPreference = 'Stop'

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Data      = Join-Path $ScriptDir 'data'
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }

Write-Host "==> Claude Code 설정 이식 시작"
Write-Host "    HOME       : $HOME"
Write-Host "    CLAUDE_DIR : $ClaudeDir"

# 0) claude CLI 확인
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Error "'claude' CLI를 찾을 수 없습니다. 먼저 Claude Code를 설치하세요. https://docs.claude.com/en/docs/claude-code"
  exit 1
}

# 0-1) node 확인 (statusLine + SessionStart 훅이 의존. 없으면 조용히 실패하므로 경고)
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Warning "'node' 미발견 - statusLine과 SessionStart 훅이 동작하지 않습니다. Node.js 설치 권장 (설치는 계속 진행)"
}

# 0-2) 백업은 재실행마다 누적되므로 원본별 최신 3개만 남긴다 (파일/디렉토리 공통)
function Prune-Baks([string]$Path) {
  Get-ChildItem -Path "$Path.bak.*" -Force -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -Skip 3 | ForEach-Object {
      Remove-Item $_.FullName -Recurse -Force
      Write-Host "   낡은 백업 삭제: $($_.Name)"
    }
}

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

# 0-3) claude CLI 자체 업데이트 (실패해도 설치는 계속)
try { claude update } catch { Write-Host "   (건너뜀) claude update" }

# 1) 마켓플레이스 등록 + 플러그인 설치 (개별 실패는 무시하고 계속)
Write-Host "==> 마켓플레이스 등록"
# claude-skills-jsc: 이 repo 에 통합된 로컬 마켓플레이스 (marketplace\)
# - 별도 clone 불필요, repo 안에서 스킬을 직접 수정하면 즉시 반영
$localMarket = Join-Path $ScriptDir 'marketplace'
foreach ($m in 'mksglu/context-mode','forrestchang/andrej-karpathy-skills','uppinote20/claude-dashboard','DietrichGebert/ponytail','anthropics/skills',$localMarket) {
  try { claude plugin marketplace add $m } catch { Write-Host "   (건너뜀) marketplace add $m" }
}
Write-Host "==> 플러그인 설치"
# swift-lsp, clangd-lsp 는 기본 내장 마켓플레이스(claude-plugins-official) 소속 - marketplace add 불필요
# clangd-lsp: C/C++ 코드 인텔리전스. compile_commands.json 이 있는 프로젝트에서만 제대로 동작
# (UE 는 RunUBT.sh -mode=GenerateClangDatabase, CMake 는 -DCMAKE_EXPORT_COMPILE_COMMANDS=ON)
foreach ($p in 'context-mode@context-mode','andrej-karpathy-skills@karpathy-skills','claude-dashboard@claude-dashboard','ponytail@ponytail','document-skills@anthropic-agent-skills','swift-lsp@claude-plugins-official','clangd-lsp@claude-plugins-official',
              'unreal-dev-kb@claude-skills-jsc','ue5-rdg@claude-skills-jsc','ue5-shaders@claude-skills-jsc','ue5-coding-convention@claude-skills-jsc','gpu-fluid-sim@claude-skills-jsc','hdk-reference@claude-skills-jsc','gpu-gems-1@claude-skills-jsc') {
  try { claude plugin install $p } catch { Write-Host "   (건너뜀) install $p" }
}

# 2) statusLine 은 hooks/dashboard-statusline.mjs 래퍼가 담당 (settings.json 에 고정)
#    설치 시점 경로를 박지 않는다 - 플러그인 업데이트로 캐시 버전 폴더가 교체되면
#    statusLine 이 조용히 죽기 때문. 래퍼가 매 호출마다 최신 버전을 해석.
$dashGlob = Join-Path $ClaudeDir 'plugins/cache/claude-dashboard/claude-dashboard/*/dist/index.js'
if (-not (Get-ChildItem -Path $dashGlob -File -ErrorAction SilentlyContinue)) {
  Write-Host "!! claude-dashboard 미발견 - statusLine 은 대시보드 설치 후 자동으로 살아납니다"
}

# 3) settings.json / settings.local.json (기존 파일 백업 후 배치)
$ts = Get-Date -Format 'yyyyMMddHHmmss'
foreach ($f in 'settings.json','settings.local.json') {
  $dst = Join-Path $ClaudeDir $f
  if (Test-Path $dst) { Copy-Item $dst "$dst.bak.$ts" -Force; Write-Host "==> 기존 $f 백업: $f.bak.$ts"; Prune-Baks $dst }
}
$settingsText = [System.IO.File]::ReadAllText((Join-Path $Data 'settings.json')).
  Replace('__CLAUDE_DIR__', ($ClaudeDir -replace '\\','/')).
  Replace('__REPO_DIR__', ($ScriptDir -replace '\\','/'))
[System.IO.File]::WriteAllText((Join-Path $ClaudeDir 'settings.json'), $settingsText, $Utf8NoBom)
Copy-Item (Join-Path $Data 'settings.local.json') (Join-Path $ClaudeDir 'settings.local.json') -Force

# 3-0) keybindings.json (기존 파일 백업 후 배치)
$kb = Join-Path $ClaudeDir 'keybindings.json'
if (Test-Path $kb) { Copy-Item $kb "$kb.bak.$ts" -Force; Prune-Baks $kb }
Copy-Item (Join-Path $Data 'keybindings.json') $kb -Force
Write-Host "==> keybindings.json 배치"

# 3-1) 훅 스크립트 배치 (settings.json의 SessionStart가 참조)
$hookSrc = Join-Path $Data 'hooks'
if (Test-Path $hookSrc) {
  $hookDst = Join-Path $ClaudeDir 'hooks'
  New-Item -ItemType Directory -Force -Path $hookDst | Out-Null
  Copy-Item (Join-Path $hookSrc '*') $hookDst -Force
  Write-Host "==> 훅 배치: $hookDst"
}

# 3-2) 스킬 — repo 의 data\skills\* 를 junction
#      메모리(프로젝트 스코프)와 달리 스킬은 유저 스코프라 어느 폴더에서든 쓸 수 있고,
#      description 이 맞을 때만 로드되므로 CLAUDE.md 처럼 매 세션 컨텍스트를 먹지 않는다.
$skillSrcRoot = Join-Path $Data 'skills'
if (Test-Path $skillSrcRoot) {
  $skillDstRoot = Join-Path $ClaudeDir 'skills'
  New-Item -ItemType Directory -Force -Path $skillDstRoot | Out-Null
  Get-ChildItem -LiteralPath $skillSrcRoot -Directory | ForEach-Object {
    $src = $_.FullName -replace '/','\'
    $dst = (Join-Path $skillDstRoot $_.Name) -replace '/','\'
    $ex  = Get-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue
    if ($ex -and ($ex.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
      if ($ex.Target -eq $src) { Write-Host "==> 스킬 junction 이미 설정됨: $($_.Name)"; return }
      cmd /c rmdir "$dst" | Out-Null
    } elseif ($ex) {
      Rename-Item -LiteralPath $dst -NewName "$($_.Name).bak.$ts"
      Write-Host "==> 기존 스킬 백업: $($_.Name).bak.$ts"
      Prune-Baks $dst
    }
    cmd /c mklink /J "$dst" "$src" | Out-Null
    Write-Host "==> 스킬 junction: $dst -> $src"
  }
}

# 4) 전역 지침 CLAUDE.md — 어느 폴더에서 실행하든 항상 로드됨 (기존 파일 백업)
$claudeMd = Join-Path $ClaudeDir 'CLAUDE.md'
if (Test-Path $claudeMd) { Copy-Item $claudeMd "$claudeMd.bak.$ts" -Force; Write-Host "==> 기존 CLAUDE.md 백업: CLAUDE.md.bak.$ts"; Prune-Baks $claudeMd }
Copy-Item (Join-Path $Data 'CLAUDE.md') $claudeMd -Force

# 5) 메모리/지침 — repo 의 data\memory 를 단일 원본으로 디렉토리 junction
#    복사가 아니라 링크. 메모리 자가 갱신이 곧 repo 수정이 되므로
#    동기화는 git pull/push 가 전부 처리.
#    junction(/J) 은 symlink 와 달리 관리자 권한/개발자 모드가 불필요.
#    -> 이 repo 는 삭제/이동하면 안 됨. 설치 후에도 계속 사용되는 실 저장소.
#    메모리는 프로젝트 스코프이므로 폴더마다 경로가 다르다. 설정 작업을 실제로
#    하는 두 곳(HOME, 이 repo)에 모두 링크한다 - 한쪽만 링크하면 다른 쪽 세션의
#    메모리는 git 밖에 쌓이고 기존 메모리도 로드되지 않는다.
$MemSrc = (Join-Path $Data 'memory') -replace '/','\'

function Link-Mem([string]$ProjectRoot) {
  # Claude Code 규칙: 경로의 비영숫자 -> '-'
  $sanitized = ($ProjectRoot -replace '[^A-Za-z0-9]','-')
  $memDir = (Join-Path $ClaudeDir "projects/$sanitized/memory") -replace '/','\'
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $memDir) | Out-Null

  $existing = Get-Item -LiteralPath $memDir -Force -ErrorAction SilentlyContinue
  if ($existing -and ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    if ($existing.Target -eq $MemSrc) { Write-Host "==> 메모리 junction 이미 설정됨: $ProjectRoot"; return }
    cmd /c rmdir "$memDir" | Out-Null        # 다른 곳을 가리키는 링크 -> 교체 (백업 불필요)
  } elseif ($existing) {
    # 실제 디렉토리 -> repo 에 없는 로컬 메모리를 먼저 회수(덮어쓰지 않음) 후 백업
    Get-ChildItem -LiteralPath $memDir -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
      $t = Join-Path $MemSrc $_.Name
      if (-not (Test-Path -LiteralPath $t)) { Copy-Item $_.FullName $t; Write-Host "   회수: $($_.Name)" }
    }
    if (-not (Get-ChildItem -LiteralPath $memDir -Force -ErrorAction SilentlyContinue)) {
      Remove-Item -LiteralPath $memDir -Force   # 빈 디렉토리면 백업할 것이 없다
    } else {
      Rename-Item -LiteralPath $memDir -NewName "memory.bak.$ts"
      Write-Host "==> 기존 메모리 백업: memory.bak.$ts"
      Prune-Baks $memDir
    }
  }
  cmd /c mklink /J "$memDir" "$MemSrc" | Out-Null
  Write-Host "==> 메모리 junction: $memDir -> $MemSrc"
}

Link-Mem $HOME        # 홈에서 세션을 열 때
Link-Mem $ScriptDir   # 이 repo 폴더에서 세션을 열 때

# 6) 레거시 정리 - 구버전 설치 방식이 남긴 파일 (statusLine 은 이제 dashboard 플러그인 담당)
foreach ($legacy in 'statusline-command.sh','statusline-mem-update.sh','statusline-usage-update.sh','install.sh','settings.json.bak') {
  $lp = Join-Path $ClaudeDir $legacy
  if (Test-Path -LiteralPath $lp) { Remove-Item -LiteralPath $lp -Force; Write-Host "==> 레거시 삭제: $legacy" }
}

Write-Host ""
Write-Host "==> 완료 (OK)"
Write-Host "    전역 지침   : $claudeMd   (모든 폴더에서 항상 적용)"
Write-Host "    메모리/지침 : $MemSrc   (HOME 또는 이 repo 에서 세션을 열면 로드 + 자가 갱신)"
