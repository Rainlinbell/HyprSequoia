#!/usr/bin/env bash
# Search Settings desktop entries without introducing a second launcher.
set -Eeuo pipefail

roots=(/usr/share/applications "$HOME/.local/share/applications")
tmp=$(mktemp "${TMPDIR:-/tmp}/hyprsequoia-settings.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT

for root in "${roots[@]}"; do
  [[ -d $root ]] || continue
  find "$root" -maxdepth 1 -type f -name '*.desktop' -print0 2>/dev/null || true
done | while IFS= read -r -d '' file; do
  if ! grep -Eiq '^Categories=.*(Settings|System|HardwareSettings|X-GNOME-Settings-Panel)' "$file"; then
    continue
  fi
  name=$(awk -F= '$1 == "Name" { print substr($0, index($0, "=") + 1); exit }' "$file")
  [[ -n $name ]] || name=$(basename "$file" .desktop)
  printf '%s\t%s\n' "$name" "$file"
done | sort -f -u >"$tmp"

[[ -s $tmp ]] || exit 0
selected=$(walker --dmenu --prompt 'Settings' <"$tmp" || true)
[[ -n $selected ]] || exit 0
desktop_file=${selected#*$'\t'}
desktop_id=$(basename "$desktop_file" .desktop)
if command -v gtk-launch >/dev/null 2>&1; then
  gtk-launch "$desktop_id" >/dev/null 2>&1 &
elif command -v gio >/dev/null 2>&1; then
  gio launch "$desktop_file" >/dev/null 2>&1 &
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$desktop_file" >/dev/null 2>&1 &
fi
