#!/usr/bin/env bash
# Capture a region or output for the File menu.
set -Eeuo pipefail
target="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$target"
file="$target/$(date +%Y-%m-%d_%H-%M-%S).png"
case ${1:-region} in
  region) geometry=$(slurp) || exit 0; grim -g "$geometry" "$file";;
  screen) grim "$file";;
  *) printf 'Usage: %s [region|screen]\n' "$0" >&2; exit 2;;
esac
wl-copy <"$file"
notify-send 'Screenshot saved' "$file" 2>/dev/null || true
