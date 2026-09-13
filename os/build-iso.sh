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
KODI_SOURCE_BUILD="${KODI_SOURCE_BUILD:-0}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi
command -v lb >/dev/null || { echo "live-build is required" >&2; exit 1; }

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
  config/includes.chroot/etc/kodi-os \
  config/includes.chroot/usr/sbin \
  config/hooks/live

cp "$OS_DIR/package-lists/kodi-os.list.chroot" config/package-lists/
cp "$OS_DIR/kodi-os-session.service" config/includes.chroot/etc/systemd/system/
cp "$OS_DIR/kodi-os-firstboot.service" config/includes.chroot/etc/systemd/system/
cp "$OS_DIR/firstboot.sh" config/includes.chroot/usr/sbin/kodi-os-firstboot
cp "$OS_DIR/configure-services.sh" config/hooks/live/0200-enable-kodi-os.hook.chroot
chmod +x config/includes.chroot/usr/sbin/kodi-os-firstboot config/hooks/live/0200-enable-kodi-os.hook.chroot

if [[ "$KODI_SOURCE_BUILD" == "1" ]]; then
  mkdir -p config/includes.chroot/usr/src
  tar -C "$ROOT_DIR" --exclude=.git --exclude=build -czf config/includes.chroot/usr/src/kodi-source.tar.gz .
  cp "$OS_DIR/source-build-kodi.sh" config/includes.chroot/usr/sbin/kodi-os-build-source
  chmod +x config/includes.chroot/usr/sbin/kodi-os-build-source
fi

lb build 2>&1 | tee "$ROOT_DIR/build/kodi-os-build.log"

ISO="$(find . -maxdepth 1 -type f \( -name '*.hybrid.iso' -o -name '*.iso' \) -print -quit)"
if [[ -z "$ISO" ]]; then
  echo "live-build completed without producing an ISO" >&2
  exit 2
fi
cp "$ISO" "$ARTIFACT_DIR/${IMAGE_NAME}.iso"
sha256sum "$ARTIFACT_DIR/${IMAGE_NAME}.iso" > "$ARTIFACT_DIR/${IMAGE_NAME}.iso.sha256"
echo "ISO: $ARTIFACT_DIR/${IMAGE_NAME}.iso"
echo "SHA256: $ARTIFACT_DIR/${IMAGE_NAME}.iso.sha256"