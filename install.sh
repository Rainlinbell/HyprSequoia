#!/usr/bin/env bash
# Interactive, transactional installer for HyprSequoia.

set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"
# shellcheck source=scripts/lib/packages.sh
source "$ROOT/scripts/lib/packages.sh"

HS_PROFILE=full HS_CHINESE=0 HS_GPU=auto HS_REMOVE_KDE=0 COMMITTED=0 BACKUP=""

# Restore the backup made by this run after an unexpected failure.
rollback() {
  local status=$?
  if ((status != 0)) && [[ $COMMITTED == 0 && -n $BACKUP && -d $BACKUP/config ]]; then
    warn "Installation failed; restoring the configuration backup."
    rm -rf -- "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/kitty" "$HOME/.config/walker" "$HOME/.config/swaync" "$HOME/.config/dock"
    cp -a "$BACKUP/config/." "$HOME/.config/"
  fi
  exit "$status"
}
trap rollback EXIT

# Display the installer menu and apply the selected mode.
choose_profile() {
  printf '\nHyprSequoia installer\n  1) Full install\n  2) Minimal install\n  3) Chinese environment\n  4) NVIDIA profile\n  5) AMD profile\n  6) Intel profile\n  7) Remove KDE Plasma after install\n  8) Restore latest backup\n  9) Exit\n'
  read -r -p 'Select [1]: ' choice
  case ${choice:-1} in
    1) HS_PROFILE=full;; 2) HS_PROFILE=minimal;; 3) HS_PROFILE=full; HS_CHINESE=1;;
    4) HS_GPU=nvidia;; 5) HS_GPU=amd;; 6) HS_GPU=intel;; 7) HS_REMOVE_KDE=1;;
    8) exec "$ROOT/restore.sh";; 9) exit 0;; *) die "Unknown selection.";;
  esac
}

# Detect graphics hardware when no explicit profile was selected.
detect_gpu() {
  [[ $HS_GPU != auto ]] && return
  local devices; devices=$(lspci -nnk 2>/dev/null || true)
  if grep -qi nvidia <<<"$devices"; then HS_GPU=nvidia
  elif grep -Eqi 'amd|ati' <<<"$devices"; then HS_GPU=amd
  elif grep -qi intel <<<"$devices"; then HS_GPU=intel
  else HS_GPU=unknown; fi
  info "Detected GPU profile: $HS_GPU"
}

# Report whether installation is running inside an existing Wayland session.
detect_session() {
  if [[ ${XDG_SESSION_TYPE:-} == wayland ]]; then
    info "Wayland session detected."
  else
    info "No active Wayland session detected; installation from a TTY or another desktop is supported."
  fi
}

# Back up only configuration trees managed by HyprSequoia.
backup_config() {
  BACKUP="$HS_BACKUP_DIR/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP/config"
  local item
  for item in hypr waybar kitty walker swaync dock; do
    [[ -e $HOME/.config/$item ]] && cp -a "$HOME/.config/$item" "$BACKUP/config/"
  done
  printf '%s\n' "$BACKUP" >"$HS_STATE_HOME/latest-backup"
}

# Install configurations and executable helpers.
deploy() {
  : >"$HS_MANIFEST"
  local component
  for component in hypr waybar kitty walker swaync dock; do
    install_tree "$ROOT/configs/$component" "$HOME/.config/$component"
  done
  # Preserve a user's reordered Dock favorites across updates and reinstalls.
  if [[ -r $BACKUP/config/dock/favorites.list ]]; then
    install -Dm644 "$BACKUP/config/dock/favorites.list" "$HOME/.config/dock/favorites.list"
  fi
  # Waybar's custom modules are executable entry points, unlike ordinary CSS/JSON files.
  for script_dir in "$HOME/.config/waybar/scripts" "$HOME/.config/dock/scripts"; do
    if [[ -d $script_dir ]]; then
      while IFS= read -r -d '' script; do chmod 755 "$script"; done < <(find "$script_dir" -type f -name '*.sh' -print0)
    fi
  done
  install_tree "$ROOT/themes" "$HOME/.local/share/hyprsequoia/themes"
  local script
  for script in "$ROOT/scripts/bin/"*; do
    install -Dm755 "$script" "$HOME/.local/bin/$(basename "$script")"
    printf '%s\n' "$HOME/.local/bin/$(basename "$script")" >>"$HS_MANIFEST"
  done
  sed -i "s/__GPU_PROFILE__/$HS_GPU/" "$HOME/.config/hypr/conf.d/10-environment.conf"
  if [[ $HS_CHINESE == 1 ]]; then
    install -Dm644 "$ROOT/configs/fcitx5/profile" "$HOME/.config/fcitx5/profile"
    printf '%s\n' "$HOME/.config/fcitx5/profile" >>"$HS_MANIFEST"
    printf '%s\n' \
      'env = XMODIFIERS,@im=fcitx' \
      'env = QT_IM_MODULE,fcitx' \
      'env = SDL_IM_MODULE,fcitx' \
      >>"$HOME/.config/hypr/conf.d/10-environment.conf"
    printf '\nexec-once = fcitx5 -d\n' >>"$HOME/.config/hypr/conf.d/60-autostart.conf"
  fi
}

main() {
  require_user; require_arch; init_state; choose_profile; detect_session; detect_gpu
  exec > >(tee -a "$HS_LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log") 2>&1
  info "Installing $HS_PROFILE profile."
  install_packages; backup_config; deploy; enable_services
  [[ $HS_REMOVE_KDE == 1 ]] && "$ROOT/uninstall-kde.sh"
  COMMITTED=1
  info "Installation complete. Log out, select Hyprland in SDDM, and sign in."
}
main "$@"
