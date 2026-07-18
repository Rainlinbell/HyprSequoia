#!/usr/bin/env bash
# Open a contextual File/Edit/View/Window/Help menu.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
menu=${1:-Help}
case $menu in
  File) entries=('Open File Manager' 'New Terminal' 'Region Screenshot' 'Full Screenshot');;
  Edit) entries=('Clipboard History' 'Copy Active Window Title');;
  View) entries=('Toggle Fullscreen' 'Toggle Floating' 'Reload Hyprland');;
  Window) entries=('Close Window' 'Focus Left' 'Focus Right' 'Focus Up' 'Focus Down');;
  *) entries=('Open Troubleshooting Guide' 'Open Project Homepage' 'About HyprSequoia');;
esac
choice=$(printf '%s\n' "${entries[@]}" | walker --dmenu -p "$menu" 2>/dev/null || true)
case $choice in
  'Open File Manager') thunar >/dev/null 2>&1 & ;;
  'New Terminal') kitty >/dev/null 2>&1 & ;;
  'Region Screenshot') ~/.config/waybar/scripts/screenshot.sh region;;
  'Full Screenshot') ~/.config/waybar/scripts/screenshot.sh screen;;
  'Clipboard History') ~/.config/waybar/scripts/clipboard.sh menu;;
  'Copy Active Window Title') hyprctl activewindow -j | wl-copy;;
  'Toggle Fullscreen') hyprctl dispatch fullscreen;;
  'Toggle Floating') hyprctl dispatch togglefloating;;
  'Reload Hyprland') hyprctl reload;;
  'Close Window') hyprctl dispatch killactive;;
  'Focus Left') hyprctl dispatch movefocus l;;
  'Focus Right') hyprctl dispatch movefocus r;;
  'Focus Up') hyprctl dispatch movefocus u;;
  'Focus Down') hyprctl dispatch movefocus d;;
  'Open Troubleshooting Guide') xdg-open 'https://github.com/Rainlinbell/HyprSequoia/blob/main/docs/TROUBLESHOOTING.md' >/dev/null 2>&1 & ;;
  'Open Project Homepage') xdg-open 'https://github.com/Rainlinbell/HyprSequoia' >/dev/null 2>&1 & ;;
  'About HyprSequoia') notify 'HyprSequoia' 'A modular macOS-inspired Hyprland desktop.';;
esac
