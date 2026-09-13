#!/usr/bin/env bash
set -Eeuo pipefail

export HOME=/home/kodi
export XDG_CONFIG_HOME=/home/kodi/.config
export XDG_DATA_HOME=/home/kodi/.local/share
export XDG_CACHE_HOME=/home/kodi/.cache

install -d -m 0755 "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
chown -R kodi:kodi /home/kodi

# Wait briefly for the graphical session and audio/network services. Do not
# make Kodi boot depend on optional hardware services.
for _ in {1..30}; do
  if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then break; fi
  sleep 1
done

exec /usr/bin/kodi --standalone "$@"
