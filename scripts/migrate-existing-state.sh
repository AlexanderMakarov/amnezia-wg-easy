#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-/etc/amnezia/amneziawg}"
SOURCE_DIR="${2:-}"

if [[ -z "${SOURCE_DIR}" ]]; then
  if [[ -d /etc/amnezia/amneziawg ]]; then
    SOURCE_DIR="/etc/amnezia/amneziawg"
  elif [[ -d /etc/wireguard ]]; then
    SOURCE_DIR="/etc/wireguard"
  else
    echo "No source directory found. Pass source explicitly:"
    echo "  sudo $0 /etc/amnezia/amneziawg /path/to/source"
    exit 1
  fi
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root."
  exit 1
fi

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "Source directory does not exist: ${SOURCE_DIR}"
  exit 1
fi

mkdir -p "${TARGET_DIR}"
chmod 700 "${TARGET_DIR}"

for file in wg0.conf wg0.json; do
  if [[ -f "${SOURCE_DIR}/${file}" ]]; then
    cp -a "${SOURCE_DIR}/${file}" "${TARGET_DIR}/${file}"
  fi
done

if [[ ! -f "${TARGET_DIR}/wg0.conf" ]]; then
  echo "Missing ${TARGET_DIR}/wg0.conf after migration."
  exit 1
fi

if [[ ! -f "${TARGET_DIR}/wg0.json" ]]; then
  echo "Warning: ${TARGET_DIR}/wg0.json not found. UI client metadata may be missing."
fi

echo "State copied from ${SOURCE_DIR} to ${TARGET_DIR}."
