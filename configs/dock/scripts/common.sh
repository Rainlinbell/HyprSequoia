#!/usr/bin/env bash
# Shared state, JSON, and notification helpers for the dock.
set -Eeuo pipefail

# HyprSequoia deploys user configuration under ~/.config, matching the main
# installer and the paths used by the Waybar JSONC file.
readonly DOCK_CONFIG_DIR="$HOME/.config/dock"
readonly DOCK_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprsequoia/dock"
readonly DOCK_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
# These constants are consumed by the scripts that source this library.
# shellcheck disable=SC2034
readonly \
  DOCK_PID_FILE="$DOCK_RUNTIME_DIR/hyprsequoia-dock.pid" \
  DOCK_WATCHER_PID_FILE="$DOCK_RUNTIME_DIR/hyprsequoia-dock-autohide.pid" \
  DOCK_BACKEND_FILE="$DOCK_RUNTIME_DIR/hyprsequoia-dock-backend" \
  DOCK_HISTORY="$DOCK_STATE_DIR/recent" \
  DOCK_FAVORITES="$DOCK_CONFIG_DIR/favorites.list"

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
