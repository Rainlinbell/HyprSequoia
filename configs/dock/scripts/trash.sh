#!/usr/bin/env bash
# Display, open, or empty the freedesktop Trash.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
case ${1:-status} in
  status)
    if command -v gio >/dev/null 2>&1; then
      count=$(gio trash --list 2>/dev/null | wc -l | tr -d ' ')
      if ((count > 0)); then status_json "  $count" "Trash: $count items (right-click to empty)" full
      else status_json '' 'Trash is empty' empty; fi
    else status_json '' 'gio is not installed.' unavailable; fi;;
  open) xdg-open trash:/// >/dev/null 2>&1 & ;;
  empty)
    if command -v gio >/dev/null 2>&1; then
      read -r -p 'Empty the Trash? [y/N] ' answer < /dev/tty || answer=n
      [[ $answer =~ ^[Yy]$ ]] && gio trash --empty
    fi;;
  *) printf 'Usage: %s [status|open|empty]\n' "$0" >&2; exit 2;;
esac
