#!/usr/bin/env bash
# Small, reversible actions exposed through a keyboard-only Walker menu.
set -Eeuo pipefail

options=$(cat <<'EOF'
Lock Screen
Show Dock
Toggle Light / Dark Mode
Reload Hyprland
Reload Waybar
Region Screenshot
Open System Settings
EOF
)
choice=$(printf '%s\n' "$options" | walker --dmenu --prompt 'Quick actions' || true)
case "$choice" in
  'Lock Screen') loginctl lock-session ;;
  'Show Dock') "$HOME/.config/dock/scripts/dock.sh" show ;;
  'Toggle Light / Dark Mode') hyprsequoia-theme toggle ;;
  'Reload Hyprland') hyprctl reload ;;
  'Reload Waybar') pkill -USR2 -x waybar 2>/dev/null || true ;;
  'Region Screenshot') hyprsequoia-screenshot region ;;
  'Open System Settings')
    if command -v hyprsequoia-settings >/dev/null 2>&1; then hyprsequoia-settings &
    elif command -v systemsettings >/dev/null 2>&1; then systemsettings &
    elif command -v gnome-control-center >/dev/null 2>&1; then gnome-control-center &
    fi
    ;;
esac
