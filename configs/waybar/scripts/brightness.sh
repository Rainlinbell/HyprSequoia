#!/usr/bin/env bash
# Report the first backlight device as a compact menu-bar icon.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
if ! command -v brightnessctl >/dev/null 2>&1; then
  status_json '󰃞' 'brightnessctl is not installed.' unavailable
  exit 0
fi
percent=$(brightnessctl -m 2>/dev/null | awk -F, 'NR==1 {gsub(/%/,"",$4); print $4}')
[[ $percent =~ ^[0-9]+$ ]] || percent=0
if ((percent >= 67)); then icon='󰃠'
elif ((percent >= 34)); then icon='󰃟'
else icon='󰃞'; fi
status_json "$icon" "Brightness: ${percent}%" brightness
