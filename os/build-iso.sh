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

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi
for cmd in lb sha256sum find tee tar; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Required command missing: $cmd" >&2; exit 1; }
done

mkdir -p "$ARTIFACT_DIR"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

lb config \
  --mode debian \
  --distribution "$CODENAME" \
  --architectures "$ARCH" \
  --binary-images iso-hybrid \
  --archive-areas "main contrib non-free non-free-firmware" \
  --bootappend-live "boot=live components quiet splash" \
  --debian-installer false \
  --apt-recommends true \
  --memtest none \
  --iso-application "Kodi OS" \
  --iso-publisher "Kodi OS Project" \
  --iso-volume "KODI_OS"

mkdir -p config/package-lists \
  config/includes.chroot/etc/systemd/system \
  config/includes.chroot/etc/default/grub.d \
  config/includes.chroot/etc/calamares \
  config/includes.chroot/usr/sbin \
  config/hooks/live

cp "$OS_DIR/package-lists/kodi-os.list.chroot" config/package-lists/
cp "$OS_DIR/kodi-os-session.service" config/includes.chroot/etc/systemd/system/
cp "$OS_DIR/kodi-os-firstboot.service" config/includes.chroot/etc/systemd/system/
cp "$OS_DIR/kodi-os-recovery.service" config/includes.chroot/etc/systemd/system/
cp "$OS_DIR/kodi-os-gaming-init.service" config/includes.chroot/etc/systemd/system/
cp "$OS_DIR/kodi-os-controller-init.service" config/includes.chroot/etc/systemd/system/
cp "$OS_DIR/kodi-os-network-init.service" config/includes.chroot/etc/systemd/system/
cp "$OS_DIR/systemd/kodi-os.target" config/includes.chroot/etc/systemd/system/
cp "$OS_DIR/firstboot.sh" config/includes.chroot/usr/sbin/kodi-os-firstboot
cp "$OS_DIR/kodi-os-hardware.sh" config/includes.chroot/usr/sbin/kodi-os-hardware
cp "$OS_DIR/kodi-os-session-wrapper.sh" config/includes.chroot/usr/sbin/kodi-os-session-wrapper
cp "$OS_DIR/kodi-os-recovery" config/includes.chroot/usr/sbin/kodi-os-recovery
cp "$OS_DIR/kodi-os-storage-init" config/includes.chroot/usr/sbin/kodi-os-storage-init
cp "$OS_DIR/kodi-os-gaming-init" config/includes.chroot/usr/sbin/kodi-os-gaming-init
cp "$OS_DIR/kodi-os-controller-init" config/includes.chroot/usr/sbin/kodi-os-controller-init
cp "$OS_DIR/kodi-os-network-init" config/includes.chroot/usr/sbin/kodi-os-network-init
cp "$OS_DIR/includes.chroot/etc/default/grub.d/99-kodi-os.cfg" config/includes.chroot/etc/default/grub.d/99-kodi-os.cfg
cp "$OS_DIR/configure-services.sh" config/hooks/live/0200-enable-kodi-os.hook.chroot
cp "$OS_DIR/hooks/0300-validate-kodi-os.hook.chroot" config/hooks/live/0300-validate-kodi-os.hook.chroot
cp "$OS_DIR/hooks/0310-validate-boot-assets.hook.chroot" config/hooks/live/0310-validate-boot-assets.hook.chroot
cp "$OS_DIR/hooks/0320-validate-efi-layout.hook.chroot" config/hooks/live/0320-validate-efi-layout.hook.chroot
chmod +x config/includes.chroot/usr/sbin/kodi-os-firstboot \
  config/includes.chroot/usr/sbin/kodi-os-hardware \
  config/includes.chroot/usr/sbin/kodi-os-session-wrapper \
  config/includes.chroot/usr/sbin/kodi-os-recovery \
  config/includes.chroot/usr/sbin/kodi-os-storage-init \
  config/includes.chroot/usr/sbin/kodi-os-gaming-init \
  config/includes.chroot/usr/sbin/kodi-os-controller-init \
  config/includes.chroot/usr/sbin/kodi-os-network-init \
  config/hooks/live/0200-enable-kodi-os.hook.chroot \
  config/hooks/live/0300-validate-kodi-os.hook.chroot \
  config/hooks/live/0310-validate-boot-assets.hook.chroot \
  config/hooks/live/0320-validate-efi-layout.hook.chroot

if [[ -f "$OS_DIR/calamares/settings.conf" ]]; then
  cp "$OS_DIR/calamares/settings.conf" config/includes.chroot/etc/calamares/settings.conf
fi
if [[ -f "$OS_DIR/hooks/0400-install-calamares.hook.chroot" ]]; then
  cp "$OS_DIR/hooks/0400-install-calamares.hook.chroot" config/hooks/live/0400-install-calamares.hook.chroot
  chmod +x config/hooks/live/0400-install-calamares.hook.chroot
fi

lb build 2>&1 | tee "$ROOT_DIR/build/kodi-os-build.log"

ISO="$(find . -maxdepth 1 -type f \( -name '*.hybrid.iso' -o -name '*.iso' \) -print -quit)"
[[ -n "$ISO" ]] || { echo "live-build completed without producing an ISO" >&2; exit 2; }

cp "$ISO" "$ARTIFACT_DIR/${IMAGE_NAME}.iso"
sha256sum "$ARTIFACT_DIR/${IMAGE_NAME}.iso" > "$ARTIFACT_DIR/${IMAGE_NAME}.iso.sha256"
echo "ISO: $ARTIFACT_DIR/${IMAGE_NAME}.iso"
echo "SHA256: $ARTIFACT_DIR/${IMAGE_NAME}.iso.sha256"
