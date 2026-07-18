# Install, update, restore

The installer owns the files recorded at
`~/.local/state/hyprsequoia/installed-files`. Reinstalling creates a new dated
backup and refreshes the manifest. Keep personal overrides in files not present
in the repository, ideally `~/.config/hypr/local.conf`, and source them last from
`hyprland.conf`.

`update.sh` accepts only a clean Git checkout and performs a fast-forward pull
before returning to the interactive installer. This prevents accidental merges
or overwritten local repository changes.

`restore.sh` deletes existing regular files listed in the manifest and copies
the latest backup into `~/.config`. It does not uninstall packages, disable
services, or delete new untracked configuration. Backups may be copied or
removed manually after inspection.

The KDE tool queries only the installed `plasma` package group, excludes SDDM,
shows the package list, and requires confirmation. It does not broadly remove Qt
or KDE Frameworks packages because other applications may need them.
