#!/usr/bin/env bash
set -Eeuo pipefail

export HOME=/home/kodi
export XDG_CONFIG_HOME=/home/kodi/.config
export XDG_DATA_HOME=/home/kodi/.local/share
export XDG_CACHE_HOME=/home/kodi/.cache

# Keep Kodi's user database/configuration on the persistent OS storage.
# The directory is created on first boot and remains available after reboot.
PERSISTENT_KODI_HOME=/storage/userdata/.kodi
install -d -m 0755 "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$PERSISTENT_KODI_HOME"
chown -R kodi:kodi /home/kodi /storage/userdata

if [[ ! -e /home/kodi/.kodi ]]; then
  ln -s "$PERSISTENT_KODI_HOME" /home/kodi/.kodi
elif [[ -d /home/kodi/.kodi && ! -L /home/kodi/.kodi ]]; then
  # Migrate an existing first-run directory once, without deleting user data.
  if [[ -z "$(ls -A /storage/userdata/.kodi 2>/dev/null)" ]]; then
    cp -a /home/kodi/.kodi/. /storage/userdata/.kodi/
  fi
  rm -rf /home/kodi/.kodi
  ln -s "$PERSISTENT_KODI_HOME" /home/kodi/.kodi
fi

# Wait briefly for the graphical session and audio/network services. Do not
# make Kodi boot depend on optional hardware services.
for _ in {1..30}; do
  if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then break; fi
  sleep 1
done

exec /usr/bin/kodi --standalone "$@"
