#!/usr/bin/env bash
# 새 plugin 추가 헬퍼
# Usage: ./scripts/new-plugin.sh <plugin-name> <description> [category]
#
# 예시:
#   ./scripts/new-plugin.sh ue5-post-process "UE5 Post Process cvar 카탈로그"
#   ./scripts/new-plugin.sh ue5-coding-style "UE5 코딩 가이드" workflow
#
# 자동 처리:
#   - <plugin-name>/.claude-plugin/plugin.json 생성
#   - <plugin-name>/skills/<plugin-name>/SKILL.md skeleton 생성
#   - <plugin-name>/README.md skeleton 생성
#   - .claude-plugin/marketplace.json에 plugin 항목 추가 (jq 필요)
#
# 수동으로 채워야 할 것:
#   - SKILL.md 본문
#   - plugin.json/marketplace.json keywords
#   - marketplace/README.md 시나리오 매트릭스 (해당 시)
#   - git commit + push

set -euo pipefail

if [ $# -lt 2 ]; then
    cat <<EOF
Usage: $0 <plugin-name> <description> [category]

Categories: reference (default), workflow, mcp, custom-domain

Example:
  $0 ue5-post-process "UE5 Post Process cvar 카탈로그"
  $0 ue5-style "UE5 코딩 스타일" workflow
EOF
    exit 1
fi

PLUGIN="$1"
DESC="$2"
CATEGORY="${3:-reference}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 중복 체크
if [ -d "$ROOT/$PLUGIN" ]; then
    echo "❌ Error: $PLUGIN already exists at $ROOT/$PLUGIN" >&2
    exit 1
fi

# plugin name 검증 (소문자/하이픈만)
if ! [[ "$PLUGIN" =~ ^[a-z][a-z0-9-]*$ ]]; then
    echo "❌ Error: plugin name must be lowercase alphanumeric + hyphens (got: $PLUGIN)" >&2
    exit 1
fi

# 디렉토리 생성
mkdir -p "$ROOT/$PLUGIN/.claude-plugin"
mkdir -p "$ROOT/$PLUGIN/skills/$PLUGIN"

# plugin.json
cat > "$ROOT/$PLUGIN/.claude-plugin/plugin.json" <<EOF
{
  "name": "$PLUGIN",
  "description": "$DESC",
  "version": "1.0.0",
  "author": {
    "name": "Seongcheol Jeon",
    "email": "seongcheoljeon@mistilgames.com"
  },
  "license": "MIT",
  "keywords": [],
  "skills": ["./skills/$PLUGIN"]
}
EOF

# SKILL.md skeleton
cat > "$ROOT/$PLUGIN/skills/$PLUGIN/SKILL.md" <<'SKILL_EOF'
---
name: __PLUGIN__
description: __DESC__. 트리거: (키워드 나열). 다루지 않음: (다른 plugin 영역).
license: MIT
---

# __PLUGIN__

## 목적

(여기에 본문 작성)

## 사용 흐름

1. (단계)
2. (단계)

## 자동 트리거

다음 키워드를 포함한 질문에 자동 활성화:
- (키워드)
- (키워드)

## 응답 원칙

1. (원칙)
2. (원칙)

## 함께 활성화되면 좋은 plugin

| 시나리오 | 협력 plugin | 본 plugin 역할 | 협력 plugin 역할 |
|---|---|---|---|
| (시나리오) | `other-plugin` | (역할) | (역할) |

## 갱신

(버전 업그레이드 시 갱신할 항목)
SKILL_EOF

# placeholder 치환
sed -i "s/__PLUGIN__/$PLUGIN/g; s/__DESC__/$DESC/g" "$ROOT/$PLUGIN/skills/$PLUGIN/SKILL.md"

# README.md skeleton
cat > "$ROOT/$PLUGIN/README.md" <<EOF
# $PLUGIN

$DESC

## 다루는 영역

- (영역 1)
- (영역 2)

## 자동 트리거

다음 키워드를 포함한 질문에 자동 활성화:
- (키워드)

## 명시적 호출

\`\`\`text
/$PLUGIN
\`\`\`

## 함께 사용하면 좋은 plugin

- \`(other-plugin)\` — (이유)
EOF

# marketplace.json 등록
MP="$ROOT/.claude-plugin/marketplace.json"
if [ ! -f "$MP" ]; then
    echo "⚠ Warning: $MP not found. Skipping marketplace registration." >&2
elif ! command -v jq &> /dev/null; then
    echo "⚠ Warning: jq not installed. Manually add to $MP plugins[]:" >&2
    echo "  Install jq: sudo apt install jq  (WSL/Linux) or  brew install jq  (Mac)" >&2
else
    cp "$MP" "$MP.bak"
    jq --arg name "$PLUGIN" \
       --arg desc "$DESC" \
       --arg cat "$CATEGORY" \
       '.plugins += [{
         "name": $name,
         "source": ("./" + $name),
         "description": $desc,
         "version": "1.0.0",
         "author": {"name": "Seongcheol Jeon"},
         "keywords": [],
         "category": $cat
       }]' "$MP.bak" > "$MP"
    rm "$MP.bak"
    echo "✓ Updated $MP"
fi

cat <<EOF

✓ Created plugin: $PLUGIN
  Path: $ROOT/$PLUGIN
  Files:
    - .claude-plugin/plugin.json
    - skills/$PLUGIN/SKILL.md (skeleton)
    - README.md (skeleton)

Next steps:
  1. Fill SKILL.md body:
     $ROOT/$PLUGIN/skills/$PLUGIN/SKILL.md

  2. Add keywords to plugin.json + marketplace.json
     (currently empty arrays)

  3. (Optional) Add scenario to:
     $ROOT/README.md  (시나리오 매트릭스)

  4. Git:
     cd $ROOT
     git add .
     git commit -m "Add $PLUGIN plugin"
     git push

  5. Install:
     claude plugin install $PLUGIN@claude-skills-jsc

EOF
