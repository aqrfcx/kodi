#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS_DIR="$ROOT_DIR/os"

failures=0
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1" >&2
    failures=$((failures + 1))
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "ERROR: required file not found: $1" >&2
    failures=$((failures + 1))
  fi
}

if [[ "${EUID}" -ne 0 ]]; then
  echo "ERROR: run this check as root (sudo)." >&2
  exit 1
fi

for cmd in lb sha256sum awk find tar; do
  require_cmd "$cmd"
done

for file in \
  "$OS_DIR/build-iso.sh" \
  "$OS_DIR/firstboot.sh" \
  "$OS_DIR/configure-services.sh" \
  "$OS_DIR/kodi-os-session.service" \
  "$OS_DIR/kodi-os-firstboot.service" \
  "$OS_DIR/kodi-os-hardware.sh" \
  "$OS_DIR/package-lists/kodi-os.list.chroot"; do
  require_file "$file"
done

if [[ -f "$OS_DIR/build-iso.sh" ]]; then bash -n "$OS_DIR/build-iso.sh"; fi
if [[ -f "$OS_DIR/firstboot.sh" ]]; then bash -n "$OS_DIR/firstboot.sh"; fi
if [[ -f "$OS_DIR/configure-services.sh" ]]; then bash -n "$OS_DIR/configure-services.sh"; fi
if [[ -f "$OS_DIR/kodi-os-hardware.sh" ]]; then bash -n "$OS_DIR/kodi-os-hardware.sh"; fi

if [[ -f "$OS_DIR/package-lists/kodi-os.list.chroot" ]] && ! grep -qx 'kodi' "$OS_DIR/package-lists/kodi-os.list.chroot"; then
  echo "ERROR: Kodi package is missing from the OS package list." >&2
  failures=$((failures + 1))
fi

if (( failures )); then
  echo "Kodi OS preflight: FAIL ($failures issue(s))" >&2
  exit 1
fi

echo "Kodi OS preflight: PASS"
