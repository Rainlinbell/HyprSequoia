#!/usr/bin/env bash
# Conservatively remove Plasma while preserving SDDM and unrelated Qt apps.
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$ROOT/scripts/lib/common.sh"
require_user; require_arch
mapfile -t plasma < <(pacman -Qqg plasma 2>/dev/null || true)
((${#plasma[@]})) || { info "Plasma package group is not installed."; exit 0; }
printf 'The following Plasma group packages will be removed (SDDM is preserved):\n%s\n' "${plasma[*]}"
read -r -p 'Continue? [y/N] ' answer
[[ $answer =~ ^[Yy]$ ]] || exit 0
filtered=(); for package in "${plasma[@]}"; do [[ $package == sddm ]] || filtered+=("$package"); done
((${#filtered[@]})) && as_root pacman -Rns "${filtered[@]}"
read -r -p 'Move KDE user configuration to a backup? [y/N] ' answer
if [[ $answer =~ ^[Yy]$ ]]; then
  target="$HS_BACKUP_DIR/kde-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$target"
  for path in "$HOME/.config/kdeglobals" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$HOME/.config/plasmarc"; do [[ -e $path ]] && mv -- "$path" "$target/"; done
fi
info "Plasma removal complete; SDDM was not removed or disabled."
