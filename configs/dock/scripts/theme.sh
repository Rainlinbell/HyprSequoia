#!/usr/bin/env bash
# Switch dock palettes and restart only the dock backend.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
config_dir=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprsequoia"
state_file="$state_dir/dock-theme"
mkdir -p "$state_dir"
current=dark; [[ -r $state_file ]] && current=$(<"$state_file")
case ${1:-toggle} in
  dark|light) next=$1;;
  toggle) [[ $current == dark ]] && next=light || next=dark;;
  *) printf 'Usage: %s [dark|light|toggle]\n' "$0" >&2; exit 2;;
esac
cp -- "$config_dir/theme-$next.css" "$config_dir/theme.css"
cp -- "$config_dir/nwg-style-$next.css" "$config_dir/nwg-style.css"
printf '%s\n' "$next" >"$state_file"
"$config_dir/scripts/dock.sh" restart
