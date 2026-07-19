#!/usr/bin/env bash
# Shared helpers for Waybar status modules.
set -Eeuo pipefail

# Escape a value for a JSON string without requiring jq in minimal installs.
json_escape() {
  local value=${1-}
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/ }
  value=${value//$'\r'/ }
  printf '%s' "$value"
}

# Print one Waybar custom-module JSON response.
status_json() {
  local text=$1 tooltip=${2:-} class=${3:-}
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(json_escape "$text")" "$(json_escape "$tooltip")" "$(json_escape "$class")"
}

# Send a desktop notification when notify-send is installed.
notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$@" || true
  fi
}
