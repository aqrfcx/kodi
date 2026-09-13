#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS_DIR="$ROOT_DIR/os"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/build/live}"
ARTIFACT_DIR="${ARTIFACT_DIR:-$ROOT_DIR/build/artifacts}"
IMAGE_NAME="${IMAGE_NAME:-kodi-os}"
CODENAME="${CODENAME:-bookworm}"
ARCH="${ARCH:-amd64}"
if [[ "${EUID}" -ne 0 ]]; then echo "Run as root: sudo $0" >&2; exit 1; fi
command -v lb >/dev/null 2>&1 || { echo "live-build (lb) is required" >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum is required" >&2; exit 1; }
mkdir -p "$ARTIFACT_DIR" "$ROOT_DIR/build"
rm -rf "$WORK_DIR"; mkdir -p "$WORK_DIR"; cd "$WORK_DIR"
lb config --mode debian --distribution "$CODENAME" --architectures "$ARCH" \
  --binary-images iso-hybrid --archive-areas "main contrib non-free non-free-firmware" \
  --bootappend-live "boot=live components quiet splash" --debian-installer false \
  --apt-recommends true --memtest none --iso-application "Kodi OS" \
  --iso-publisher "Kodi OS Project" --iso-volume "KODI_OS"
mkdir -p config/package-lists config/includes.chroot/etc/systemd/system \
  config/includes.chroot/etc/default/grub.d config/includes.chroot/etc/calamares \
  config/includes.chroot/usr/sbin config/includes.chroot/opt/kodi-os config/hooks/live
cp "$OS_DIR/package-lists/kodi-os.list.chroot" config/package-lists/
cp "$OS_DIR/systemd/kodi-os.target" config/includes.chroot/etc/systemd/system/
for service in kodi-os-storage-init.service kodi-os-session.service kodi-os-firstboot.service kodi-os-recovery.service \
  kodi-os-gaming-init.service kodi-os-controller-init.service kodi-os-network-init.service kodi-os-network-watch.service \
  kodi-os-healthcheck.service kodi-os-storage-check.service kodi-os-update.service; do
  cp "$OS_DIR/$service" config/includes.chroot/etc/systemd/system/
done
for script in firstboot.sh kodi-os-hardware.sh kodi-os-session-wrapper.sh kodi-os-recovery \
  kodi-os-storage-init kodi-os-storage-check kodi-os-gaming-init kodi-os-controller-init \
  kodi-os-network-init kodi-os-network-watch kodi-os-healthcheck kodi-os-app-launcher kodi-os-update; do
  cp "$OS_DIR/$script" "config/includes.chroot/usr/sbin/${script%.sh}"
done
cp "$OS_DIR/kodi-os-recovery-grub.cfg" config/includes.chroot/opt/kodi-os/kodi-os-recovery-grub.cfg
cp "$OS_DIR/includes.chroot/etc/default/grub.d/99-kodi-os.cfg" config/includes.chroot/etc/default/grub.d/99-kodi-os.cfg
cp "$OS_DIR/configure-services.sh" config/hooks/live/0200-enable-kodi-os.hook.chroot
cp "$OS_DIR/hooks/0300-validate-kodi-os.hook.chroot" config/hooks/live/0300-validate-kodi-os.hook.chroot
cp "$OS_DIR/hooks/0310-validate-boot-assets.hook.chroot" config/hooks/live/0310-validate-boot-assets.hook.chroot
cp "$OS_DIR/hooks/0320-validate-efi-layout.hook.chroot" config/hooks/live/0320-validate-efi-layout.hook.chroot
cp "$OS_DIR/hooks/0330-install-recovery-grub.hook.chroot" config/hooks/live/0330-install-recovery-grub.hook.chroot
chmod +x config/includes.chroot/usr/sbin/* config/hooks/live/*.hook.chroot
if [[ -f "$OS_DIR/calamares/settings.conf" ]]; then cp "$OS_DIR/calamares/settings.conf" config/includes.chroot/etc/calamares/settings.conf; fi
if [[ -f "$OS_DIR/hooks/0400-install-calamares.hook.chroot" ]]; then cp "$OS_DIR/hooks/0400-install-calamares.hook.chroot" config/hooks/live/0400-install-calamares.hook.chroot; chmod +x config/hooks/live/0400-install-calamares.hook.chroot; fi
lb build 2>&1 | tee "$ROOT_DIR/build/kodi-os-build.log"
ISO="$(find . -maxdepth 1 -type f \( -name '*.hybrid.iso' -o -name '*.iso' \) -print -quit)"
[[ -n "$ISO" ]] || { echo "live-build completed without producing an ISO" >&2; exit 2; }
cp "$ISO" "$ARTIFACT_DIR/${IMAGE_NAME}.iso"
sha256sum "$ARTIFACT_DIR/${IMAGE_NAME}.iso" > "$ARTIFACT_DIR/${IMAGE_NAME}.iso.sha256"
echo "ISO: $ARTIFACT_DIR/${IMAGE_NAME}.iso"
echo "SHA256: $ARTIFACT_DIR/${IMAGE_NAME}.iso.sha256"