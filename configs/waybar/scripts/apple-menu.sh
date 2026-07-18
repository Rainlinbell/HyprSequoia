#!/usr/bin/env bash
# Open the Apple-logo session menu in Walker's layer-shell popup.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
choice=$(printf '%s\n' 'About HyprSequoia' 'System Settings' 'Lock Screen' 'Sleep' 'Restart' 'Shutdown' 'Logout' | walker --dmenu -p 'HyprSequoia' 2>/dev/null || true)
case $choice in
  'About HyprSequoia') notify 'HyprSequoia' 'A modular macOS-inspired Hyprland desktop.' ;;
  'System Settings')
    if command -v systemsettings >/dev/null 2>&1; then systemsettings
    elif command -v gnome-control-center >/dev/null 2>&1; then gnome-control-center
    else notify 'System Settings' 'No graphical settings center is installed.'; fi ;;
  'Lock Screen') loginctl lock-session ;;
  'Sleep') systemctl suspend ;;
  'Restart') systemctl reboot ;;
  'Shutdown') systemctl poweroff ;;
  'Logout') hyprctl dispatch exit ;;
esac
