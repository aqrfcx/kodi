#!/usr/bin/env bash
set -Eeuo pipefail

install -d -m 0755 /storage /storage/userdata /storage/media /storage/state /home/kodi
if ! id kodi >/dev/null 2>&1; then
  useradd --system --create-home --home-dir /home/kodi --shell /bin/bash kodi
fi
chown -R kodi:kodi /home/kodi /storage
install -d -m 0755 /home/kodi/.config /home/kodi/.local/share /home/kodi/.cache
chown -R kodi:kodi /home/kodi/.config /home/kodi/.local

cat >/etc/X11/xorg.conf.d/10-kodi-os.conf <<'EOF'
Section "ServerFlags"
    Option "DontVTSwitch" "false"
    Option "AutoEnableDevices" "true"
EndSection
EOF

systemctl enable NetworkManager.service || true
systemctl enable upower.service || true
systemctl enable bluetooth.service || true
systemctl enable pipewire.service || true
systemctl enable kodi-os-session.service || true

touch /storage/.kodi-os-initialized
