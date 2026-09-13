# Kodi OS

This directory turns the Kodi source tree into a bootable, appliance-style Linux image.

## Goals

- UEFI-bootable ISO for x86_64
- Kodi launches automatically as the graphical shell
- systemd-based appliance lifecycle
- no normal desktop environment dependency
- persistent writable data under `/storage`
- safe first-run configuration
- optional source-build path for the Kodi tree
- reproducible build entrypoint and SHA256 output

## Build host

The supported build host is Debian/Ubuntu Linux (or WSL2 with a Linux filesystem). The build needs root privileges, `live-build`, Docker/VM isolation is recommended, and at least 30 GB free space. A source build can require substantially more.

```bash
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools dosfstools rsync git ca-certificates
sudo ./os/build-iso.sh
```

Output is written to `build/artifacts/`.

## Build modes

The default mode uses the distribution Kodi package so the image can be produced quickly and predictably. Set `KODI_SOURCE_BUILD=1` to request building Kodi from this checkout inside the image build environment. Source builds are intentionally opt-in because Kodi's native dependency graph is large and varies by distribution release.

```bash
sudo KODI_SOURCE_BUILD=1 ./os/build-iso.sh
```

## Boot

The resulting ISO is intended for UEFI x86_64 systems. Test it in a VM first, then write it to a USB device. Installation to an internal disk is a separate, destructive operation and is not performed by the ISO builder.

## Architecture

```text
UEFI
  -> GRUB
    -> Linux kernel + initramfs
      -> systemd
        -> kodi-os-firstboot.service
        -> kodi-os-session.service
          -> Kodi fullscreen shell

/storage
  ├── userdata
  ├── media
  └── state
```

The OS layer deliberately does not modify Kodi's upstream application architecture. It supplies the appliance/runtime layer around it, leaving a clean boundary for the later JARVIS integration.