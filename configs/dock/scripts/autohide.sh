#!/usr/bin/env bash
# Pointer-edge autohide watcher for the Waybar fallback backend.
set -Eeuo pipefail
pid=${1:?Waybar dock PID required}
state=hidden
trap 'exit 0' INT TERM EXIT
while kill -0 "$pid" 2>/dev/null; do
  near=false
  if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    cursor=$(hyprctl cursorpos -j 2>/dev/null || printf '{"x":0,"y":0}')
    x=$(jq -r '.x // 0' <<<"$cursor" 2>/dev/null || printf '0')
    y=$(jq -r '.y // 0' <<<"$cursor" 2>/dev/null || printf '0')
    # shellcheck disable=SC2016
    near=$(hyprctl monitors -j 2>/dev/null | jq --argjson x "$x" --argjson y "$y" 'any(.[]; ($x >= .x and $x < (.x + .width) and $y >= (.y + .height - 18) and $y <= (.y + .height + 8)))' 2>/dev/null || printf 'false')
  else
    near=true
  fi
  if [[ $near == true && $state != shown ]]; then
    kill -SIGUSR2 "$pid" 2>/dev/null || exit 0
    state=shown
  elif [[ $near != true && $state != hidden ]]; then
    kill -SIGUSR1 "$pid" 2>/dev/null || exit 0
    state=hidden
  fi
  sleep 0.25
done
