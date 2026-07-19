#!/usr/bin/env bash
# Restore the latest pre-install configuration backup.
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$ROOT/scripts/lib/common.sh"
require_user; init_state
[[ -r $HS_STATE_HOME/latest-backup ]] || die "No backup is recorded."
backup=$(<"$HS_STATE_HOME/latest-backup")
[[ -d $backup/config ]] || die "Backup is missing: $backup"
read -r -p 'Restore the latest backup and replace managed configuration? [y/N] ' answer
[[ $answer =~ ^[Yy]$ ]] || exit 0
if [[ -r $HS_MANIFEST ]]; then while IFS= read -r file; do [[ -f $file ]] && rm -f -- "$file"; done <"$HS_MANIFEST"; fi
cp -a "$backup/config/." "$HOME/.config/"
info "Restored $backup"
