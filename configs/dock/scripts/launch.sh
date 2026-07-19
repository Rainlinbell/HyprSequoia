#!/usr/bin/env bash
# Launch a favorite, record it as recent, and refresh running indicators.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
init_state

# Add a known app to the bounded, newest-first recent list.
record_recent() {
  local app=$1 tmp
  tmp=$(mktemp "$DOCK_STATE_DIR/recent.XXXXXX")
  { printf '%s\n' "$app"; [[ -r $DOCK_HISTORY ]] && grep -Fxv "$app" "$DOCK_HISTORY"; } | head -n 8 >"$tmp" || true
  mv -- "$tmp" "$DOCK_HISTORY"
}

# Execute the first available command from a list.
run_first() {
  local command
  for command in "$@"; do
    if command -v "${command%% *}" >/dev/null 2>&1; then
      bash -c "$command" >/dev/null 2>&1 &
      return 0
    fi
  done
  return 1
}

app=${1:-menu}
if [[ $app == menu ]]; then
  choice=$(printf '%s\n' 'Firefox' 'VS Code' 'Terminal' 'Files' 'Settings' 'Recent Applications' | walker --dmenu -p 'Applications' 2>/dev/null || true)
  case $choice in
    Firefox) app=firefox;;
    'VS Code') app=code;;
    Terminal) app=terminal;;
    Files) app=files;;
    Settings) app=settings;;
    'Recent Applications') exec "$(dirname -- "$0")/recent.sh";;
    *) exit 0;;
  esac
fi
case $app in
  finder|files) record_recent "$app"; run_first thunar "xdg-open \"$HOME\"" || notify 'Dock' 'Install Thunar or a file manager.';;
  firefox) record_recent firefox; run_first firefox 'xdg-open https://www.mozilla.org/firefox/' || notify 'Dock' 'Firefox is not installed.';;
  code) record_recent code; run_first code codium 'kitty -e nvim' || notify 'Dock' 'VS Code, Codium, or Neovim is not installed.';;
  terminal) record_recent terminal; run_first kitty foot alacritty || notify 'Dock' 'No supported terminal is installed.';;
  settings) record_recent settings; run_first hyprsequoia-settings systemsettings gnome-control-center 'kitty -e nmtui' || notify 'Dock' 'No settings application is installed.';;
  *) notify 'Dock' "Unknown application: $app";;
esac
pkill -RTMIN+8 -x waybar 2>/dev/null || true
