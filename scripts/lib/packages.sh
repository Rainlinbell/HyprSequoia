#!/usr/bin/env bash
# Package profiles and package-management helpers.

readonly -a HS_CORE_PACKAGES=(hyprland waybar kitty walker-bin swaync hyprpaper hyprlock hypridle networkmanager bluez bluez-utils pipewire wireplumber pipewire-pulse xdg-desktop-portal-hyprland xdg-desktop-portal-gtk grim slurp wl-clipboard cliphist gammastep brightnessctl playerctl polkit-gnome qt5-wayland qt6-wayland noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd bibata-cursor-theme)
readonly -a HS_FULL_PACKAGES=(thunar thunar-archive-plugin file-roller pavucontrol network-manager-applet blueman jq imagemagick)
readonly -a HS_CN_PACKAGES=(fcitx5-im fcitx5-rime fcitx5-configtool noto-fonts-cjk)

# Install official packages in a single idempotent transaction.
install_packages() {
  local -a packages=("${HS_CORE_PACKAGES[@]}")
  [[ $HS_PROFILE == full ]] && packages+=("${HS_FULL_PACKAGES[@]}")
  [[ $HS_CHINESE == 1 ]] && packages+=("${HS_CN_PACKAGES[@]}")
  case $HS_GPU in
    nvidia) packages+=(nvidia-utils egl-wayland);;
    amd) packages+=(mesa vulkan-radeon);;
    intel) packages+=(mesa vulkan-intel);;
  esac
  # walker-bin is AUR-only; install official packages first and Walker separately.
  local -a official=() aur=() package
  for package in "${packages[@]}"; do
    if pacman -Si "$package" >/dev/null 2>&1; then official+=("$package"); else aur+=("$package"); fi
  done
  ((${#official[@]})) && as_root pacman -S --needed --noconfirm "${official[@]}"
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
