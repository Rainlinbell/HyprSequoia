#!/usr/bin/env bash
# Update a Git checkout and reinstall while preserving a rollback point.
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$ROOT/scripts/lib/common.sh"
require_user; require_arch
has git || die "git is required."
[[ -d $ROOT/.git ]] || die "Updates require a Git checkout."
[[ -z $(git -C "$ROOT" status --porcelain) ]] || die "Commit or stash repository changes before updating."
git -C "$ROOT" pull --ff-only
exec "$ROOT/install.sh"
