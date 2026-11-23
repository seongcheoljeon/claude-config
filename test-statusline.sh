#!/usr/bin/env bash
# dashboard-statusline.mjs 자체 검증 — 가짜 캐시 디렉토리로 버전 해석을 확인한다.
# 확인 대상: (1) 사전순이 아닌 "숫자" 정렬 (1.9.0 < 1.26.1 < 1.30.1)
#            (2) stdin(세션 JSON) 을 대시보드에 그대로 물려주는지
#            (3) 대시보드 미설치 시 조용히 종료(exit 0)하는지 — 상태줄만 비면 됨
set -euo pipefail

WRAPPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/data/hooks/dashboard-statusline.mjs"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for v in 0.1.0 1.9.0 1.26.1 1.30.1; do
  d="$TMP/plugins/cache/claude-dashboard/claude-dashboard/$v/dist"
  mkdir -p "$d"
  # 자기 버전 + 받은 stdin 을 그대로 출력하는 스텁
  printf 'let i="";process.stdin.on("data",c=>i+=c).on("end",()=>console.log("%s|"+JSON.parse(i).model.display_name));\n' "$v" > "$d/index.js"
done

got="$(echo '{"model":{"display_name":"Opus 5"}}' | CLAUDE_CONFIG_DIR="$TMP" bun "$WRAPPER")"
[ "$got" = "1.30.1|Opus 5" ] || { echo "FAIL: 최신 버전/stdin 전달 — got: $got" >&2; exit 1; }

# ponytail 플래그가 있으면 첫 줄 앞에 배지
echo full > "$TMP/.ponytail-active"
got="$(echo '{"model":{"display_name":"Opus 5"}}' | CLAUDE_CONFIG_DIR="$TMP" bun "$WRAPPER")"
[ "$got" = $'\e[38;5;108m[PONYTAIL]\e[0m 1.30.1|Opus 5' ] || { echo "FAIL: ponytail 배지 — got: $got" >&2; exit 1; }

# 버전 폴더가 아예 없을 때: 출력 없이 exit 0 (statusLine 오류 표시를 만들지 않음)
got="$(echo '{}' | CLAUDE_CONFIG_DIR="$TMP/none" bun "$WRAPPER")" || { echo "FAIL: 미설치 시 0 이 아닌 종료" >&2; exit 1; }
[ -z "$got" ] || { echo "FAIL: 미설치인데 출력 있음 — $got" >&2; exit 1; }

echo "OK: statusLine 래퍼 정상 (버전 숫자정렬 + stdin 전달 + ponytail 배지 + 미설치 폴백)"
