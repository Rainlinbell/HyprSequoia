#!/usr/bin/env bash
# Open the Tahoe-styled SwayNC Control Center.
set -Eeuo pipefail
if command -v swaync-client >/dev/null 2>&1; then
  exec swaync-client -t -sw
fi
exec walker --dmenu -p 'Control Center'
