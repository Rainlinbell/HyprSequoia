#!/usr/bin/env bash
# Compatibility entry point for the unified Tahoe appearance controller.
set -Eeuo pipefail
if command -v hyprsequoia-theme >/dev/null 2>&1; then
  exec hyprsequoia-theme "${1:-toggle}"
fi
printf 'hyprsequoia-theme is not installed; rerun the installer.\n' >&2
exit 1
