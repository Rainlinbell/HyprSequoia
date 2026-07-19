#!/usr/bin/env bash
# Shared state, JSON, and notification helpers for the dock.
set -Eeuo pipefail

# HyprSequoia deploys user configuration under ~/.config, matching the main
# installer and the paths used by the Waybar JSONC file.
readonly DOCK_CONFIG_DIR="$HOME/.config/dock"
readonly DOCK_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprsequoia/dock"
readonly DOCK_RUNTIME_DIR="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}/hyprsequoia-$UID}"
# These constants are consumed by the scripts that source this library.
# shellcheck disable=SC2034
readonly \
  DOCK_PID_FILE="$DOCK_RUNTIME_DIR/hyprsequoia-dock.pid" \
  DOCK_WATCHER_PID_FILE="$DOCK_RUNTIME_DIR/hyprsequoia-dock-autohide.pid" \
  DOCK_BACKEND_FILE="$DOCK_RUNTIME_DIR/hyprsequoia-dock-backend" \
  DOCK_HISTORY="$DOCK_STATE_DIR/recent" \
  DOCK_FAVORITES="$DOCK_CONFIG_DIR/favorites.list" \
  DOCK_RUST_PIN_FILE="$HOME/.cache/mac-dock-pinned" \
  DOCK_GO_PIN_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/nwg-dock-pinned"

# Escape a shell value for a Waybar JSON response.
json_escape() {
  local value=${1-}
  value=${value//\\/\\\\}; value=${value//\"/\\\"}
  value=${value//$'\n'/ }; value=${value//$'\r'/ }
  printf '%s' "$value"
}

# Print a custom-module response with text, tooltip, and CSS class.
status_json() {
  local text=$1 tooltip=${2:-} class=${3:-}
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(json_escape "$text")" "$(json_escape "$tooltip")" "$(json_escape "$class")"
}

# Notify if a notification daemon is available.
notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$@" || true
  fi
}

# Create private state storage.
init_state() { umask 077; mkdir -p "$DOCK_STATE_DIR"; }

# Prefer a real desktop ID when the application is installed, so the native
# backend can merge its pin with the matching Hyprland client class. Proxies
# keep the same button useful on minimal installations.
dock_pin_id() {
  case $1 in
    finder|thunar|Thunar|hyprsequoia-finder)
      if command -v thunar >/dev/null 2>&1; then printf '%s\n' thunar
      else printf '%s\n' hyprsequoia-finder; fi;;
    firefox|hyprsequoia-firefox)
      if command -v firefox >/dev/null 2>&1; then printf '%s\n' firefox
      else printf '%s\n' hyprsequoia-firefox; fi;;
    code|Code|code-oss|hyprsequoia-code)
      if command -v code-oss >/dev/null 2>&1; then printf '%s\n' code-oss
      elif command -v code >/dev/null 2>&1; then printf '%s\n' code
      elif command -v codium >/dev/null 2>&1; then printf '%s\n' codium
      else printf '%s\n' hyprsequoia-code; fi;;
    terminal|kitty|hyprsequoia-terminal)
      if command -v kitty >/dev/null 2>&1; then printf '%s\n' kitty
      elif command -v foot >/dev/null 2>&1; then printf '%s\n' foot
      elif command -v alacritty >/dev/null 2>&1; then printf '%s\n' Alacritty
      else printf '%s\n' hyprsequoia-terminal; fi;;
    files|hyprsequoia-files) printf '%s\n' hyprsequoia-files;;
    settings|systemsettings|hyprsequoia-settings|hyprsequoia-dock-settings)
      printf '%s\n' hyprsequoia-dock-settings;;
    *) printf '%s\n' "$1";;
  esac
}

normalize_dock_pins() {
  local id
  while IFS= read -r id; do
    [[ -n $id && $id != \#* ]] || continue
    dock_pin_id "$id"
  done | awk 'NF && !seen[$0]++'
}
