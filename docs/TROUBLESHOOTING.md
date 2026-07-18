# Troubleshooting

## Session returns to SDDM

Switch to a TTY with `Ctrl+Alt+F3`, sign in, and inspect
`journalctl --user -b` plus `journalctl -b -u sddm`. Confirm `Hyprland` launches
from the TTY. NVIDIA users should install the driver appropriate to their exact
GPU generation and enable DRM modesetting according to the Arch Wiki.

## Black wallpaper or missing bar

Run `hyprpaper` or `waybar` in a terminal to expose parsing errors. Confirm the
bundled wallpaper exists at `~/.config/hypr/wallpapers/default.svg`. Reload
Hyprland with `hyprctl reload` after edits.

## Screen sharing fails

Confirm both `xdg-desktop-portal-hyprland` and
`xdg-desktop-portal-gtk` are installed. Log out fully after installation, then
inspect `systemctl --user status xdg-desktop-portal-hyprland`.

## Chinese input does not appear

Install the Chinese profile, start `fcitx5`, and verify applications inherit
the Wayland session environment. Use `fcitx5-diagnose` for a detailed report.

## Restore after a failed experiment

Run `./restore.sh` from the repository. If no recorded backup exists, inspect
`~/.local/state/hyprsequoia/backups` and copy the desired dated `config`
directory manually.
