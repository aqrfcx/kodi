#!/usr/bin/env bash
set -Eeuo pipefail

for service in \
  kodi-os-storage-init.service \
  kodi-os-storage-check.service \
  kodi-os-firstboot.service \
  kodi-os-gaming-init.service \
  kodi-os-gaming-check.service \
  kodi-os-game-catalog.service \
  kodi-os-storage-mount.service \
  kodi-os-storage-watch.service \
  kodi-os-controller-init.service \
  kodi-os-device-watch.service \
  kodi-os-network-init.service \
  kodi-os-network-watch.service \
  kodi-os-healthcheck.service \
  kodi-os-session.service \
  kodi-os-recovery.service \
  kodi-os.target; do
  systemctl enable "$service"
done

systemctl enable kodi-os-game-catalog.timer
systemctl enable kodi-os-storage-mount.path

for service in NetworkManager.service udisks2.service upower.service bluetooth.service dbus.service; do
  systemctl enable "$service" 2>/dev/null || true
done

chmod 0755 /usr/sbin/kodi-os-update
chmod 0755 /usr/sbin/kodi-os-storage-watch
chmod 0755 /usr/sbin/kodi-os-storage-mount
