# Claude Code 설정 이식 스크립트 (Windows PowerShell 5.1 / 7 모두 지원)
# - 플러그인 3개 재설치, settings 배치, statusLine 경로 자동 탐색,
#   전역 CLAUDE.md 배치, 메모리/지침 복사
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

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

# 1) 마켓플레이스 등록 + 플러그인 설치 (개별 실패는 무시하고 계속)
Write-Host "==> 마켓플레이스 등록"
foreach ($m in 'mksglu/context-mode','forrestchang/andrej-karpathy-skills','uppinote20/claude-dashboard') {
  try { claude plugin marketplace add $m } catch { Write-Host "   (건너뜀) marketplace add $m" }
}
Write-Host "==> 플러그인 설치"
foreach ($p in 'context-mode@context-mode','andrej-karpathy-skills@karpathy-skills','claude-dashboard@claude-dashboard') {
  try { claude plugin install $p } catch { Write-Host "   (건너뜀) install $p" }
}

# 2) statusLine 대시보드 index.js 자동 탐색 (설치된 최신 버전; node는 슬래시 경로 허용)
$dashGlob  = Join-Path $ClaudeDir 'plugins/cache/claude-dashboard/claude-dashboard/*/dist/index.js'
$dashFiles = @(Get-ChildItem -Path $dashGlob -File -ErrorAction SilentlyContinue)
$dashFile  = $null
if ($dashFiles.Count -gt 0) {
  try {
    # 버전 폴더명(예: 1.26.1) 기준 정렬, 실패 시 수정시각 기준 폴백
    $dashFile = $dashFiles | Sort-Object { [version]($_.Directory.Parent.Name) } | Select-Object -Last 1
  } catch {
    $dashFile = $dashFiles | Sort-Object LastWriteTime | Select-Object -Last 1
  }
}
if ($dashFile) {
  $StatusLineCmd = 'node ' + ($dashFile.FullName -replace '\\','/')
  Write-Host "==> statusLine: $StatusLineCmd"
} else {
  # 미발견 시 무해한 no-op으로 폴백 (에러 방지). 이후 '/claude-dashboard:update'로 경로 갱신.
  $StatusLineCmd = 'echo'
  Write-Host "!! claude-dashboard index.js 미발견 — statusLine을 no-op으로 설정. Claude Code에서 '/claude-dashboard:update' 실행 권장"
}

# 3) settings.json / settings.local.json (기존 파일 백업 후 배치)
$ts = Get-Date -Format 'yyyyMMddHHmmss'
foreach ($f in 'settings.json','settings.local.json') {
  $dst = Join-Path $ClaudeDir $f
  if (Test-Path $dst) { Copy-Item $dst "$dst.bak.$ts" -Force; Write-Host "==> 기존 $f 백업: $f.bak.$ts" }
}
$settingsText = [System.IO.File]::ReadAllText((Join-Path $Data 'settings.json')).Replace('__STATUSLINE_CMD__', $StatusLineCmd)
[System.IO.File]::WriteAllText((Join-Path $ClaudeDir 'settings.json'), $settingsText, $Utf8NoBom)
Copy-Item (Join-Path $Data 'settings.local.json') (Join-Path $ClaudeDir 'settings.local.json') -Force

# 4) 전역 지침 CLAUDE.md — 어느 폴더에서 실행하든 항상 로드됨 (기존 파일 백업)
$claudeMd = Join-Path $ClaudeDir 'CLAUDE.md'
if (Test-Path $claudeMd) { Copy-Item $claudeMd "$claudeMd.bak.$ts" -Force; Write-Host "==> 기존 CLAUDE.md 백업: CLAUDE.md.bak.$ts" }
Copy-Item (Join-Path $Data 'CLAUDE.md') $claudeMd -Force

# 5) 메모리/지침 복사 — home-as-project 경로 산출 (Claude Code 규칙: 비영숫자 -> '-')
#    (자가 갱신 메모리 시스템 + reference 노트 보존용. HOME에서 claude 실행 시 로드)
$Sanitized = ($HOME -replace '[^A-Za-z0-9]','-')
$MemDir = Join-Path $ClaudeDir "projects/$Sanitized/memory"
New-Item -ItemType Directory -Force -Path $MemDir | Out-Null
Copy-Item (Join-Path $Data 'memory\*.md') $MemDir -Force

Write-Host ""
Write-Host "==> 완료 (OK)"
Write-Host "    전역 지침   : $claudeMd   (모든 폴더에서 항상 적용)"
Write-Host "    메모리/지침 : $MemDir   (HOME에서 실행 시 로드 + 자가 갱신)"
