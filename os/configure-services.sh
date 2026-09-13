#!/usr/bin/env bash
set -Eeuo pipefail

for service in \
  kodi-os-storage-init.service \
  kodi-os-storage-check.service \
  kodi-os-firstboot.service \
  kodi-os-gaming-init.service \
  kodi-os-controller-init.service \
  kodi-os-network-init.service \
  kodi-os-healthcheck.service \
  kodi-os-session.service \
  kodi-os-recovery.service \
  kodi-os.target; do
  systemctl enable "$service"
done

for service in NetworkManager.service upower.service bluetooth.service dbus.service; do
  systemctl enable "$service" 2>/dev/null || true
done

chmod 0755 /usr/sbin/kodi-os-update
