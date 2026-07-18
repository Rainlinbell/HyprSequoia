#!/usr/bin/env bash
# Shared, side-effect-free helpers for HyprSequoia lifecycle scripts.

set -Eeuo pipefail

readonly HS_NAME="HyprSequoia"
readonly HS_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/hyprsequoia"
readonly HS_LOG_DIR="$HS_STATE_HOME/logs"
readonly HS_BACKUP_DIR="$HS_STATE_HOME/backups"
readonly HS_MANIFEST="$HS_STATE_HOME/installed-files"

# Print an informational message.
info() { printf '\033[1;34m[%s]\033[0m %s\n' "$HS_NAME" "$*"; }
# Print a warning.
warn() { printf '\033[1;33m[%s]\033[0m %s\n' "$HS_NAME" "$*" >&2; }
# Print an error and terminate.
die() { printf '\033[1;31m[%s]\033[0m %s\n' "$HS_NAME" "$*" >&2; exit 1; }
# Return success when a command exists.
has() { command -v "$1" >/dev/null 2>&1; }
# Require a regular, non-root user.
require_user() { [[ ${EUID:-$(id -u)} -ne 0 ]] || die "Run this command as your user, not root."; }
# Require Arch Linux.
require_arch() { [[ -r /etc/arch-release ]] || die "HyprSequoia supports Arch Linux only."; }
# Run a command with sudo after verifying sudo exists.
as_root() { has sudo || die "sudo is required."; sudo "$@"; }
# Create private state directories.
init_state() { umask 077; mkdir -p "$HS_LOG_DIR" "$HS_BACKUP_DIR"; }
# Resolve the repository root independently of the caller's directory.
repo_root() { cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P; }
# Copy a directory tree and record installed files for safe restore.
install_tree() {
  local source=$1 destination=$2 file relative
  mkdir -p "$destination"
  while IFS= read -r -d '' file; do
    relative=${file#"$source"/}
    install -Dm644 "$file" "$destination/$relative"
    printf '%s\n' "$destination/$relative" >>"$HS_MANIFEST"
  done < <(find "$source" -type f -print0)
}
