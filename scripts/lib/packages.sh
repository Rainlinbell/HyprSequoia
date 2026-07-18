#!/usr/bin/env bash
# Package profiles and package-management helpers.

readonly -a HS_CORE_PACKAGES=(hyprland waybar kitty walker-bin swaync hyprpaper hyprlock hypridle networkmanager bluez bluez-utils pipewire wireplumber pipewire-pulse xdg-desktop-portal-hyprland xdg-desktop-portal-gtk grim slurp wl-clipboard cliphist gammastep jq brightnessctl playerctl polkit-gnome qt5-wayland qt6-wayland noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd bibata-cursor-theme imagemagick pciutils)
readonly -a HS_FULL_PACKAGES=(thunar thunar-archive-plugin file-roller pavucontrol network-manager-applet blueman jq)
readonly -a HS_CN_PACKAGES=(fcitx5-im fcitx5-rime fcitx5-configtool noto-fonts-cjk)
HS_NVIDIA_EXTRA=()

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
  local -a packages=("${HS_CORE_PACKAGES[@]}")
  [[ $HS_PROFILE == full ]] && packages+=("${HS_FULL_PACKAGES[@]}")
  [[ $HS_CHINESE == 1 ]] && packages+=("${HS_CN_PACKAGES[@]}")
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
  ((${#official[@]})) && as_root pacman -Syu --needed --noconfirm "${official[@]}"
  if ((${#aur[@]})); then
    has yay || die "Packages ${aur[*]} require yay. Install yay, then run the installer again."
    yay -S --needed --noconfirm "${aur[@]}"
  fi
}

# Enable system services required by the desktop.
enable_services() {
  as_root systemctl enable --now NetworkManager.service
  as_root systemctl enable --now bluetooth.service
}
