#!/usr/bin/env bash
# Package profiles and package-management helpers.

readonly -a HS_CORE_PACKAGES=(hyprland sddm waybar kitty walker-bin swaync hyprpaper hyprlock hypridle networkmanager bluez bluez-utils pipewire wireplumber pipewire-pulse xdg-desktop-portal-hyprland xdg-desktop-portal-gtk grim slurp wl-clipboard cliphist gammastep jq brightnessctl playerctl polkit-gnome qt5-wayland qt6-wayland noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd bibata-cursor-theme imagemagick librsvg nwg-dock-hyprland pciutils mesa mesa-utils)
readonly -a HS_FULL_PACKAGES=(thunar thunar-archive-plugin file-roller pavucontrol network-manager-applet blueman jq)
# Use concrete packages rather than the fcitx5-im group. `pacman -Si` resolves
# packages, not groups, and package/AUR classification must remain deterministic.
readonly -a HS_CN_PACKAGES=(fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-rime noto-fonts-cjk)
# Walker itself and the official Elephant release both publish prebuilt AUR
# packages. Prefer the matching Elephant split binaries: explicitly requesting
# the source packages makes a normal desktop install compile Go modules and can
# fail solely because proxy.golang.org is unreachable.
readonly -a HS_SPOTLIGHT_BIN_CORE_PACKAGES=(elephant-bin elephant-desktopapplications-bin elephant-calc-bin)
readonly -a HS_SPOTLIGHT_BIN_EXTRA_PACKAGES=(elephant-files-bin elephant-clipboard-bin elephant-symbols-bin elephant-unicode-bin elephant-providerlist-bin)
# Keep an already-installed source family during an upgrade. Replacing it with
# the conflicting binary family requires removing packages mid-transaction and
# makes a failed download leave Walker without its runtime. Fresh installs use
# the binary family above.
readonly -a HS_SPOTLIGHT_SOURCE_CORE_PACKAGES=(elephant elephant-desktopapplications elephant-calc)
readonly -a HS_SPOTLIGHT_SOURCE_EXTRA_PACKAGES=(elephant-files elephant-clipboard elephant-symbols elephant-unicode elephant-providerlist)
HS_NVIDIA_EXTRA=()

# Move only unowned files reported by pacman as transaction conflicts. This
# recovers safely from an interrupted extraction or missing local file metadata:
# every path is retained in the user's state backup, while files owned by any
# package and directory conflicts remain hard failures.
backup_unowned_pacman_conflicts() {
  local transaction_log=$1 backup path owner destination unsafe=0
  local -a conflicts=()

  mapfile -t conflicts < <(
    sed -nE 's/^[^:]+: (\/.*) exists in filesystem$/\1/p' "$transaction_log" | sort -u
  )
  ((${#conflicts[@]})) || return 1

  for path in "${conflicts[@]}"; do
    if [[ $path != /* || $path == *'/../'* || $path == */.. ]]; then
      warn "Refusing an unsafe pacman conflict path: $path"
      unsafe=1
      continue
    fi
    [[ -e $path || -L $path ]] || continue
    if owner=$(pacman -Qqo -- "$path" 2>/dev/null); then
      warn "Pacman conflict is owned by ${owner//$'\n'/, }: $path"
      unsafe=1
    elif [[ -d $path && ! -L $path ]]; then
      warn "Pacman conflict is a directory and will not be moved automatically: $path"
      unsafe=1
    fi
  done
  ((unsafe == 0)) || return 1

  backup="$HS_BACKUP_DIR/package-conflicts-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup"
  for path in "${conflicts[@]}"; do
    [[ -e $path || -L $path ]] || continue
    destination="$backup/${path#/}"
    mkdir -p "$(dirname -- "$destination")"
    as_root mv -- "$path" "$destination"
    warn "Preserved unowned conflicting file: $path"
  done
  warn "Pacman conflict backup: $backup"
}

# Run one full official repository transaction. If the only failure is unowned
# `exists in filesystem` residue, preserve those paths and retry exactly once.
install_official_packages() {
  local transaction_log status
  local -a packages=("$@")
  ((${#packages[@]})) || return 0
  transaction_log="$HS_LOG_DIR/pacman-$(date +%Y%m%d-%H%M%S).log"

  set +e
  as_root env LC_ALL=C pacman -Syu --needed --noconfirm "${packages[@]}" \
    2>&1 | tee "$transaction_log"
  status=${PIPESTATUS[0]}
  set -e
  ((status == 0)) && return 0

  if ! backup_unowned_pacman_conflicts "$transaction_log"; then
    die "Official package transaction failed. Review $transaction_log; no conflicting files were overwritten."
  fi

  warn "Retrying the official package transaction after preserving unowned conflicts."
  set +e
  as_root env LC_ALL=C pacman -Syu --needed --noconfirm "${packages[@]}" \
    2>&1 | tee -a "$transaction_log"
  status=${PIPESTATUS[0]}
  set -e
  ((status == 0)) \
    || die "Official package retry failed. Review $transaction_log and the pacman output above."
}

# A zero-byte shared library is never loadable. Reinstall its owning official
# package after the main transaction, then verify the exact file was restored.
# Unowned or foreign-package files are reported but never guessed or removed.
repair_empty_owned_shared_libraries() {
  local path owner
  local -a empty_libraries=() owners=() unique_owners=()

  mapfile -t empty_libraries < <(
    find /usr/lib -maxdepth 1 -type f -empty \
      \( -name '*.so' -o -name '*.so.*' \) -print 2>/dev/null | sort -u
  )
  ((${#empty_libraries[@]})) || return 0

  for path in "${empty_libraries[@]}"; do
    if ! owner=$(pacman -Qqo -- "$path" 2>/dev/null); then
      warn "Unowned empty shared library requires manual investigation: $path"
      continue
    fi
    if pacman -Si "$owner" >/dev/null 2>&1; then
      owners+=("$owner")
    else
      warn "Empty shared library belongs to a foreign package ($owner): $path"
    fi
  done
  ((${#owners[@]})) || return 0

  mapfile -t unique_owners < <(printf '%s\n' "${owners[@]}" | sort -u)
  warn "Reinstalling official packages that own empty shared libraries: ${unique_owners[*]}"
  as_root env LC_ALL=C pacman -S --noconfirm "${unique_owners[@]}" \
    || die "Could not repair packages that own empty shared libraries: ${unique_owners[*]}"

  for path in "${empty_libraries[@]}"; do
    owner=$(pacman -Qqo -- "$path" 2>/dev/null || true)
    if [[ -n $owner ]] && printf '%s\n' "${unique_owners[@]}" | grep -Fqx -- "$owner"; then
      [[ -s $path ]] || die "Package reinstall left an empty shared library: $path"
    fi
  done
  info "Owned empty shared libraries repaired."
}

# AUR helpers cache completed downloads and package builds, so a single retry
# can recover a transient mirror/AUR failure without repeating successful work.
install_aur_packages() {
  local helper=$1 attempt
  shift
  local -a packages=("$@")

  for attempt in 1 2; do
    if "$helper" -S --needed --noconfirm "${packages[@]}"; then
      return 0
    fi
    if ((attempt == 1)); then
      warn "AUR transaction failed; retrying once using the helper cache."
    fi
  done
  die "AUR package installation failed: ${packages[*]}. Review the first package error above."
}

# Return the first supported AUR helper already available to the user.
find_aur_helper() {
  local helper
  for helper in yay paru; do
    if has "$helper"; then
      printf '%s\n' "$helper"
      return 0
    fi
  done
  return 1
}

# Bootstrap yay-bin only after explicit confirmation. AUR PKGBUILDs are
# third-party code, so the installer prints the source and never downloads or
# executes one silently.
offer_aur_helper_install() {
  local answer build_dir
  printf '\nRequired packages are available only from the AUR.\n' >&2
  printf 'HyprSequoia can build yay-bin from https://aur.archlinux.org/yay-bin.git\n' >&2
  read -r -p 'Install yay-bin now? [y/N] ' answer || answer=n
  [[ $answer =~ ^[Yy]$ ]] || return 1

  as_root pacman -S --needed --noconfirm base-devel git
  build_dir=$(mktemp -d "${TMPDIR:-/tmp}/hyprsequoia-yay.XXXXXX")
  if ! git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir"; then
    rm -rf -- "$build_dir"
    die "Could not clone yay-bin from the AUR. Check the network connection and retry."
  fi
  if ! (cd "$build_dir" && makepkg -si --needed --noconfirm); then
    rm -rf -- "$build_dir"
    die "yay-bin installation failed. Review the makepkg output before retrying."
  fi
  rm -rf -- "$build_dir"
  has yay || die "yay-bin completed, but the yay command is not available in PATH."
}

# Select an NVIDIA kernel module package without guessing the GPU generation.
# An installed driver is always respected. For a new setup, current NVIDIA
# hardware defaults to the open DKMS module; users of pre-Turing cards can pick
# the proprietary DKMS module explicitly.
select_nvidia_driver() {
  local package choice installed
  for package in nvidia-open-dkms nvidia-dkms nvidia nvidia-open; do
    if pacman -Q "$package" >/dev/null 2>&1; then
      printf 'existing:%s\n' "$package"
      return 0
    fi
  done
  # Respect legacy and vendor-specific package names instead of trying to
  # replace a working module stack with a conflicting repository package.
  installed=$(pacman -Qq 2>/dev/null | awk '/^nvidia(-open)?(-[0-9]+xx)?(-dkms)?$/ && !found {print; found=1}')
  if [[ -n $installed ]]; then
    printf 'existing:%s\n' "$installed"
    return 0
  fi
  if command -v modinfo >/dev/null 2>&1 && modinfo nvidia >/dev/null 2>&1; then
    printf '%s\n' 'existing:kernel-module'
    return 0
  fi
  printf '\nNVIDIA kernel driver\n' >&2
  printf '  1) nvidia-open-dkms (RTX / GTX 16-series and newer; required for RTX 50-series)\n' >&2
  printf '  2) nvidia-dkms (older supported GPUs, including GTX 10-series and earlier)\n' >&2
  read -r -p 'Select [1]: ' choice || choice=1
  case ${choice:-1} in
    1) package=nvidia-open-dkms;;
    2) package=nvidia-dkms;;
    *) die "Unknown NVIDIA driver selection.";;
  esac
  pacman -Si "$package" >/dev/null 2>&1 || die "$package is unavailable in the configured repositories."
  printf '%s\n' "$package"
}

# DKMS cannot build without headers. Add headers for the standard kernels that
# are installed, and leave a clear warning for custom kernels.
add_nvidia_headers() {
  local kernel header found=0
  for kernel in linux linux-lts linux-zen linux-hardened; do
    if pacman -Q "$kernel" >/dev/null 2>&1; then
      found=1
      header="${kernel}-headers"
      if pacman -Si "$header" >/dev/null 2>&1; then
        HS_NVIDIA_EXTRA+=("$header")
      fi
    fi
  done
  ((found)) || warn "No standard Arch kernel detected; ensure matching headers are installed for NVIDIA DKMS."
}

# Install official packages in a single idempotent transaction.
install_packages() {
  local -a spotlight_core=("${HS_SPOTLIGHT_BIN_CORE_PACKAGES[@]}")
  local -a spotlight_extra=("${HS_SPOTLIGHT_BIN_EXTRA_PACKAGES[@]}")
  if pacman -Q elephant >/dev/null 2>&1 && ! pacman -Q elephant-bin >/dev/null 2>&1; then
    info "Keeping the installed Elephant source-package family for this upgrade."
    spotlight_core=("${HS_SPOTLIGHT_SOURCE_CORE_PACKAGES[@]}")
    spotlight_extra=("${HS_SPOTLIGHT_SOURCE_EXTRA_PACKAGES[@]}")
  fi
  local -a packages=("${HS_CORE_PACKAGES[@]}" "${spotlight_core[@]}" "${spotlight_extra[@]}")
  [[ $HS_PROFILE == full ]] && packages+=("${HS_FULL_PACKAGES[@]}")
  [[ $HS_CHINESE == 1 ]] && packages+=("${HS_CN_PACKAGES[@]}")
  [[ ${HS_VIRT:-none} == vmware ]] && packages+=(open-vm-tools)
  case $HS_GPU in
    nvidia)
      local nvidia_driver driver_selection
      driver_selection=$(select_nvidia_driver)
      if [[ $driver_selection == existing:* ]]; then
        nvidia_driver=${driver_selection#existing:}
      else
        nvidia_driver=$driver_selection
        packages+=("$nvidia_driver")
      fi
      packages+=(nvidia-utils egl-wayland)
      if [[ $nvidia_driver == *-dkms ]]; then
        # Use a temporary array so this helper remains side-effect-free for all
        # non-NVIDIA profiles.
        HS_NVIDIA_EXTRA=()
        add_nvidia_headers
        packages+=("${HS_NVIDIA_EXTRA[@]}")
      fi
      ;;
  esac
  # Hybrid laptops need the userspace stack for the display-driving iGPU even
  # when the NVIDIA profile owns the discrete renderer.
  if [[ $HS_GPU == amd || ${HS_HAS_AMD:-0} == 1 ]]; then packages+=(mesa vulkan-radeon); fi
  if [[ $HS_GPU == intel || ${HS_HAS_INTEL:-0} == 1 ]]; then packages+=(mesa vulkan-intel); fi
  # walker-bin is AUR-only; install official packages first and Walker separately.
  local -a official=() aur=() package
  for package in "${packages[@]}"; do
    if pacman -Si "$package" >/dev/null 2>&1; then official+=("$package"); else aur+=("$package"); fi
  done
  # Arch supports only full-system upgrades. Installing against refreshed
  # repositories without upgrading the existing Hyprland/Aquamarine libraries
  # can create an ABI mismatch and an immediate SDDM login loop.
  install_official_packages "${official[@]}"
  if ((${#aur[@]})); then
    local helper=''
    helper=$(find_aur_helper || true)
    if [[ -z $helper ]]; then
      offer_aur_helper_install || die "AUR packages are required: ${aur[*]}. Install yay or paru, then rerun the installer."
      helper=yay
    fi
    install_aur_packages "$helper" "${aur[@]}"
  fi
  repair_empty_owned_shared_libraries
}

# Enable system services required by the desktop.
enable_services() {
  as_root systemctl enable --now NetworkManager.service
  as_root systemctl enable --now bluetooth.service
  if [[ ${HS_VIRT:-none} == vmware ]]; then
    as_root systemctl enable --now vmtoolsd.service
    as_root systemctl enable --now vmware-vmblock-fuse.service
  fi
}
