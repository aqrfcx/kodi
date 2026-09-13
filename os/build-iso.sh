  --iso-publisher "Kodi OS Project" --iso-volume "KODI_OS"
mkdir -p config/package-lists config/includes.chroot/etc/systemd/system \
  config/includes.chroot/etc/systemd/system/kodi-os-storage-mount.path.d \
  config/includes.chroot/etc/default/grub.d config/includes.chroot/etc/calamares \
  config/includes.chroot/usr/sbin config/includes.chroot/opt/kodi-os config/hooks/live \
  config/includes.chroot/usr/share/kodi/addons
cp "$OS_DIR/package-lists/kodi-os.list.chroot" config/package-lists/
cp "$OS_DIR/systemd/kodi-os.target" config/includes.chroot/etc/systemd/system/
for service in kodi-os-storage-init.service kodi-os-session.service kodi-os-firstboot.service kodi-os-recovery.service \
  kodi-os-gaming-init.service kodi-os-gaming-check.service kodi-os-game-launcher.service kodi-os-game-catalog.service kodi-os-game-catalog.timer \
  kodi-os-storage-mount.service kodi-os-storage-mount.path kodi-os-controller-init.service kodi-os-device-watch.service \
  kodi-os-network-init.service kodi-os-network-watch.service kodi-os-healthcheck.service kodi-os-storage-check.service kodi-os-update.service; do
  cp "$OS_DIR/$service" config/includes.chroot/etc/systemd/system/
done
for script in firstboot.sh kodi-os-hardware.sh kodi-os-session-wrapper.sh kodi-os-recovery \
  kodi-os-storage-init kodi-os-storage-check kodi-os-gaming-init kodi-os-gaming-check kodi-os-game-launcher kodi-os-game-catalog \
  kodi-os-storage-mount kodi-os-controller-init kodi-os-device-watch kodi-os-network-init kodi-os-network-watch kodi-os-healthcheck kodi-os-app-launcher kodi-os-update; do
  cp "$OS_DIR/$script" "config/includes.chroot/usr/sbin/${script%.sh}"
done
if [[ -d "$ROOT_DIR/addons/plugin.program.kodiosgames" ]]; then
  rm -rf config/includes.chroot/usr/share/kodi/addons/plugin.program.kodiosgames
  cp -a "$ROOT_DIR/addons/plugin.program.kodiosgames" config/includes.chroot/usr/share/kodi/addons/
fi
cp "$OS_DIR/kodi-os-recovery-grub.cfg" config/includes.chroot/opt/kodi-os/kodi-os-recovery-grub.cfg