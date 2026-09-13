#!/usr/bin/env bash
set -Eeuo pipefail

# Small, dependency-light helpers used by Kodi OS. They intentionally avoid
# arbitrary shell execution and expose only the operations needed by the UI.

usage() {
  echo "Usage: $0 {network|audio|display|storage|gaming}"
}

network_status() {
  nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true
}

audio_status() {
  if command -v wpctl >/dev/null 2>&1; then
    wpctl status 2>/dev/null || true
  elif command -v pactl >/dev/null 2>&1; then
    pactl info 2>/dev/null || true
  fi
}

display_status() {
  if command -v xrandr >/dev/null 2>&1; then
    DISPLAY="${DISPLAY:-:0}" xrandr --query 2>/dev/null || true
  fi
}

storage_status() {
  lsblk -e7 -o NAME,PATH,SIZE,FSTYPE,LABEL,MOUNTPOINTS,RM,RO,TYPE 2>/dev/null || true
}

gaming_status() {
  printf 'Steam: '; command -v steam >/dev/null 2>&1 && echo installed || echo unavailable
  printf 'Wine: '; command -v wine >/dev/null 2>&1 && wine --version 2>/dev/null || echo unavailable
  printf 'PCSX2: '; command -v pcsx2 >/dev/null 2>&1 && echo installed || echo unavailable
  printf 'RetroArch: '; command -v retroarch >/dev/null 2>&1 && echo installed || echo unavailable
}

case "${1:-}" in
  network) network_status ;;
  audio) audio_status ;;
  display) display_status ;;
  storage) storage_status ;;
  gaming) gaming_status ;;
  *) usage; exit 2 ;;
esac
