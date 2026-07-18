#!/usr/bin/env bash
# Interactive, transactional installer for HyprSequoia.

set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"
# shellcheck source=scripts/lib/packages.sh
source "$ROOT/scripts/lib/packages.sh"

HS_PROFILE=full HS_CHINESE=0 HS_GPU=auto HS_REMOVE_KDE=0 COMMITTED=0 BACKUP="" DISABLED_LUA=""
HS_HAS_NVIDIA=0 HS_HAS_AMD=0 HS_HAS_INTEL=0

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

# Validate the deployed legacy config without starting a compositor. Hyprland
# added --verify-config in 0.47; current Arch releases all support it. Keeping
# this check before service activation prevents a bad config from becoming an
# SDDM login loop and leaves the verification output in the state log.
validate_hyprland_config() {
  local config="$HOME/.config/hypr/hyprland.conf" verify_log hypr_bin help rc
  [[ -r $config ]] || die "Hyprland config was not deployed: $config"
  if has Hyprland; then
    hypr_bin=Hyprland
  elif has hyprland; then
    hypr_bin=hyprland
  else
    warn "Hyprland is not in PATH; skipping config verification."
    return 0
  fi
  # Do not pipe --help into grep -q: with pipefail, grep's early exit can send
  # SIGPIPE to Hyprland and make a supported build look unsupported.
  help=$("$hypr_bin" --help 2>&1 || true)
  if [[ $help != *--verify-config* ]]; then
    warn "This Hyprland build has no --verify-config; skipping static validation."
    return 0
  fi
  verify_log="$HS_LOG_DIR/hyprland-verify-$(date +%Y%m%d-%H%M%S).log"
  set +e
  "$hypr_bin" --config "$config" --verify-config >"$verify_log" 2>&1
  rc=$?
  set -e
  # Hyprland 0.55.0 had a known verify-only crash; do not roll back a valid
  # install solely because of that upstream bug, but preserve the log.
  if ((rc == 139)); then
    warn "Hyprland --verify-config crashed (upstream verify-only bug); inspect $verify_log before logging in."
    return 0
  fi
  if ((rc != 0)); then
    warn "Hyprland rejected the deployed configuration."
    warn "See $verify_log and the backup recorded in $HS_STATE_HOME/latest-backup."
    sed -n '1,100p' "$verify_log" >&2 || true
    die "Configuration validation failed; restoring the previous configuration."
  fi
  info "Hyprland configuration verified (log: $verify_log)."
}

# Catch a malformed JSON/JSONC file before Waybar or SwayNC is started. The
# shipped files currently contain no comments, so jq can validate them without
# a lossy JSONC preprocessor.
validate_json_configs() {
  local config
  has jq || { warn "jq is not in PATH; skipping JSON config validation."; return 0; }
  for config in \
    "$HOME/.config/waybar/config.jsonc" \
    "$HOME/.config/dock/config.jsonc" \
    "$HOME/.config/swaync/config.json"; do
    [[ -r $config ]] || continue
    if ! jq empty "$config" >/dev/null 2>&1; then
      die "Invalid JSON configuration: $config. The previous configuration will be restored."
    fi
  done
}

# Hyprland 0.55 prefers ~/.config/hypr/hyprland.lua over the legacy .conf.
# Preserve an existing Lua setup in the transaction backup, then move it out
# of the active path so the configuration we validate is the one SDDM loads.
disable_preexisting_lua_config() {
  local lua="$HOME/.config/hypr/hyprland.lua" disabled
  [[ -e $lua ]] || return 0
  disabled="$lua.hyprsequoia-disabled-$(date +%Y%m%d-%H%M%S)"
  warn "Found $lua; Hyprland would ignore the deployed hyprland.conf."
  warn "Preserving it as $disabled (the pre-install backup can restore it)."
  mv -- "$lua" "$disabled"
  DISABLED_LUA=$disabled
}

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

# Detect graphics hardware from stable PCI vendor IDs. Matching words such as
# "ati" in lspci output is unsafe because it also matches "compatible" and can
# misclassify every non-NVIDIA adapter as AMD.
detect_gpu() {
  local vendor_file vendor numeric_devices=''
  for vendor_file in /sys/class/drm/card*/device/vendor; do
    [[ -r $vendor_file ]] || continue
    vendor=$(tr '[:upper:]' '[:lower:]' <"$vendor_file")
    case $vendor in
      0x10de) HS_HAS_NVIDIA=1;;
      0x1002) HS_HAS_AMD=1;;
      0x8086) HS_HAS_INTEL=1;;
    esac
  done
  # sysfs is sufficient on normal Arch systems. Fall back to numeric lspci
  # output for unusual containers/chroots without DRM class devices.
  if ((HS_HAS_NVIDIA == 0 && HS_HAS_AMD == 0 && HS_HAS_INTEL == 0)) && has lspci; then
    numeric_devices=$(lspci -Dn 2>/dev/null | awk '$2 ~ /^03(00|02|80):$/ {print}' || true)
    grep -qi ' 10de:' <<<"$numeric_devices" && HS_HAS_NVIDIA=1
    grep -qi ' 1002:' <<<"$numeric_devices" && HS_HAS_AMD=1
    grep -qi ' 8086:' <<<"$numeric_devices" && HS_HAS_INTEL=1
  fi
  if [[ $HS_GPU == auto ]]; then
    if ((HS_HAS_NVIDIA)); then HS_GPU=nvidia
    elif ((HS_HAS_AMD)); then HS_GPU=amd
    elif ((HS_HAS_INTEL)); then HS_GPU=intel
    else HS_GPU=unknown; fi
  fi
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

# NVIDIA needs a kernel module with DRM modesetting before a Wayland session
# can present a framebuffer. Recent Arch drivers enable this by default, but
# report the state when the installer is run so a TTY user gets an actionable
# warning instead of an unexplained SDDM login loop.
report_gpu_requirements() {
  [[ $HS_GPU == nvidia ]] || return 0
  local modeset
  if [[ -r /sys/module/nvidia_drm/parameters/modeset ]]; then
    modeset=$(< /sys/module/nvidia_drm/parameters/modeset)
    if [[ $modeset != Y && $modeset != y && $modeset != 1 ]]; then
      warn "nvidia_drm modeset is disabled ($modeset); enable nvidia_drm.modeset=1 and reboot before selecting Hyprland."
    else
      info "nvidia_drm modeset is enabled."
    fi
  else
    warn "nvidia_drm is not loaded yet. Verify DRM modesetting after reboot with: cat /sys/module/nvidia_drm/parameters/modeset"
  fi
  warn "NVIDIA DKMS requires matching kernel headers; the installer adds headers for standard Arch kernels when available."
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
  [[ -n $DISABLED_LUA ]] && printf '%s\n' "$DISABLED_LUA" >>"$HS_MANIFEST"
  local component
  for component in hypr waybar kitty walker swaync dock; do
    install_tree "$ROOT/configs/$component" "$HOME/.config/$component"
  done
  # local.conf is intentionally a user-owned extension point. Keep the copy
  # from the backup when reinstalling instead of replacing personal overrides
  # with the empty project template.
  if [[ -r $BACKUP/config/hypr/local.conf ]]; then
    install -Dm644 "$BACKUP/config/hypr/local.conf" "$HOME/.config/hypr/local.conf"
  fi
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
  configure_gpu_environment
  if [[ $HS_CHINESE == 1 ]]; then
    install -Dm644 "$ROOT/configs/fcitx5/profile" "$HOME/.config/fcitx5/profile"
    printf '%s\n' "$HOME/.config/fcitx5/profile" >>"$HS_MANIFEST"
    printf '%s\n' \
      'env = XMODIFIERS,@im=fcitx' \
      'env = QT_IM_MODULE,fcitx' \
      'env = SDL_IM_MODULE,fcitx' \
      >>"$HOME/.config/hypr/conf.d/10-environment.conf"
  fi
}

# Add only the environment required by the selected GPU. The common profile
# stays vendor-neutral, while NVIDIA gets the variables recommended by the
# Hyprland documentation and a conservative cursor fallback.
configure_gpu_environment() {
  local env_file="$HOME/.config/hypr/conf.d/10-environment.conf"
  case $HS_GPU in
    nvidia)
      cat >>"$env_file" <<'EOF'

# NVIDIA Wayland compatibility (selected by the installer).
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
cursor {
    no_hardware_cursors = true
}
EOF
      ;;
  esac
}

main() {
  require_user; require_arch; init_state; choose_profile; detect_session; detect_gpu
  exec > >(tee -a "$HS_LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log") 2>&1
  report_gpu_requirements
  info "Installing $HS_PROFILE profile."
  install_packages; backup_config; disable_preexisting_lua_config; deploy
  validate_hyprland_config; validate_json_configs; enable_services
  [[ $HS_REMOVE_KDE == 1 ]] && "$ROOT/uninstall-kde.sh"
  COMMITTED=1
  if [[ $HS_GPU == nvidia ]]; then
    info "Installation complete. Reboot to load the NVIDIA module, then select Hyprland in SDDM."
  else
    info "Installation complete. Log out, select Hyprland in SDDM, and sign in."
  fi
}
main "$@"
