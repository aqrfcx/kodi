#!/usr/bin/env bash
set -Eeuo pipefail

systemctl enable kodi-os-firstboot.service
systemctl enable kodi-os-session.service
systemctl enable kodi-os-gaming-init.service
systemctl enable kodi-os-controller-init.service
systemctl enable kodi-os-network-init.service
systemctl enable kodi-os-recovery.service
systemctl enable kodi-os.target

for service in NetworkManager.service upower.service bluetooth.service; do
  systemctl enable "$service" 2>/dev/null || true
done
