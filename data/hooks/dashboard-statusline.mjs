#!/usr/bin/env node
// claude-dashboard statusLine 런처 — 캐시 "버전 폴더"를 실행 시점에 해석한다.
// settings.json 에 .../claude-dashboard/1.30.1/dist/index.js 처럼 버전을 박으면
// 플러그인 업데이트로 폴더가 교체되는 순간 statusLine 이 조용히 죽는다.
// (context-mode-cache-heal.mjs 가 다루는 #46915 와 같은 계열의 고장)
// CLAUDE_CONFIG_DIR(#577) 은 설치 시점이 아니라 이 스크립트 실행 시점에 반영.
// Pure Node.js — 셸 의존 없음(Windows 동일 동작).
import { existsSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { homedir } from "node:os";
import { spawnSync } from "node:child_process";

function cfgDir() {
  const e = process.env.CLAUDE_CONFIG_DIR;
  if (e && e.trim() !== "") {
    return e.startsWith("~") ? resolve(homedir(), e.replace(/^~[/\\]?/, "")) : resolve(e);
  }
  return resolve(homedir(), ".claude");
}

// 깨진 심볼릭 링크가 섞여 있어도 statusLine 전체가 죽지 않도록 예외를 삼킨다.
const isDir = (p) => { try { return statSync(p).isDirectory() } catch { return false } };

const parent = resolve(cfgDir(), "plugins", "cache", "claude-dashboard", "claude-dashboard");
if (!existsSync(parent)) process.exit(0);   // 대시보드 미설치 → 상태줄 없음 (무해)

const versions = readdirSync(parent)
  .filter((d) => /^\d+\.\d+/.test(d) && isDir(join(parent, d)))
  .filter((d) => existsSync(join(parent, d, "dist", "index.js")))
  // 숫자 비교. 사전순은 1.9.0 > 1.26.1 로 오판한다.
  .sort((a, b) => {
    const pa = a.split(".").map(Number), pb = b.split(".").map(Number);
    for (let i = 0; i < 3; i++) if ((pa[i] || 0) !== (pb[i] || 0)) return (pa[i] || 0) - (pb[i] || 0);
    return 0;
  });
if (!versions.length) process.exit(0);

// 별도 프로세스로 위임하고 stdin(세션 JSON)/stdout 을 그대로 물려준다.
// in-process import 는 대시보드가 argv/main 판정을 할 경우 깨지므로 피한다.
const target = join(parent, versions[versions.length - 1], "dist", "index.js");
const r = spawnSync(process.execPath, [target], { stdio: "inherit" });
process.exit(r.status ?? 0);
