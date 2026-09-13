#!/usr/bin/env bash
set -Eeuo pipefail

install -d -m 0755 /storage /storage/userdata /storage/media /storage/state /storage/roms /storage/downloads /home/kodi

if ! getent group kodi >/dev/null 2>&1; then
  groupadd --system kodi
fi
if ! id kodi >/dev/null 2>&1; then
  useradd --system --create-home --home-dir /home/kodi --shell /bin/bash --gid kodi kodi
fi

for group in audio video render input netdev; do
  if getent group "$group" >/dev/null 2>&1; then
    usermod -aG "$group" kodi || true
  fi
done

install -d -m 0755 /home/kodi/.config /home/kodi/.local/share /home/kodi/.cache
chown -R kodi:kodi /home/kodi /storage

install -d -m 0755 /etc/X11/xorg.conf.d
cat >/etc/X11/xorg.conf.d/10-kodi-os.conf <<'EOF'
Section "ServerFlags"
    Option "DontVTSwitch" "false"
    Option "AutoEnableDevices" "true"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
EOF

systemctl enable NetworkManager.service || true
systemctl enable upower.service || true
systemctl enable bluetooth.service || true
systemctl enable dbus.service || true

# Keep first boot idempotent: the service may be retried after an interrupted boot.
touch /storage/.kodi-os-initialized
