#!/usr/bin/env bash
# Interactive, transactional installer for HyprSequoia.

set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"
# shellcheck source=scripts/lib/packages.sh
source "$ROOT/scripts/lib/packages.sh"

HS_PROFILE=full HS_CHINESE=0 HS_GPU=auto HS_VIRT=none HS_REMOVE_KDE=0 COMMITTED=0 BACKUP="" DISABLED_LUA=""
HS_HAS_NVIDIA=0 HS_HAS_AMD=0 HS_HAS_INTEL=0
HS_SDDM_SESSION="/usr/local/share/wayland-sessions/hyprsequoia.desktop"
HS_SESSION_LAUNCHER="/usr/local/bin/hyprsequoia-start"
SDDM_DISPLAY_SERVER=x11 SDDM_DISPLAY_SOURCE="built-in default"

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
    die "Hyprland is not in PATH after package deployment; refusing to install an unverified login session."
  fi
  # Do not pipe --help into grep -q: with pipefail, grep's early exit can send
  # SIGPIPE to Hyprland and make a supported build look unsupported.
  help=$("$hypr_bin" --help 2>&1 || true)
  if [[ $help != *--verify-config* ]]; then
    die "This Hyprland build has no --verify-config support. Complete a full Arch upgrade, then retry."
  fi
  verify_log="$HS_LOG_DIR/hyprland-verify-$(date +%Y%m%d-%H%M%S).log"
  set +e
  "$hypr_bin" --config "$config" --verify-config >"$verify_log" 2>&1
  rc=$?
  set -e
  # A verifier crash cannot prove that the login configuration is safe. Keep
  # the log and fail closed so SDDM never receives an unverified session.
  if ((rc == 139)); then
    warn "Hyprland --verify-config crashed; inspect $verify_log."
    die "Configuration verification crashed. Upgrade Hyprland and retry; restoring the previous configuration."
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

# Identify virtualized graphics before package selection. VMware needs guest
# integration packages, and all VMs need an accelerated DRM render node for a
# real Hyprland session.
detect_virtualization() {
  local detected=''
  if has systemd-detect-virt; then
    detected=$(systemd-detect-virt 2>/dev/null || true)
  fi
  if [[ -n $detected && $detected != none ]]; then
    HS_VIRT=$detected
  elif has lspci && lspci -Dn 2>/dev/null | grep -qi ' 15ad:'; then
    HS_VIRT=vmware
  fi
  info "Virtualization: $HS_VIRT"
}

# Refuse to deploy a login entry that can only crash. A render node is the
# minimum portable VM check; VMware additionally emits an unambiguous EGL
# diagnostic when the host-side "Accelerate 3D graphics" option is disabled.
validate_virtual_graphics() {
  [[ $HS_VIRT != none ]] || return 0
  local graphics_log
  graphics_log="$HS_LOG_DIR/graphics-$(date +%Y%m%d-%H%M%S).log"

  if ! compgen -G '/dev/dri/renderD*' >/dev/null; then
    die "Virtual machine has no DRM render node. Fully power it off, enable 3D acceleration in the hypervisor display settings, boot it, and rerun the installer."
  fi
  if [[ $HS_VIRT == vmware && ! -d /sys/module/vmwgfx ]]; then
    die "VMware graphics driver vmwgfx is not loaded. Enable Accelerate 3D graphics, reboot the guest, and verify: lspci -k"
  fi
  if [[ $HS_VIRT == vmware ]] && has eglinfo; then
    eglinfo -B >"$graphics_log" 2>&1 || true
    if grep -Fq 'VMware: No 3D enabled' "$graphics_log"; then
      die "VMware 3D acceleration is disabled. Fully shut down the VM, open VM Settings > Display, enable Accelerate 3D graphics, then boot and rerun the installer. See $graphics_log"
    fi
  fi
}

# HyprSequoia currently owns ~/.config paths in its compositor, Waybar, Dock,
# and helper configurations. Stop before changing the system if Hyprland would
# load a different XDG/config override than the file the installer validates.
require_managed_config_path() {
  local expected_home expected_config requested
  expected_home=$(realpath -m -- "$HOME/.config")
  expected_config=$(realpath -m -- "$HOME/.config/hypr/hyprland.conf")
  if [[ -n ${XDG_CONFIG_HOME:-} ]]; then
    requested=$(realpath -m -- "$XDG_CONFIG_HOME")
    if [[ $requested != "$expected_home" ]]; then
      die "XDG_CONFIG_HOME points to $requested, but HyprSequoia currently manages $expected_home. Unset the override before installing."
    fi
  fi
  if [[ -n ${HYPRLAND_CONFIG:-} ]]; then
    requested=${HYPRLAND_CONFIG/#\~/$HOME}
    requested=$(realpath -m -- "$requested")
    if [[ $requested != "$expected_config" ]]; then
      die "HYPRLAND_CONFIG points to $requested, but the managed login config is $expected_config. Unset the override before installing."
    fi
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

# Verify a selected DKMS driver after pacman hooks have run. A package can be
# present while its module build failed; allowing login in that state produces
# the same immediate black-screen return as a compositor crash.
validate_nvidia_postinstall() {
  [[ $HS_GPU == nvidia ]] || return 0
  local installed_packages needs_dkms=0 status=''
  installed_packages=$(pacman -Qq 2>/dev/null || true)
  if grep -Eq '^nvidia(-open)?(-[0-9]+xx)?-dkms$' <<<"$installed_packages"; then
    needs_dkms=1
  fi
  if ((needs_dkms)); then
    has dkms || die "An NVIDIA DKMS package is installed, but the dkms command is unavailable."
    status=$(dkms status 2>&1 || true)
    if ! grep -Eqi '^nvidia/.*[,:][[:space:]].*installed' <<<"$status"; then
      warn "NVIDIA DKMS did not report an installed module:"
      printf '%s\n' "$status" >&2
      die "NVIDIA module build failed. Install matching kernel headers and repair DKMS before logging in."
    fi
    info "NVIDIA DKMS module build verified."
  fi
  if [[ -r /sys/module/nvidia_drm/parameters/modeset ]]; then
    local modeset
    modeset=$(< /sys/module/nvidia_drm/parameters/modeset)
    if [[ $modeset != Y && $modeset != y && $modeset != 1 ]]; then
      warn "The currently loaded nvidia_drm module still has modeset=$modeset. Enable modeset and reboot before selecting HyprSequoia."
    fi
  else
    warn "The NVIDIA DRM module is not loaded in this boot; reboot is required before the first HyprSequoia login."
  fi
}

# Read SDDM's effective greeter backend using its documented configuration
# precedence. This setting controls the greeter only; it does not decide
# whether the selected desktop session itself is Wayland or X11.
read_sddm_display_server() {
  local file value
  local -a files=()
  for file in /usr/lib/sddm/sddm.conf.d/*.conf; do [[ -f $file ]] && files+=("$file"); done
  for file in /etc/sddm.conf.d/*.conf; do [[ -f $file ]] && files+=("$file"); done
  [[ -f /etc/sddm.conf ]] && files+=(/etc/sddm.conf)
  SDDM_DISPLAY_SERVER=x11
  SDDM_DISPLAY_SOURCE="built-in default"
  for file in "${files[@]}"; do
    [[ -r $file ]] || continue
    value=$(awk '
      /^[[:space:]]*[#;]/ { next }
      /^[[:space:]]*\[/ {
        general = ($0 ~ /^[[:space:]]*\[General\][[:space:]]*$/)
        next
      }
      general && /^[[:space:]]*DisplayServer[[:space:]]*=/ {
        value = $0
        sub(/^[^=]*=/, "", value)
        sub(/[[:space:]]*[#;].*$/, "", value)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        if (value != "") last = value
      }
      END { if (last != "") print last }
    ' "$file")
    if [[ -n $value ]]; then
      SDDM_DISPLAY_SERVER=$value
      SDDM_DISPLAY_SOURCE=$file
    fi
  done
}

# Install a clearly named, non-UWSM login entry. Current Arch packages also
# expose an optional UWSM entry even when uwsm itself is absent, which makes it
# easy for a new user to select a session that immediately exits to SDDM.
install_sddm_session() {
  local source="$ROOT/configs/sddm/hyprsequoia.desktop"
  local launcher="$ROOT/scripts/bin/hyprsequoia-start"
  has start-hyprland || die "The installed Hyprland package has no start-hyprland wrapper. Complete a full Arch upgrade, then retry."
  [[ -r $source ]] || die "Missing SDDM session template: $source"
  [[ -x $launcher ]] || die "Missing session launcher: $launcher"
  as_root install -Dm755 "$launcher" "$HS_SESSION_LAUNCHER"
  as_root install -Dm644 "$source" "$HS_SDDM_SESSION"
  info "Installed the pinned HyprSequoia session entry: $HS_SDDM_SESSION"
}

# Refuse a known-incompatible login stack and explain non-fatal SDDM choices
# that commonly look like a compositor crash.
validate_login_stack() {
  local version plain_entry=/usr/share/wayland-sessions/hyprland.desktop exec_line=''
  version=$(pacman -Q sddm 2>/dev/null | awk '{print $2}' || true)
  [[ -n $version ]] || die "SDDM is not installed after package deployment."
  if has vercmp && (($(vercmp "$version" 0.20.0) < 0)); then
    die "SDDM $version is too old; Hyprland requires SDDM 0.20.0 or newer."
  fi
  info "SDDM version check passed ($version)."

  if [[ -r $plain_entry ]]; then
    exec_line=$(awk -F= '$1 == "Exec" { sub(/^[^=]*=/, ""); print; exit }' "$plain_entry")
    if [[ $exec_line != *start-hyprland* ]]; then
      warn "$plain_entry does not launch start-hyprland (Exec=$exec_line)."
      warn "Use the HyprSequoia session installed by this installer or reinstall the Arch hyprland package."
    fi
  else
    warn "The packaged plain Hyprland SDDM entry is missing; use the HyprSequoia session entry."
  fi
  if [[ -r /usr/share/wayland-sessions/hyprland-uwsm.desktop ]] && ! has uwsm; then
    warn "SDDM also lists 'Hyprland (uwsm-managed)', but uwsm is not installed. Do not select that entry."
  fi

  read_sddm_display_server
  if [[ ${SDDM_DISPLAY_SERVER,,} == wayland ]]; then
    warn "SDDM is forced to the experimental Wayland greeter by $SDDM_DISPLAY_SOURCE."
    warn "If login still returns to SDDM, test the default DisplayServer=x11 backend; see docs/TROUBLESHOOTING.md."
  else
    info "SDDM greeter backend: $SDDM_DISPLAY_SERVER ($SDDM_DISPLAY_SOURCE)."
  fi
}

# Enable SDDM for a clean Arch installation without replacing another display
# manager that the user deliberately enabled. Do not start it from inside the
# installer because doing so could terminate the current graphical session.
enable_display_manager() {
  local link=/etc/systemd/system/display-manager.service target=''
  if [[ -e $link || -L $link ]]; then
    target=$(readlink -f -- "$link" 2>/dev/null || true)
    if [[ $target == */sddm.service ]]; then
      info "SDDM is already the enabled display manager."
    else
      warn "Keeping the existing display manager: ${target:-$link}"
      warn "The HyprSequoia session is available from any manager that scans standard Wayland session directories."
    fi
    return 0
  fi
  as_root systemctl enable sddm.service
  info "Enabled SDDM for the next boot."
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
  # Preserve the selected Tahoe appearance across upgrades. Theme source files
  # remain immutable; only the generated theme.css entry points are replaced.
  local appearance=dark
  if [[ -r $HS_STATE_HOME/appearance ]]; then
    IFS= read -r appearance <"$HS_STATE_HOME/appearance"
  elif [[ -r $HS_STATE_HOME/waybar-theme ]]; then
    IFS= read -r appearance <"$HS_STATE_HOME/waybar-theme"
  fi
  [[ $appearance == light ]] || appearance=dark
  cp -- "$HOME/.config/waybar/theme-$appearance.css" "$HOME/.config/waybar/theme.css"
  cp -- "$HOME/.config/dock/theme-$appearance.css" "$HOME/.config/dock/theme.css"
  cp -- "$HOME/.config/dock/nwg-style-$appearance.css" "$HOME/.config/dock/nwg-style.css"
  cp -- "$HOME/.config/swaync/theme-$appearance.css" "$HOME/.config/swaync/theme.css"
  cp -- "$HOME/.config/walker/themes/sequoia/theme-$appearance.css" "$HOME/.config/walker/themes/sequoia/theme.css"
  if has gsettings; then
    local gtk_theme=adw-gtk3-dark icon_theme=Papirus-Dark color_scheme=prefer-dark
    if [[ $appearance == light ]]; then
      gtk_theme=adw-gtk3
      icon_theme=Papirus
      color_scheme=prefer-light
    fi
    gsettings set org.gnome.desktop.interface font-name 'Inter 11' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "$color_scheme" 2>/dev/null || true
  fi
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
  # Runtime shell entry points need execute bits; CSS, JSON, TOML, and XML stay data-only.
  for script_dir in "$HOME/.config/waybar/scripts" "$HOME/.config/dock/scripts" "$HOME/.config/walker/scripts"; do
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
  local desktop data_home
  data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  for desktop in "$ROOT/configs/applications/"*.desktop; do
    [[ -r $desktop ]] || continue
    install -Dm644 "$desktop" "$data_home/applications/$(basename "$desktop")"
    printf '%s\n' "$data_home/applications/$(basename "$desktop")" >>"$HS_MANIFEST"
  done
  if has update-desktop-database; then
    update-desktop-database "$data_home/applications" || warn "Could not refresh the user desktop-entry database."
  fi
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
  require_user; require_arch; init_state; choose_profile; detect_session; detect_virtualization; detect_gpu
  exec > >(tee -a "$HS_LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log") 2>&1
  require_managed_config_path
  report_gpu_requirements
  info "Installing $HS_PROFILE profile."
  install_packages; validate_nvidia_postinstall; validate_virtual_graphics
  backup_config; disable_preexisting_lua_config; deploy
  validate_hyprland_config; validate_json_configs
  validate_login_stack; enable_services; enable_display_manager
  [[ $HS_REMOVE_KDE == 1 ]] && "$ROOT/uninstall-kde.sh"
  install_sddm_session
  COMMITTED=1
  if [[ ${HYPRSEQUOIA_SESSION:-0} == 1 ]] && has hyprctl && hyprctl monitors >/dev/null 2>&1; then
    info "Refreshing the active HyprSequoia session."
    "$HOME/.local/bin/hyprsequoia-refresh" || warn "Live refresh failed; log out and back in to apply the new interface."
  fi
  if [[ $HS_GPU == nvidia ]]; then
    info "Installation complete. Reboot to load the NVIDIA module, then select HyprSequoia in SDDM (not the UWSM-managed entry)."
  else
    info "Installation complete. Log out, select HyprSequoia in SDDM (not the UWSM-managed entry), and sign in."
  fi
}
main "$@"
