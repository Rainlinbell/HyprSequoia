#!/usr/bin/env bash
# Open a compact Control Center action palette.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
choice=$(printf '%s\n' 'Wi-Fi and Network' 'Bluetooth' 'VPN' 'Brightness Up' 'Brightness Down' 'Sound Settings' 'Microphone' 'Night Shift' 'Toggle Light/Dark Mode' 'Notification Center' | walker --dmenu --prompt 'Control Center' 2>/dev/null || true)
case $choice in
  'Wi-Fi and Network') nm-connection-editor >/dev/null 2>&1 &;;
  'Bluetooth') blueman-manager >/dev/null 2>&1 &;;
  'VPN') nm-connection-editor >/dev/null 2>&1 &;;
  'Brightness Up') brightnessctl set 5%+;;
  'Brightness Down') brightnessctl set 5%-;;
  'Sound Settings') pavucontrol >/dev/null 2>&1 &;;
  'Microphone') pavucontrol --tab=4 >/dev/null 2>&1 &;;
  'Night Shift')
    if command -v gammastep >/dev/null 2>&1; then gammastep -O 4000
    else notify 'Night Shift' 'Install gammastep to control night color temperature.'; fi;;
  'Toggle Light/Dark Mode') "$(dirname -- "$0")/theme.sh" toggle;;
  'Notification Center') swaync-client -t -sw;;
esac
