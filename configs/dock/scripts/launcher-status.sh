#!/usr/bin/env bash
# Return a launcher icon with idle, running, or active state.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
app=${1:?application id required}; icon=${2:?icon required}
label=$app; pattern=''
case $app in
  finder|files) label='Files'; pattern='thunar|org\.xfce\.thunar';;
  firefox) label='Firefox'; pattern='firefox';;
  code) label='VS Code'; pattern='code|codium';;
  terminal) label='Terminal'; pattern='kitty|foot|alacritty|wezterm';;
  settings) label='Settings'; pattern='systemsettings|gnome-control-center';;
esac
class=idle; count=0
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  clients=$(hyprctl clients -j 2>/dev/null || printf '[]')
  # shellcheck disable=SC2016
  count=$(jq --arg pattern "$pattern" '[.[] | select((.class // "" | ascii_downcase | test($pattern)))] | length' <<<"$clients" 2>/dev/null || printf '0')
  active=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""' 2>/dev/null || true)
  if [[ $active =~ $pattern ]]; then
    class=active
  elif ((count > 0)); then
    class=running
  fi
fi
status_json "$icon" "$label — $count running" "$class"
