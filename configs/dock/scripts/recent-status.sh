#!/usr/bin/env bash
# Report the number of recently launched favorite applications.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
count=0; [[ -r $DOCK_HISTORY ]] && count=$(wc -l <"$DOCK_HISTORY" | tr -d ' ')
status_json "  ${count:-0}" "Recent applications: ${count:-0}" recent
