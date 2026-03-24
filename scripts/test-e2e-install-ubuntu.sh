#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /etc/os-release ]]; then
  echo "[FAIL] /etc/os-release is missing. Ubuntu-only test cannot continue."
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "[FAIL] Ubuntu is required for this e2e install check. Detected: ${PRETTY_NAME:-unknown}."
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "[FAIL] apt-get is required for this e2e install check."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "[FAIL] sudo is required to execute installer checks as root."
  exit 1
fi

echo "[INFO] Ubuntu + apt detected: ${PRETTY_NAME:-ubuntu}."
echo "[INFO] sudo is required because apt updates package metadata and installs system packages under privileged paths."
echo "[INFO] Running installer execution-path validation in safe e2e mode."

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "${tmp_root}"' EXIT

app_dir="${tmp_root}/app"
wg_dir="${tmp_root}/wg-path"
systemd_dir="${tmp_root}/systemd"

sudo env \
  APP_DIR="${app_dir}" \
  WG_PATH_DEFAULT="${wg_dir}" \
  SYSTEMD_DIR="${systemd_dir}" \
  INSTALL_SKIP_APT=1 \
  INSTALL_SKIP_BUN_INSTALL=1 \
  INSTALL_SKIP_USER_SETUP=1 \
  INSTALL_SKIP_CHOWN=1 \
  INSTALL_SKIP_SYSTEMD_START=1 \
  bash "${repo_dir}/scripts/install-machine-bun.sh"

service_file="${systemd_dir}/amnezia-wg-easy.service"
env_file="${app_dir}/.env"

[[ -f "${service_file}" ]] || { echo "[FAIL] Service file not created: ${service_file}"; exit 1; }
[[ -f "${env_file}" ]] || { echo "[FAIL] Env file not created: ${env_file}"; exit 1; }

grep -q "^WG_PATH=${wg_dir}/" "${env_file}" || { echo "[FAIL] Env file WG_PATH does not match expected test path."; exit 1; }
grep -q "^WG_BIN=" "${env_file}" || { echo "[FAIL] Env file missing WG_BIN."; exit 1; }
grep -q "^WG_QUICK_BIN=" "${env_file}" || { echo "[FAIL] Env file missing WG_QUICK_BIN."; exit 1; }

echo "[PASS] Installer execution path completed."
echo "[PASS] Service file check passed: ${service_file}"
echo "[PASS] Environment file check passed: ${env_file}"
echo "[PASS] Ubuntu e2e install verification completed successfully."
