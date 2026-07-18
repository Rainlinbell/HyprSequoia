#!/usr/bin/env bash
# Keyboard-only recent-file picker. It intentionally scans common XDG folders
# instead of adding a database daemon or a heavyweight indexer.
set -Eeuo pipefail

export PATH="$HOME/.local/bin:$PATH"
tmp=$(mktemp "${TMPDIR:-/tmp}/hyprsequoia-recent.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT

roots=()
if command -v xdg-user-dir >/dev/null 2>&1; then
  for key in DOCUMENTS DOWNLOAD DESKTOP PICTURES VIDEOS MUSIC; do
    dir=$(xdg-user-dir "$key" 2>/dev/null || true)
    [[ -d $dir ]] && roots+=("$dir")
  done
fi
for dir in "$HOME/Documents" "$HOME/Downloads" "$HOME/Desktop" "$HOME/Pictures" "$HOME/Videos" "$HOME/Music"; do
  [[ -d $dir ]] && roots+=("$dir")
done

if ((${#roots[@]})); then
  printf '%s\n' "${roots[@]}" | awk '!seen[$0]++' | while IFS= read -r dir; do
    find "$dir" -maxdepth 3 -type f -printf '%T@ %p\n' 2>/dev/null || true
  done | sort -nr | cut -d' ' -f2- | awk '!seen[$0]++ { if (count < 80) print; count++ }' >"$tmp"
fi

if [[ ! -s $tmp ]]; then
  command -v notify-send >/dev/null 2>&1 && notify-send 'HyprSequoia Spotlight' 'No recent files found.'
  exit 0
fi

selected=$(walker --dmenu --prompt 'Recent files' <"$tmp" || true)
[[ -n $selected ]] || exit 0
if command -v gio >/dev/null 2>&1; then
  gio open "$selected" >/dev/null 2>&1 &
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$selected" >/dev/null 2>&1 &
fi
