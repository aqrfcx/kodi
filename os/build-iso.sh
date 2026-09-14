#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS_DIR="$ROOT_DIR/os"
BUILD_DIR="$ROOT_DIR/build"
LB_DIR="$BUILD_DIR/live-build"
ARTIFACT_DIR="$BUILD_DIR/artifacts"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "ERROR: run as root: sudo ./os/build-iso.sh" >&2
  exit 1
fi

command -v lb >/dev/null 2>&1 || { echo "ERROR: live-build is required" >&2; exit 1; }
command -v xorriso >/dev/null 2>&1 || { echo "ERROR: xorriso is required" >&2; exit 1; }
command -v rsync >/dev/null 2>&1 || { echo "ERROR: rsync is required" >&2; exit 1; }

mkdir -p "$BUILD_DIR" "$ARTIFACT_DIR"
rm -rf "$LB_DIR"
mkdir -p "$LB_DIR"
cd "$LB_DIR"

lb config \
  --distribution bookworm \
  --architectures amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap http://deb.debian.org/debian \
  --mirror-chroot http://deb.debian.org/debian \
  --mirror-binary http://deb.debian.org/debian \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components quiet splash" \
  --iso-application "Kodi OS" \
  --iso-publisher "Kodi OS Project" \
  --iso-volume "KODI_OS"

mkdir -p \
  config/package-lists \
  config/includes.chroot/etc/systemd/system \
  config/includes.chroot/etc/default/grub.d \
  config/includes.chroot/etc/calamares \
  config/includes.chroot/usr/sbin \
  config/includes.chroot/opt/kodi-os \
  config/includes.chroot/usr/share/kodi/addons \
  config/hooks/live

cp "$OS_DIR/package-lists/kodi-os.list.chroot" config/package-lists/
cp "$OS_DIR/systemd/kodi-os.target" config/includes.chroot/etc/systemd/system/

# Install all OS systemd units that are present. This keeps the builder robust
# when a service is added or removed from the OS layer.
for service in "$OS_DIR"/*.service "$OS_DIR"/*.timer "$OS_DIR"/*.path; do
  [[ -f "$service" ]] || continue
  cp "$service" config/includes.chroot/etc/systemd/system/
done

# Install executable OS helpers.
for script in "$OS_DIR"/firstboot.sh "$OS_DIR"/kodi-os-* "$OS_DIR"/kodi-os-hardware.sh "$OS_DIR"/kodi-os-session-wrapper.sh; do
  [[ -f "$script" ]] || continue
  base="$(basename "$script")"
  cp "$script" "config/includes.chroot/usr/sbin/$base"
done

# Recovery configuration and installer assets.
[[ -f "$OS_DIR/kodi-os-recovery-grub.cfg" ]] && cp "$OS_DIR/kodi-os-recovery-grub.cfg" config/includes.chroot/opt/kodi-os/
[[ -d "$OS_DIR/calamares" ]] && rsync -a "$OS_DIR/calamares/" config/includes.chroot/etc/calamares/

# Copy the Kodi Games plugin into the image.
if [[ -d "$ROOT_DIR/addons/plugin.program.kodiosgames" ]]; then
  rm -rf config/includes.chroot/usr/share/kodi/addons/plugin.program.kodiosgames
  cp -a "$ROOT_DIR/addons/plugin.program.kodiosgames" config/includes.chroot/usr/share/kodi/addons/
fi

# Preserve executable permissions inside the chroot.
find config/includes.chroot/usr/sbin -type f -exec chmod 0755 {} +

# Optional live-build hooks shipped by the OS layer.
if [[ -d "$OS_DIR/hooks/live" ]]; then
  rsync -a "$OS_DIR/hooks/live/" config/hooks/live/
  find config/hooks/live -type f -exec chmod 0755 {} +
done
fi

# Build the ISO. Source-building Kodi is intentionally not mixed into the
# first image build; the default path uses the distro Kodi package for a
# reproducible, testable appliance image.
lb build 2>&1 | tee "$BUILD_DIR/live-build.log"

ISO="$(find "$LB_DIR" -maxdepth 1 -type f -name '*.iso' -print -quit)"
if [[ -z "$ISO" ]]; then
  echo "ERROR: live-build completed but no ISO was produced." >&2
  exit 1
fi

cp -f "$ISO" "$ARTIFACT_DIR/kodi-os-amd64.iso"
sha256sum "$ARTIFACT_DIR/kodi-os-amd64.iso" > "$ARTIFACT_DIR/kodi-os-amd64.iso.sha256"

printf '\nBuild complete.\nISO: %s\nSHA256: %s\n' \
  "$ARTIFACT_DIR/kodi-os-amd64.iso" \
  "$ARTIFACT_DIR/kodi-os-amd64.iso.sha256"
