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
  local command pid
  for command in "$@"; do
    if command -v "${command%% *}" >/dev/null 2>&1; then
      bash -c "$command" >/dev/null 2>&1 &
      pid=$!
      # Catch missing subcommands and immediate startup failures without
      # blocking on a normally running GUI process.
      for _ in 1 2 3; do
        sleep 0.05
        if ! kill -0 "$pid" 2>/dev/null; then
          if wait "$pid"; then return 0; fi
          pid=''
          break
        fi
      done
      if [[ -n $pid ]]; then
        if kill -0 "$pid" 2>/dev/null; then return 0
        elif wait "$pid"; then return 0; fi
      fi
    fi
  done
  return 1
}

open_target() {
  command -v xdg-open >/dev/null 2>&1 || return 1
  xdg-open "$1" >/dev/null 2>&1
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
  finder|files)
    record_recent "$app"
    run_first thunar || open_target "$HOME" || notify 'Dock' 'Install Thunar or a file manager.';;
  firefox)
    record_recent firefox
    run_first firefox || open_target 'https://www.mozilla.org/firefox/' || notify 'Dock' 'Firefox is not installed.';;
  code)
    record_recent code
    if run_first code codium; then :
    elif command -v kitty >/dev/null 2>&1 && command -v nvim >/dev/null 2>&1; then
      run_first 'kitty -e nvim' || notify 'Dock' 'Neovim could not be started.'
    else
      notify 'Dock' 'VS Code, Codium, or Neovim is not installed.'
    fi;;
  terminal) record_recent terminal; run_first kitty foot alacritty || notify 'Dock' 'No supported terminal is installed.';;
  settings)
    record_recent settings
    if run_first hyprsequoia-settings systemsettings gnome-control-center; then :
    elif command -v kitty >/dev/null 2>&1 && command -v nmtui >/dev/null 2>&1; then
      run_first 'kitty -e nmtui' || notify 'Dock' 'Network settings could not be started.'
    else
      notify 'Dock' 'No settings application is installed.'
    fi;;
  *) notify 'Dock' "Unknown application: $app";;
esac
pkill -RTMIN+8 -x waybar 2>/dev/null || true
