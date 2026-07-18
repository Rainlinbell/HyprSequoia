#!/usr/bin/env bash
# Report Bluetooth power and connected-device count.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
command -v bluetoothctl >/dev/null 2>&1 || { status_json '' 'bluetoothctl is not installed.' unavailable; exit 0; }
powered=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/{print $2; exit}')
if [[ $powered != yes ]]; then status_json '󰂲' 'Bluetooth is off' disabled; exit 0; fi
connected=$(bluetoothctl devices Connected 2>/dev/null | wc -l | tr -d ' ')
if [[ ${connected:-0} -gt 0 ]]; then status_json "  $connected" "Bluetooth: $connected connected" connected
else status_json '' 'Bluetooth is on; no connected devices' idle; fi
