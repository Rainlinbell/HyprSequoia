# Install, update, restore

The installer owns the files recorded at
`~/.local/state/hyprsequoia/installed-files`. Reinstalling creates a new dated
backup and refreshes the manifest. `~/.config/hypr/local.conf` is the supported
personal override file: the repository supplies only a placeholder and the
installer preserves the user's copy across reinstalls.

Package installation uses `pacman -Syu` so Hyprland and its tightly coupled
Aquamarine/Hypr* libraries are upgraded as one supported Arch transaction. The
installer never performs a partial `pacman -Sy`/`pacman -S` upgrade.

Packages absent from official repositories are installed with an existing
`yay` or `paru`. If no helper is present, the interactive installer may build
`yay-bin` from its displayed AUR Git source only after explicit confirmation.
Declining leaves the user configuration untouched and prints the missing AUR
package list.

`update.sh` accepts only a clean Git checkout and performs a fast-forward pull
before returning to the interactive installer. This prevents accidental merges
or overwritten local repository changes.

`restore.sh` deletes existing regular files listed in the manifest and copies
the latest backup into `~/.config`. It does not uninstall packages, disable
services, or delete new untracked configuration. Backups may be copied or
removed manually after inspection.

At the end of a successful installation, HyprSequoia installs the local SDDM
session entry `/usr/local/share/wayland-sessions/hyprsequoia.desktop`. This
system entry is intentionally not removed by a user-configuration restore.

The KDE tool queries only the installed `plasma` package group, excludes SDDM,
shows the package list, and requires confirmation. It does not broadly remove Qt
or KDE Frameworks packages because other applications may need them.
