#!/usr/bin/env bash
# Update a Git checkout from its remote branch, then redeploy it transactionally.
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"

require_user
require_arch
has git || die "git is required."
git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "Updates require a Git checkout. Clone the repository instead of using a source archive."
[[ -z $(git -C "$ROOT" status --porcelain) ]] \
  || die "Commit or stash repository changes before updating."

current_branch=$(git -C "$ROOT" symbolic-ref --quiet --short HEAD) \
  || die "The checkout is detached. Switch to a local branch before updating."
upstream=$(git -C "$ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)

if [[ -n $upstream && $upstream == */* ]]; then
  remote=${upstream%%/*}
  remote_branch=${upstream#*/}
else
  remote=origin
  remote_head=$(git -C "$ROOT" symbolic-ref --quiet --short "refs/remotes/$remote/HEAD" 2>/dev/null || true)
  remote_branch=${remote_head#"$remote/"}
  [[ -n $remote_branch && $remote_branch != "$remote_head" ]] || remote_branch=main
  warn "Branch $current_branch has no upstream; using $remote/$remote_branch."
fi

git -C "$ROOT" remote get-url "$remote" >/dev/null 2>&1 \
  || die "Git remote '$remote' is not configured."

before=$(git -C "$ROOT" rev-parse --short=12 HEAD)
info "Checking $remote/$remote_branch for updates (local branch: $current_branch)."
if ! git -C "$ROOT" fetch --prune "$remote" "$remote_branch"; then
  warn "The first Git fetch failed; retrying once with HTTPS over HTTP/1.1."
  warn "TLS certificate verification remains enabled."
  git -C "$ROOT" -c http.version=HTTP/1.1 fetch --prune "$remote" "$remote_branch"
fi
git -C "$ROOT" merge --ff-only FETCH_HEAD
after=$(git -C "$ROOT" rev-parse --short=12 HEAD)

if [[ $before == "$after" ]]; then
  info "Repository is already current at $after."
else
  info "Repository updated: $before -> $after."
fi

info "Starting the installer to deploy commit $after."
info "The update is not installed until the installer finishes successfully."
exec "$ROOT/install.sh"
