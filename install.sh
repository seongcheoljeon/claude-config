#!/usr/bin/env bash
# Claude Code 설정 이식 스크립트 (macOS / Linux)
# - 플러그인 3개 재설치, settings 복사, statusLine 경로 자동 탐색, 메모리/지침 복사
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="$SCRIPT_DIR/data"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

echo "==> Claude Code 설정 이식 시작"
echo "    HOME       : $HOME"
echo "    CLAUDE_DIR : $CLAUDE_DIR"

# 0) claude CLI 확인
if ! command -v claude >/dev/null 2>&1; then
  echo "!! 'claude' CLI를 찾을 수 없습니다. 먼저 Claude Code를 설치하세요." >&2
  echo "   https://docs.claude.com/en/docs/claude-code" >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

# 1) 마켓플레이스 등록 + 플러그인 설치
echo "==> 마켓플레이스 등록"
claude plugin marketplace add mksglu/context-mode              || true
claude plugin marketplace add forrestchang/andrej-karpathy-skills || true
claude plugin marketplace add uppinote20/claude-dashboard      || true

echo "==> 플러그인 설치"
claude plugin install context-mode@context-mode                || true
claude plugin install andrej-karpathy-skills@karpathy-skills   || true
claude plugin install claude-dashboard@claude-dashboard        || true

# 2) statusLine 대시보드 index.js 경로 자동 탐색 (설치된 최신 버전)
#    macOS(BSD sort)에서 -V 미지원일 수 있어 런타임에 확인 후 폴백
if sort -V </dev/null >/dev/null 2>&1; then SORT_CMD="sort -V"; else SORT_CMD="sort"; fi
DASH_INDEX="$(ls -1 "$CLAUDE_DIR"/plugins/cache/claude-dashboard/claude-dashboard/*/dist/index.js 2>/dev/null | $SORT_CMD | tail -n1 || true)"
if [ -z "$DASH_INDEX" ]; then
  # 미발견 시 무해한 no-op으로 폴백 (에러 방지). 이후 '/claude-dashboard:update'로 경로 갱신.
  echo "!! claude-dashboard index.js 미발견 — statusLine을 no-op으로 설정. Claude Code에서 '/claude-dashboard:update' 실행 권장"
  STATUSLINE_CMD="echo"
else
  echo "==> statusLine 경로: $DASH_INDEX"
  STATUSLINE_CMD="node $DASH_INDEX"
fi

# 3) settings.json / settings.local.json (기존 파일 백업 후 배치)
TS="$(date +%Y%m%d%H%M%S)"
for f in settings.json settings.local.json; do
  if [ -f "$CLAUDE_DIR/$f" ]; then
    cp "$CLAUDE_DIR/$f" "$CLAUDE_DIR/$f.bak.$TS"
    echo "==> 기존 $f 백업: $f.bak.$TS"
  fi
done
sed "s#__STATUSLINE_CMD__#${STATUSLINE_CMD}#g" "$DATA/settings.json" > "$CLAUDE_DIR/settings.json"
cp "$DATA/settings.local.json" "$CLAUDE_DIR/settings.local.json"

# 4) 전역 지침 CLAUDE.md — 어느 폴더에서 실행하든 항상 로드됨 (기존 파일 백업)
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak.$TS"
  echo "==> 기존 CLAUDE.md 백업: CLAUDE.md.bak.$TS"
fi
cp "$DATA/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# 5) 메모리/지침 복사 — home-as-project 경로 산출 (Claude Code 규칙: 비영숫자 → '-')
#    (자가 갱신 메모리 시스템 + reference 노트 보존용. HOME에서 claude 실행 시 로드)
SANITIZED="$(printf '%s' "$HOME" | sed 's/[^A-Za-z0-9]/-/g')"
MEM_DIR="$CLAUDE_DIR/projects/$SANITIZED/memory"
mkdir -p "$MEM_DIR"
cp "$DATA"/memory/*.md "$MEM_DIR"/

echo ""
echo "==> 완료 ✅"
echo "    전역 지침   : $CLAUDE_DIR/CLAUDE.md   (모든 폴더에서 항상 적용)"
echo "    메모리/지침 : $MEM_DIR   (HOME에서 실행 시 로드 + 자가 갱신)"
