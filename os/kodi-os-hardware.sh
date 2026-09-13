#!/usr/bin/env bash
set -Eeuo pipefail

# Read-only hardware diagnostics used by Kodi OS tooling.
# Outputs stable KEY=VALUE lines for future UI/AI integrations.

emit() { printf '%s=%s\n' "$1" "$2"; }

if command -v lscpu >/dev/null 2>&1; then
  emit CPU_MODEL "$(lscpu -n -p=MODEL_NAME 2>/dev/null | grep -v '^#' | head -n1 || true)"
  emit CPU_THREADS "$(nproc 2>/dev/null || true)"
fi

if [[ -r /proc/meminfo ]]; then
  emit RAM_KB "$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
fi

if command -v lsblk >/dev/null 2>&1; then
  emit BLOCK_DEVICES "$(lsblk -dn -o NAME,TYPE,SIZE | tr '\n' ';' | sed 's/;$//')"
fi

if command -v lspci >/dev/null 2>&1; then
  emit GPU_DEVICES "$(lspci -nn 2>/dev/null | grep -Ei 'VGA compatible controller|3D controller|Display controller' | tr '\n' ';' | sed 's/;$//')"
fi

if [[ -d /sys/class/net ]]; then
  emit NETWORK_INTERFACES "$(ls -1 /sys/class/net | tr '\n' ';' | sed 's/;$//')"
fi

if command -v systemctl >/dev/null 2>&1; then
  emit NETWORKMANAGER "$(systemctl is-active NetworkManager 2>/dev/null || true)"
  emit PIPEWIRE "$(systemctl --user is-active pipewire 2>/dev/null || true)"
  emit BLUETOOTH "$(systemctl is-active bluetooth 2>/dev/null || true)"
fi
