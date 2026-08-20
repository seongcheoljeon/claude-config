#!/usr/bin/env bash
# Claude Code 설정 이식 스크립트 (macOS / Linux)
# - CLI 업데이트, 마켓플레이스(로컬 marketplace/ 포함)·플러그인 14개 설치,
#   settings/keybindings/훅 배치, 전역 CLAUDE.md 배치, 메모리 symlink, 레거시 정리
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

# 0-2) 백업은 재실행마다 누적되므로 원본별 최신 3개만 남긴다 (파일/디렉토리 공통)
prune_baks() {                    # $1: 백업 대상 원본 경로
  { ls -1dt "$1".bak.* 2>/dev/null || true; } | tail -n +4 | while IFS= read -r old; do
    rm -rf "$old"
    echo "   낡은 백업 삭제: $(basename "$old")"
  done
}

mkdir -p "$CLAUDE_DIR"

# 0-3) claude CLI 자체 업데이트 (실패해도 설치는 계속)
claude update || true

# 1) 마켓플레이스 등록 + 플러그인 설치
echo "==> 마켓플레이스 등록"
claude plugin marketplace add mksglu/context-mode              || true
claude plugin marketplace add forrestchang/andrej-karpathy-skills || true
claude plugin marketplace add uppinote20/claude-dashboard      || true
claude plugin marketplace add DietrichGebert/ponytail          || true
claude plugin marketplace add anthropics/skills                || true
# claude-skills-jsc: 이 repo 에 통합된 로컬 마켓플레이스 (marketplace/)
# — 별도 clone 불필요, repo 안에서 스킬을 직접 수정하면 즉시 반영
claude plugin marketplace add "$SCRIPT_DIR/marketplace"        || true

echo "==> 플러그인 설치"
claude plugin install context-mode@context-mode                || true
claude plugin install andrej-karpathy-skills@karpathy-skills   || true
claude plugin install claude-dashboard@claude-dashboard        || true
claude plugin install ponytail@ponytail                        || true
claude plugin install document-skills@anthropic-agent-skills   || true
# 아래 2개는 기본 내장 마켓플레이스(claude-plugins-official) 소속 — marketplace add 불필요
claude plugin install swift-lsp@claude-plugins-official        || true
# clangd-lsp: C/C++ 코드 인텔리전스. compile_commands.json 이 있는 프로젝트에서만 제대로 동작
# (UE 는 RunUBT.sh -mode=GenerateClangDatabase, CMake 는 -DCMAKE_EXPORT_COMPILE_COMMANDS=ON)
claude plugin install clangd-lsp@claude-plugins-official       || true
# claude-skills-jsc 7종 (UE5/HDK/GPU Gems)
for p in unreal-dev-kb ue5-rdg ue5-shaders ue5-coding-convention \
         gpu-fluid-sim hdk-reference gpu-gems-1; do
  claude plugin install "$p@claude-skills-jsc"                 || true
done

# 2) statusLine 은 hooks/dashboard-statusline.mjs 래퍼가 담당 (settings.json 에 고정)
#    설치 시점 경로를 박지 않는다 — 플러그인이 업데이트되면 캐시 버전 폴더가
#    교체되어 statusLine 이 조용히 죽기 때문. 래퍼가 매 호출마다 최신 버전을 해석.
if ! compgen -G "$CLAUDE_DIR/plugins/cache/claude-dashboard/claude-dashboard/*/dist/index.js" >/dev/null; then
  echo "!! claude-dashboard 미발견 — statusLine 은 대시보드 설치 후 자동으로 살아납니다"
fi

# 3) settings.json / settings.local.json (기존 파일 백업 후 배치)
TS="$(date +%Y%m%d%H%M%S)"
for f in settings.json settings.local.json; do
  if [ -f "$CLAUDE_DIR/$f" ]; then
    cp "$CLAUDE_DIR/$f" "$CLAUDE_DIR/$f.bak.$TS"
    echo "==> 기존 $f 백업: $f.bak.$TS"
    prune_baks "$CLAUDE_DIR/$f"
  fi
done
sed -e "s#__CLAUDE_DIR__#${CLAUDE_DIR}#g" \
    -e "s#__REPO_DIR__#${SCRIPT_DIR}#g" \
    "$DATA/settings.json" > "$CLAUDE_DIR/settings.json"
cp "$DATA/settings.local.json" "$CLAUDE_DIR/settings.local.json"

# 3-0) keybindings.json (기존 파일 백업 후 배치)
if [ -f "$CLAUDE_DIR/keybindings.json" ]; then
  cp "$CLAUDE_DIR/keybindings.json" "$CLAUDE_DIR/keybindings.json.bak.$TS"
  prune_baks "$CLAUDE_DIR/keybindings.json"
fi
cp "$DATA/keybindings.json" "$CLAUDE_DIR/keybindings.json"
echo "==> keybindings.json 배치"

# 3-1) 훅 스크립트 배치 (settings.json의 SessionStart가 참조 — 실행권한 필수)
if [ -d "$DATA/hooks" ]; then
  mkdir -p "$CLAUDE_DIR/hooks"
  cp "$DATA"/hooks/* "$CLAUDE_DIR/hooks"/
  chmod +x "$CLAUDE_DIR"/hooks/*
  echo "==> 훅 배치: $CLAUDE_DIR/hooks"
fi

# 3-2) 스킬 — repo 의 data/skills/* 를 symlink
#      메모리(프로젝트 스코프)와 달리 스킬은 유저 스코프라 어느 폴더에서든 쓸 수 있고,
#      description 이 맞을 때만 로드되므로 CLAUDE.md 처럼 매 세션 컨텍스트를 먹지 않는다.
#      → 전역이어야 하지만 항상 필요하진 않은 도메인 지식은 여기에 둔다.
if [ -d "$DATA/skills" ]; then
  mkdir -p "$CLAUDE_DIR/skills"
  for s in "$DATA"/skills/*/; do
    [ -d "$s" ] || continue
    src="${s%/}"; dst="$CLAUDE_DIR/skills/$(basename "$src")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      echo "==> 스킬 symlink 이미 설정됨: $(basename "$src")"
      continue
    fi
    [ -L "$dst" ] && rm -f "$dst"
    if [ -d "$dst" ]; then
      mv "$dst" "$dst.bak.$TS"
      echo "==> 기존 스킬 백업: $(basename "$dst").bak.$TS"
      prune_baks "$dst"
    fi
    ln -s "$src" "$dst"
    echo "==> 스킬 symlink: $dst -> $src"
  done
fi

# 4) 전역 지침 CLAUDE.md — 어느 폴더에서 실행하든 항상 로드됨 (기존 파일 백업)
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak.$TS"
  echo "==> 기존 CLAUDE.md 백업: CLAUDE.md.bak.$TS"
  prune_baks "$CLAUDE_DIR/CLAUDE.md"
fi
cp "$DATA/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# 5) 메모리/지침 — repo 의 data/memory 를 단일 원본으로 symlink
#    복사가 아니라 링크. 메모리 자가 갱신이 곧 repo 수정이 되므로
#    동기화는 git pull/push 가 전부 처리 (단방향 복사는 repo 가 낡고,
#    재실행 시 로컬 메모리를 덮어써서 유실됨)
#    → 이 repo 는 삭제/이동하면 안 됨. 설치 후에도 계속 사용되는 실 저장소.
#    메모리는 프로젝트 스코프이므로 폴더마다 경로가 다르다. 설정 작업을 실제로
#    하는 두 곳(HOME, 이 repo)에 모두 링크한다 — 한쪽만 링크하면 다른 쪽 세션의
#    메모리는 git 밖에 쌓이고 기존 메모리도 로드되지 않는다.
MEM_SRC="$DATA/memory"

link_mem() {                      # $1: 프로젝트 루트 경로
  local sanitized mem_dir m
  # Claude Code 규칙: 경로의 비영숫자 → '-'
  sanitized="$(printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g')"
  mem_dir="$CLAUDE_DIR/projects/$sanitized/memory"
  mkdir -p "$(dirname "$mem_dir")"

  if [ -L "$mem_dir" ] && [ "$(readlink "$mem_dir")" = "$MEM_SRC" ]; then
    echo "==> 메모리 symlink 이미 설정됨: $1"
    return
  fi
  if [ -L "$mem_dir" ]; then
    rm -f "$mem_dir"                       # 다른 곳을 가리키는 링크 → 교체
  elif [ -d "$mem_dir" ]; then
    # 실제 디렉토리 → repo 에 없는 로컬 메모리를 먼저 회수(덮어쓰지 않음) 후 백업
    for m in "$mem_dir"/*.md; do
      [ -e "$m" ] || continue
      [ -e "$MEM_SRC/$(basename "$m")" ] || { cp "$m" "$MEM_SRC"/; echo "   회수: $(basename "$m")"; }
    done
    # 빈 디렉토리면 백업할 것이 없다 (rmdir 은 비어있지 않으면 실패 → 백업으로 폴백)
    rmdir "$mem_dir" 2>/dev/null || {
      mv "$mem_dir" "$mem_dir.bak.$TS"
      echo "==> 기존 메모리 백업: $mem_dir.bak.$TS"
      prune_baks "$mem_dir"
    }
  fi
  ln -s "$MEM_SRC" "$mem_dir"
  echo "==> 메모리 symlink: $mem_dir -> $MEM_SRC"
}

link_mem "$HOME"           # 홈에서 세션을 열 때
link_mem "$SCRIPT_DIR"     # 이 repo 폴더에서 세션을 열 때

# 6) 레거시 정리 — 구버전 설치 방식이 남긴 파일 (statusLine 은 이제 dashboard 플러그인 담당)
for legacy in statusline-command.sh statusline-mem-update.sh statusline-usage-update.sh \
              install.sh settings.json.bak; do
  if [ -f "$CLAUDE_DIR/$legacy" ]; then
    rm -f "$CLAUDE_DIR/$legacy"
    echo "==> 레거시 삭제: $legacy"
  fi
done

echo ""
echo "==> 완료 ✅"
echo "    전역 지침   : $CLAUDE_DIR/CLAUDE.md   (모든 폴더에서 항상 적용)"
echo "    메모리/지침 : $MEM_SRC   (HOME 또는 이 repo 에서 세션을 열면 로드 + 자가 갱신)"
