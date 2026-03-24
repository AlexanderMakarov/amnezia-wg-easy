#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/amnezia-wg-easy}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="amnezia-wg-easy"
APP_USER="${APP_USER:-amnezia-wg-easy}"
APP_GROUP="${APP_GROUP:-amnezia-wg-easy}"
ENV_FILE="${APP_DIR}/.env"
WG_PATH_DEFAULT="/etc/amnezia/amneziawg"
BUN_INSTALL_DIR="${BUN_INSTALL_DIR:-/opt/bun}"
BUN_BIN_PATH="${BUN_BIN_PATH:-/usr/local/bin/bun}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (required for systemd and WireGuard integration)."
  exit 1
fi

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  ID_LIKE_VALUE="${ID_LIKE:-}"
  if [[ "${ID:-}" == "ubuntu" || "${ID_LIKE_VALUE}" == *"ubuntu"* ]]; then
    echo "Detected Ubuntu-based Linux (${PRETTY_NAME:-unknown}); proceeding with supported install flow."
  else
    echo "Warning: officially supported on Ubuntu. Continuing on ${PRETTY_NAME:-unknown} with best-effort compatibility."
  fi
fi

export DEBIAN_FRONTEND=noninteractive
echo "Using apt/systemd setup steps (requires root) to install host packages and register a system service."
apt-get update
apt-get install -y --no-install-recommends \
  curl ca-certificates gnupg unzip \
  iptables iproute2 qrencode \
  wireguard-tools

if [[ ! -x "${BUN_BIN_PATH}" ]]; then
  mkdir -p "${BUN_INSTALL_DIR}"
  BUN_INSTALL="${BUN_INSTALL_DIR}" curl -fsSL https://bun.sh/install | bash
  if [[ ! -x "${BUN_INSTALL_DIR}/bin/bun" ]]; then
    echo "Failed to install bun into ${BUN_INSTALL_DIR}/bin/bun"
    exit 1
  fi
  ln -sf "${BUN_INSTALL_DIR}/bin/bun" "${BUN_BIN_PATH}"
fi

if ! getent group "${APP_GROUP}" >/dev/null 2>&1; then
  groupadd --system "${APP_GROUP}"
fi

if ! id -u "${APP_USER}" >/dev/null 2>&1; then
  useradd --system --home-dir "${APP_DIR}" --shell /usr/sbin/nologin -g "${APP_GROUP}" "${APP_USER}"
fi

mkdir -p "${APP_DIR}"
tar -C "${REPO_DIR}" -cf - . | tar -C "${APP_DIR}" -xf -

cd "${APP_DIR}/src"
bun install --frozen-lockfile --production

mkdir -p "${WG_PATH_DEFAULT}"
chmod 700 "${WG_PATH_DEFAULT}"

WG_BIN="wg"
WG_QUICK_BIN="wg-quick"
if command -v awg >/dev/null 2>&1 && command -v awg-quick >/dev/null 2>&1; then
  WG_BIN="awg"
  WG_QUICK_BIN="awg-quick"
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  cat > "${ENV_FILE}" <<EOF
WG_HOST=CHANGE_ME
PORT=51821
WEBUI_HOST=0.0.0.0
WG_PATH=${WG_PATH_DEFAULT}/
WG_BIN=${WG_BIN}
WG_QUICK_BIN=${WG_QUICK_BIN}
WG_DEVICE=eth0
WG_PORT=51820
WG_CONFIG_PORT=51820
ENABLE_PROMETHEUS_METRICS=false
WG_ENABLE_ONE_TIME_LINKS=false
EOF
  chmod 640 "${ENV_FILE}"
fi

chown -R "${APP_USER}:${APP_GROUP}" "${APP_DIR}"
chown -R "${APP_USER}:${APP_GROUP}" "${WG_PATH_DEFAULT}"

install -D -m 0644 "${APP_DIR}/systemd/amnezia-wg-easy.service" "/etc/systemd/system/${SERVICE_NAME}.service"
systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}.service"

echo "Installed and started ${SERVICE_NAME}."
echo "Edit ${ENV_FILE}, set WG_HOST and PASSWORD_HASH, then restart:"
echo "  sudo systemctl restart ${SERVICE_NAME}"
