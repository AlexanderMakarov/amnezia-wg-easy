#!/usr/bin/env bun
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

const repoRoot = resolve(import.meta.dir, "..");
const installScriptPath = resolve(repoRoot, "scripts/install-machine-bun.sh");
const serviceFilePath = resolve(repoRoot, "systemd/amnezia-wg-easy.service");

console.log("Running install path validation for native (non-Docker) runtime.");
console.log("Note: full machine install uses sudo because apt/system service changes require root.");

if (!existsSync(installScriptPath)) {
  console.error(`Missing installer: ${installScriptPath}`);
  process.exit(1);
}

if (!existsSync(serviceFilePath)) {
  console.error(`Missing systemd unit file: ${serviceFilePath}`);
  process.exit(1);
}

const installScript = readFileSync(installScriptPath, "utf8");
const serviceFile = readFileSync(serviceFilePath, "utf8");

const checks = [
  {
    name: "installer defaults APP_DIR to /opt/amnezia-wg-easy",
    ok: installScript.includes('APP_DIR="${APP_DIR:-/opt/amnezia-wg-easy}"'),
  },
  {
    name: "installer copies project into APP_DIR",
    ok: installScript.includes('tar -C "${REPO_DIR}" -cf - . | tar -C "${APP_DIR}" -xf -'),
  },
  {
    name: "installer installs production deps with bun",
    ok: installScript.includes("bun install --frozen-lockfile --production"),
  },
  {
    name: "installer registers systemd service in /etc/systemd/system",
    ok: installScript.includes('install -D -m 0644 "${APP_DIR}/systemd/amnezia-wg-easy.service" "/etc/systemd/system/${SERVICE_NAME}.service"'),
  },
  {
    name: "systemd unit runs from /opt/amnezia-wg-easy/src",
    ok: serviceFile.includes("WorkingDirectory=/opt/amnezia-wg-easy/src"),
  },
  {
    name: "systemd unit uses /opt/amnezia-wg-easy/.env",
    ok: serviceFile.includes("EnvironmentFile=-/opt/amnezia-wg-easy/.env"),
  },
];

let failed = 0;
for (const check of checks) {
  if (check.ok) {
    console.log(`PASS: ${check.name}`);
  } else {
    failed += 1;
    console.error(`FAIL: ${check.name}`);
  }
}

if (failed > 0) {
  console.error(`Validation failed: ${failed} check(s) did not pass.`);
  process.exit(1);
}

console.log("Install path validation passed.");
