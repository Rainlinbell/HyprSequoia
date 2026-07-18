#!/usr/bin/env bash
# Switch the imported Waybar palette and reload all Waybar instances.
set -Eeuo pipefail
script_dir=$(cd -- "$(dirname -- "$0")" && pwd -P)
config_dir=$(cd -- "$script_dir/.." && pwd -P)
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprsequoia"
state_file="$state_dir/waybar-theme"
mkdir -p "$state_dir"
current=dark
[[ -r $state_file ]] && current=$(<"$state_file")
case ${1:-toggle} in
  dark|light) next=$1;;
  toggle) [[ $current == dark ]] && next=light || next=dark;;
  *) printf 'Usage: %s [dark|light|toggle]\n' "$0" >&2; exit 2;;
esac
cp -- "$config_dir/theme-$next.css" "$config_dir/theme.css"
printf '%s\n' "$next" >"$state_file"
killall -SIGUSR2 waybar 2>/dev/null || true
notify-send 'Appearance' "Waybar theme: $next" 2>/dev/null || true
