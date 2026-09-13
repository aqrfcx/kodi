#!/usr/bin/env bash
set -Eeuo pipefail
systemctl enable kodi-os-firstboot.service
systemctl enable kodi-os-session.service
