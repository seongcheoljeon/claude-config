#!/usr/bin/env node
// PreToolUse(Bash|PowerShell): deny git/gh commands that would add Claude attribution
// (Co-Authored-By: Claude / noreply@anthropic.com / "Generated with Claude Code"),
// so Claude never shows up in a GitHub repo's contributors list.
let raw = "";
process.stdin.on("data", (c) => (raw += c));
process.stdin.on("end", () => {
  let cmd = "";
  try {
    cmd = JSON.parse(raw)?.tool_input?.command ?? "";
  } catch {
    return; // unparseable input: don't interfere
  }
  const writesHistory = /\b(git\s+(commit|commit-tree|tag|notes|merge|rebase|cherry-pick|revert)|gh\s+(pr|release|issue))\b/i;
  const attribution = /co-authored-by:[^\n]*(claude|anthropic)|noreply@anthropic\.com|generated with \[?claude code/i;
  if (!writesHistory.test(cmd) || !attribution.test(cmd)) return;
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason:
        "Claude attribution is forbidden: remove Co-Authored-By: Claude / noreply@anthropic.com / 'Generated with Claude Code' lines and retry.",
    },
  }));
});
