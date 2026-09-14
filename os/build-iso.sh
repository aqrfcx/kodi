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
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required" >&2; exit 1; }
command -v dpkg-deb >/dev/null 2>&1 || { echo "ERROR: dpkg-deb is required" >&2; exit 1; }

mkdir -p "$BUILD_DIR" "$ARTIFACT_DIR"
rm -rf "$LB_DIR"
mkdir -p "$LB_DIR"
cd "$LB_DIR"

# Ubuntu 22.04 ships an older Debian archive keyring. Fetch the verified
# Bookworm keyring and install it where this live-build/debootstrap version
# expects it. This avoids relying on the host's stale keyring.
KEYRING_DIR="$BUILD_DIR/debian-keyring"
KEYRING_DEB="$KEYRING_DIR/debian-archive-keyring_2023.3+deb12u2_all.deb"
KEYRING="$KEYRING_DIR/usr/share/keyrings/debian-archive-keyring.gpg"
HOST_KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"
KEYRING_SHA256="f699e2f88dca05212f2a452b58475f2993cb6993dfbafb1d0205a3291eb8b4b8"

if [[ ! -f "$KEYRING" ]]; then
  rm -rf "$KEYRING_DIR"
  mkdir -p "$KEYRING_DIR"
  curl -fsSL \
    "http://deb.debian.org/debian/pool/main/d/debian-archive-keyring/debian-archive-keyring_2023.3+deb12u2_all.deb" \
    -o "$KEYRING_DEB"
  printf '%s  %s\n' "$KEYRING_SHA256" "$KEYRING_DEB" | sha256sum -c -
  dpkg-deb -x "$KEYRING_DEB" "$KEYRING_DIR"
fi

[[ -s "$KEYRING" ]] || { echo "ERROR: Debian archive keyring was not extracted" >&2; exit 1; }
install -m 0644 "$KEYRING" "$HOST_KEYRING"

# Ubuntu's live-build is old enough to generate the obsolete Bookworm
# security suite (bookworm/updates). Disable live-build's security archive
# during the build, then add the correct bookworm-security source to the
# resulting image below. This keeps the build itself functional while the
# installed Kodi OS still has the Debian security repository enabled.
lb config \
  --ignore-system-defaults \
  --mode debian \
  --distribution bookworm \
  --architectures amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap http://deb.debian.org/debian \
  --mirror-chroot http://deb.debian.org/debian \
  --mirror-binary http://deb.debian.org/debian \
  --security false \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components quiet splash" \
  --iso-application "Kodi OS" \
  --iso-publisher "Kodi OS Project" \
  --iso-volume "KODI_OS"

# Normalize any stale security URLs emitted by the host live-build config.
while IFS= read -r -d '' cfg; do
  sed -i \
    -e 's#bookworm/updates#bookworm-security#g' \
    -e 's#security\\.debian\\.org#deb.debian.org/debian-security#g' \
    "$cfg"
done < <(find config -type f -print0)

if grep -Rqs 'bookworm/updates' config; then
  echo "ERROR: obsolete Bookworm security suite remains in live-build config" >&2
  grep -Rns 'bookworm/updates' config >&2 || true
  exit 1
fi

mkdir -p \
  config/package-lists \
  config/includes.chroot/etc/systemd/system \
  config/includes.chroot/etc/default/grub.d \
  config/includes.chroot/etc/apt/sources.list.d \
  config/includes.chroot/etc/calamares \
  config/includes.chroot/usr/sbin \
  config/includes.chroot/opt/kodi-os \
  config/includes.chroot/usr/share/kodi/addons \
  config/hooks/live

# Re-enable the current Debian Bookworm security repository in the final OS.
cat > config/includes.chroot/etc/apt/sources.list.d/kodi-os-security.list <<'EOF'
deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

cp "$OS_DIR/package-lists/kodi-os.list.chroot" config/package-lists/
cp "$OS_DIR/systemd/kodi-os.target" config/includes.chroot/etc/systemd/system/

for service in "$OS_DIR"/*.service "$OS_DIR"/*.timer "$OS_DIR"/*.path; do
  [[ -f "$service" ]] || continue
  cp "$service" config/includes.chroot/etc/systemd/system/
done

for script in "$OS_DIR"/firstboot.sh "$OS_DIR"/kodi-os-* "$OS_DIR"/kodi-os-hardware.sh "$OS_DIR"/kodi-os-session-wrapper.sh; do
  [[ -f "$script" ]] || continue
  base="$(basename "$script")"
  cp "$script" "config/includes.chroot/usr/sbin/$base"
done

[[ -f "$OS_DIR/kodi-os-recovery-grub.cfg" ]] && cp "$OS_DIR/kodi-os-recovery-grub.cfg" config/includes.chroot/opt/kodi-os/
[[ -d "$OS_DIR/calamares" ]] && rsync -a "$OS_DIR/calamares/" config/includes.chroot/etc/calamares/

if [[ -d "$ROOT_DIR/addons/plugin.program.kodiosgames" ]]; then
  rm -rf config/includes.chroot/usr/share/kodi/addons/plugin.program.kodiosgames
  cp -a "$ROOT_DIR/addons/plugin.program.kodiosgames" config/includes.chroot/usr/share/kodi/addons/
fi

find config/includes.chroot/usr/sbin -type f -exec chmod 0755 {} +

if [[ -d "$OS_DIR/hooks/live" ]]; then
  rsync -a "$OS_DIR/hooks/live/" config/hooks/live/
  find config/hooks/live -type f -exec chmod 0755 {} +
fi

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