#!/usr/bin/env bash
# Select and launch an application from the bounded recent list.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
[[ -r $DOCK_HISTORY ]] || { notify 'Dock' 'No recent applications yet.'; exit 0; }
choice=$(while IFS= read -r app; do
  case $app in
    firefox) printf 'Firefox\n';;
    code) printf 'VS Code\n';;
    terminal) printf 'Terminal\n';;
    files|finder) printf 'Files\n';;
    settings) printf 'Settings\n';;
  esac
done <"$DOCK_HISTORY" | walker --dmenu -p 'Recent' 2>/dev/null || true)
case $choice in
  Firefox) exec "$(dirname -- "$0")/launch.sh" firefox;;
  'VS Code') exec "$(dirname -- "$0")/launch.sh" code;;
  Terminal) exec "$(dirname -- "$0")/launch.sh" terminal;;
  Files) exec "$(dirname -- "$0")/launch.sh" files;;
  Settings) exec "$(dirname -- "$0")/launch.sh" settings;;
esac
