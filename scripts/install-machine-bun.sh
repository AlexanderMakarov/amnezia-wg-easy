#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/amnezia-wg-easy}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="amnezia-wg-easy"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (required for systemd and WireGuard integration)."
  exit 1
fi

if ! command -v bun >/dev/null 2>&1; then
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="${BUN_INSTALL:-/root/.bun}"
  export PATH="${BUN_INSTALL}/bin:${PATH}"
fi

mkdir -p "${APP_DIR}"
tar -C "${REPO_DIR}" -cf - . | tar -C "${APP_DIR}" -xf -

cd "${APP_DIR}/src"
bun install --frozen-lockfile --production

install -D -m 0644 "${APP_DIR}/systemd/amnezia-wg-easy.service" "/etc/systemd/system/${SERVICE_NAME}.service"
systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}.service"

echo "Installed and started ${SERVICE_NAME}."
