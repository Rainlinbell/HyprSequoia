#!/usr/bin/env bash
# Render a compact date and open an available calendar application.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
if [[ ${1:-status} == open ]]; then
  if command -v gnome-calendar >/dev/null 2>&1; then gnome-calendar >/dev/null 2>&1 &
  elif command -v khal >/dev/null 2>&1 && command -v kitty >/dev/null 2>&1; then kitty --hold khal interactive >/dev/null 2>&1 &
  else notify 'Calendar' "$(date '+%A, %B %d, %Y')"; fi
  exit 0
fi
today=$(LC_TIME=C date '+%a %b %d')
status_json "  $today" "$(date '+%A, %B %d, %Y')" calendar
