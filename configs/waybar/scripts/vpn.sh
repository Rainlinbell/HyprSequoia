#!/usr/bin/env bash
# Report the active NetworkManager VPN without exposing connection details.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
if ! command -v nmcli >/dev/null 2>&1; then status_json '󰖂' 'NetworkManager is not installed.' unavailable; exit 0; fi
vpn=$(nmcli -t -f TYPE,NAME connection show --active 2>/dev/null | awk -F: '$1 ~ /vpn|wireguard/ {print $2; exit}')
if [[ -n ${vpn:-} ]]; then status_json '󰖂  VPN' "VPN connected: $vpn" connected
else status_json '󰖂' 'VPN disconnected' disconnected; fi
