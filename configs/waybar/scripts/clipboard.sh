#!/usr/bin/env bash
# Show clipboard availability and open cliphist when requested.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
if [[ ${1:-status} == menu ]]; then
  command -v cliphist >/dev/null 2>&1 || { notify 'Clipboard History' 'Install cliphist to enable history.'; exit 0; }
  choice=$(cliphist list | walker --dmenu -p 'Clipboard' 2>/dev/null || true)
  [[ -n $choice ]] && printf '%s' "$choice" | cliphist decode | wl-copy
  exit 0
fi
if command -v cliphist >/dev/null 2>&1; then
  count=$(cliphist list 2>/dev/null | wc -l | tr -d ' ')
  status_json "  ${count:-0}" "Clipboard history: ${count:-0} items" clipboard
elif command -v wl-paste >/dev/null 2>&1; then
  status_json '' 'Clipboard history is not installed; current clipboard is available.' clipboard
else
  status_json '' 'wl-clipboard is not installed.' unavailable
fi
