#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/amnezia-wg-easy}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="amnezia-wg-easy"
APP_USER="${APP_USER:-amnezia-wg-easy}"
APP_GROUP="${APP_GROUP:-amnezia-wg-easy}"
ENV_FILE="${APP_DIR}/.env"
WG_PATH_DEFAULT="${WG_PATH_DEFAULT:-/etc/amnezia/amneziawg}"
SYSTEMD_DIR="${SYSTEMD_DIR:-/etc/systemd/system}"
INSTALL_SKIP_APT="${INSTALL_SKIP_APT:-0}"
INSTALL_SKIP_BUN_INSTALL="${INSTALL_SKIP_BUN_INSTALL:-0}"
INSTALL_SKIP_USER_SETUP="${INSTALL_SKIP_USER_SETUP:-0}"
INSTALL_SKIP_CHOWN="${INSTALL_SKIP_CHOWN:-0}"
INSTALL_SKIP_SYSTEMD_START="${INSTALL_SKIP_SYSTEMD_START:-0}"

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
<<<<<<< HEAD
if [[ "${INSTALL_SKIP_APT}" != "1" ]]; then
  apt-get update
  apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg unzip \
    iptables iproute2 qrencode \
    wireguard-tools
else
  echo "INSTALL_SKIP_APT=1 -> skipping apt-get update/install."
fi
=======
echo "Using apt/systemd setup steps (requires root) to install host packages and register a system service."
apt-get update
apt-get install -y --no-install-recommends \
  curl ca-certificates gnupg unzip \
  iptables iproute2 qrencode \
  wireguard-tools
>>>>>>> 96c4069 (fix: accept ubuntu-based installs and add bun install-path tests)

if ! command -v bun >/dev/null 2>&1; then
  curl -fsSL https://bun.sh/install | bash
fi

if [[ -x /root/.bun/bin/bun && ! -x /usr/local/bin/bun ]]; then
  ln -sf /root/.bun/bin/bun /usr/local/bin/bun
fi

if [[ "${INSTALL_SKIP_USER_SETUP}" != "1" ]]; then
  if ! getent group "${APP_GROUP}" >/dev/null 2>&1; then
    groupadd --system "${APP_GROUP}"
  fi

  if ! id -u "${APP_USER}" >/dev/null 2>&1; then
    useradd --system --home-dir "${APP_DIR}" --shell /usr/sbin/nologin -g "${APP_GROUP}" "${APP_USER}"
  fi
else
  echo "INSTALL_SKIP_USER_SETUP=1 -> skipping user/group setup."
fi

mkdir -p "${APP_DIR}"
tar -C "${REPO_DIR}" -cf - . | tar -C "${APP_DIR}" -xf -

if [[ "${INSTALL_SKIP_BUN_INSTALL}" != "1" ]]; then
  cd "${APP_DIR}/src"
  bun install --frozen-lockfile --production
else
  echo "INSTALL_SKIP_BUN_INSTALL=1 -> skipping bun install."
fi

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

if [[ "${INSTALL_SKIP_CHOWN}" != "1" ]]; then
  chown -R "${APP_USER}:${APP_GROUP}" "${APP_DIR}"
  chown -R "${APP_USER}:${APP_GROUP}" "${WG_PATH_DEFAULT}"
else
  echo "INSTALL_SKIP_CHOWN=1 -> skipping chown."
fi

install -D -m 0644 "${APP_DIR}/systemd/amnezia-wg-easy.service" "${SYSTEMD_DIR}/${SERVICE_NAME}.service"
if [[ "${INSTALL_SKIP_SYSTEMD_START}" != "1" ]]; then
  systemctl daemon-reload
  systemctl enable --now "${SERVICE_NAME}.service"
else
  echo "INSTALL_SKIP_SYSTEMD_START=1 -> skipping systemctl daemon-reload/enable."
fi

echo "Installed and started ${SERVICE_NAME}."
echo "Edit ${ENV_FILE}, set WG_HOST and PASSWORD_HASH, then restart:"
echo "  sudo systemctl restart ${SERVICE_NAME}"
