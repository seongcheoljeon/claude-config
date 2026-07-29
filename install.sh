#!/usr/bin/env bash
# Claude Code 설정 이식 스크립트 (macOS / Linux)
# - 플러그인 4개 재설치, settings 복사, statusLine 경로 자동 탐색, 훅/메모리/지침 복사
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

# 0-1) node 확인 (statusLine + SessionStart 훅이 의존. 없으면 조용히 실패하므로 경고)
command -v node >/dev/null 2>&1 || echo "!! 'node' 미발견 — statusLine과 SessionStart 훅이 동작하지 않습니다. Node.js 설치 권장 (설치는 계속 진행)" >&2

mkdir -p "$CLAUDE_DIR"

# 1) 마켓플레이스 등록 + 플러그인 설치
echo "==> 마켓플레이스 등록"
claude plugin marketplace add mksglu/context-mode              || true
claude plugin marketplace add forrestchang/andrej-karpathy-skills || true
claude plugin marketplace add uppinote20/claude-dashboard      || true
claude plugin marketplace add DietrichGebert/ponytail          || true

echo "==> 플러그인 설치"
claude plugin install context-mode@context-mode                || true
claude plugin install andrej-karpathy-skills@karpathy-skills   || true
claude plugin install claude-dashboard@claude-dashboard        || true
claude plugin install ponytail@ponytail                        || true

# 2) statusLine 대시보드 index.js 경로 자동 탐색 (설치된 최신 버전)
#    버전 폴더명을 자리수 고정으로 패딩해 정렬 — sort -V 에 의존하지 않음.
#    (BSD sort 는 -V 미지원일 수 있고, 사전순 폴백은 1.9.0 > 1.26.1 로 오판)
DASH_INDEX="$(
  for f in "$CLAUDE_DIR"/plugins/cache/claude-dashboard/claude-dashboard/*/dist/index.js; do
    [ -f "$f" ] || continue
    v="${f%/dist/index.js}"; v="${v##*/}"
    printf '%s\t%s\n' "$(printf '%s' "$v" | awk -F. '{printf "%05d%05d%05d", $1, $2, $3}')" "$f"
  done | sort | tail -n1 | cut -f2-
)"
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
sed -e "s#__STATUSLINE_CMD__#${STATUSLINE_CMD}#g" \
    -e "s#__CLAUDE_DIR__#${CLAUDE_DIR}#g" \
    "$DATA/settings.json" > "$CLAUDE_DIR/settings.json"
cp "$DATA/settings.local.json" "$CLAUDE_DIR/settings.local.json"

# 3-1) 훅 스크립트 배치 (settings.json의 SessionStart가 참조 — 실행권한 필수)
if [ -d "$DATA/hooks" ]; then
  mkdir -p "$CLAUDE_DIR/hooks"
  cp "$DATA"/hooks/* "$CLAUDE_DIR/hooks"/
  chmod +x "$CLAUDE_DIR"/hooks/*
  echo "==> 훅 배치: $CLAUDE_DIR/hooks"
fi

# 4) 전역 지침 CLAUDE.md — 어느 폴더에서 실행하든 항상 로드됨 (기존 파일 백업)
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak.$TS"
  echo "==> 기존 CLAUDE.md 백업: CLAUDE.md.bak.$TS"
fi
cp "$DATA/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# 5) 메모리/지침 — repo 의 data/memory 를 단일 원본으로 symlink
#    복사가 아니라 링크. 메모리 자가 갱신이 곧 repo 수정이 되므로
#    동기화는 git pull/push 가 전부 처리 (단방향 복사는 repo 가 낡고,
#    재실행 시 로컬 메모리를 덮어써서 유실됨)
#    → 이 repo 는 삭제/이동하면 안 됨. 설치 후에도 계속 사용되는 실 저장소.
#    home-as-project 경로 산출 (Claude Code 규칙: 비영숫자 → '-')
SANITIZED="$(printf '%s' "$HOME" | sed 's/[^A-Za-z0-9]/-/g')"
MEM_DIR="$CLAUDE_DIR/projects/$SANITIZED/memory"
MEM_SRC="$DATA/memory"
mkdir -p "$(dirname "$MEM_DIR")"

if [ -L "$MEM_DIR" ] && [ "$(readlink "$MEM_DIR")" = "$MEM_SRC" ]; then
  echo "==> 메모리 symlink 이미 설정됨 (변경 없음)"
else
  if [ -L "$MEM_DIR" ]; then
    rm -f "$MEM_DIR"                       # 다른 곳을 가리키는 링크 → 교체
  elif [ -d "$MEM_DIR" ]; then
    # 실제 디렉토리 → repo 에 없는 로컬 메모리를 먼저 회수(덮어쓰지 않음) 후 백업
    for m in "$MEM_DIR"/*.md; do
      [ -e "$m" ] || continue
      [ -e "$MEM_SRC/$(basename "$m")" ] || { cp "$m" "$MEM_SRC"/; echo "   회수: $(basename "$m")"; }
    done
    mv "$MEM_DIR" "$MEM_DIR.bak.$TS"
    echo "==> 기존 메모리 백업: memory.bak.$TS"
  fi
  ln -s "$MEM_SRC" "$MEM_DIR"
  echo "==> 메모리 symlink: $MEM_DIR -> $MEM_SRC"
fi

echo ""
echo "==> 완료 ✅"
echo "    전역 지침   : $CLAUDE_DIR/CLAUDE.md   (모든 폴더에서 항상 적용)"
echo "    메모리/지침 : $MEM_DIR   (HOME에서 실행 시 로드 + 자가 갱신)"
