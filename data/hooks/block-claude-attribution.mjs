#!/usr/bin/env node
// PreToolUse(Bash|PowerShell): deny git/gh commands that would add Claude attribution
// (Co-Authored-By: Claude / noreply@anthropic.com / "Generated with Claude Code"),
// so Claude never shows up in a GitHub repo's contributors list.
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
let raw = "";
process.stdin.on("data", (c) => (raw += c));
process.stdin.on("end", () => {
  let cmd = "", cwd = ".";
  try {
    const input = JSON.parse(raw);
    cmd = input?.tool_input?.command ?? "";
    cwd = input?.cwd ?? ".";
  } catch {
    return; // unparseable input: don't interfere
  }
  // git 뒤 전역 옵션(-C path, -c k=v 등)이 끼어도 잡도록 서브커맨드 앞을 느슨하게 매칭 (과매칭은 attribution 검사로 걸러짐)
  const writesHistory = /\b(git\b[^\n;&|]*?\s(commit|commit-tree|tag|notes|merge|rebase|cherry-pick|revert)|gh\s+(pr|release|issue))\b/i;
  const attribution = /co-authored-by:[^\n]*(claude|anthropic)|noreply@anthropic\.com|generated with \[?claude code/i;
  if (!writesHistory.test(cmd)) return;
  // 메시지를 파일로 넘기는 경우(-F, --file, --body-file, --notes-file)도 파일 내용까지 검사
  let text = cmd;
  const fileArg = /(?:^|\s)(?:-F|--file|--body-file|--notes-file)(?:=|\s+)("[^"]+"|'[^']+'|[^\s;&|]+)/g;
  for (const m of cmd.matchAll(fileArg)) {
    try {
      text += "\n" + readFileSync(resolve(cwd, m[1].replace(/^["']|["']$/g, "")), "utf8");
    } catch {} // 읽을 수 없는 경로(-, 변수 등)는 명령 문자열 검사만
  }
  if (!attribution.test(text)) return;
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason:
        "Claude attribution is forbidden: remove Co-Authored-By: Claude / noreply@anthropic.com / 'Generated with Claude Code' lines and retry.",
    },
  }));
});
