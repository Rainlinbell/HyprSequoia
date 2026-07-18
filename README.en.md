[简体中文](README.md) · [English](README.en.md)

<div align="center">

# HyprSequoia

An original, modular Hyprland desktop experience for Arch Linux, inspired by macOS Sequoia.

</div>

HyprSequoia is a maintainable desktop distribution layer—not a collection of personal dotfiles. It provides guided installation, configuration backups, failure rollback, updates, and restoration for Arch Linux users, KDE migrants, and Linux newcomers.

> **Project status: v0.1 foundation.** The Hyprland session, installer, backup and restore, menu bar, launcher, notifications, lock screen, wallpaper, and daily hardware integrations are functional. Full Dock interaction (drag ordering, launch bounce, and native multi-monitor hotspots) is available with the optional Rust backend; systems without it use the lightweight fallback. A unified Control Center, automatic light/dark scheduling, and a graphical installer remain roadmap items.

## Features

- Modular Hyprland configuration with separate input, appearance, rules, bindings, and autostart modules
- macOS-inspired menu bar with workspaces, network, Bluetooth, volume, battery, clock, and notifications
- Walker search for applications, files, calculations, and clipboard history
- SwayNC notifications and media controls
- Bottom Sequoia Dock with auto-hide, running indicators, favorites, recents, and multi-monitor support
- Hyprlock blurred lock screen and Hypridle automatic locking
- PipeWire audio, NetworkManager, Bluetooth, brightness, and screenshot integration
- Full, minimal, Chinese, NVIDIA, AMD, and Intel installation profiles
- Automatic pre-install backups and configuration rollback on deployment failure
- Optional, confirmation-based Plasma migration that always preserves SDDM

## Usage

### 1. Prepare the system

Use an updated Arch Linux installation and confirm that:

- You are signed in as a regular user, not `root`.
- Your user can run administrative commands with `sudo`.
- The machine has a working internet connection.
- Git is installed: `sudo pacman -S --needed git`.
- If Walker is only available through the AUR, install `yay` beforehand. HyprSequoia never silently downloads an AUR helper script.

Update and reboot before installation when practical:

```bash
sudo pacman -Syu
reboot
```

### 2. Download and run the installer

```bash
git clone https://github.com/Rainlinbell/HyprSequoia.git
cd HyprSequoia
chmod +x install.sh update.sh restore.sh uninstall-kde.sh
./install.sh
```

The installer offers these profiles:

| Option | Purpose |
|---|---|
| Full Install | Complete desktop and common graphical tools; recommended for most users |
| Minimal Install | Core Hyprland desktop components only |
| Chinese Environment | Full install with Fcitx5, Rime, and Noto CJK fonts |
| NVIDIA / AMD / Intel | Manually select a GPU profile; automatic detection normally suffices |
| Remove KDE Plasma | Enter the separately confirmed KDE migration flow while preserving SDDM |
| Restore Backup | Restore the most recent pre-install configuration backup |

Packages are installed before managed configuration is backed up and deployed. NetworkManager and Bluetooth are then enabled. If configuration deployment fails, the installer restores the backup created by that run.

### 3. Start the desktop

After installation:

1. Log out of the current session.
2. Select **Hyprland** from the session menu on the SDDM login screen.
3. Sign in with your existing account.
4. Press `Super` + `Space` to test Walker, then test the network, Bluetooth, volume, and notification items in the menu bar.

KDE is not removed by default. Keep it as a fallback until HyprSequoia meets your daily needs, then run `./uninstall-kde.sh` if desired.

### 4. Keyboard shortcuts

| Action | Shortcut |
|---|---|
| Spotlight / application search | `Super` + `Space` |
| Terminal | `Super` + `Enter` |
| File manager | `Super` + `E` |
| Lock screen | `Super` + `L` |
| Close the active window | `Super` + `Q` |
| Toggle fullscreen | `Super` + `F` |
| Toggle floating | `Super` + `V` |
| Toggle the Dock | `Super` + `B` |
| Switch to workspace 1–4 | `Super` + `1`–`4` |
| Move a window to workspace 1–4 | `Super` + `Shift` + `1`–`4` |
| Region screenshot | `Print` |
| Full-screen screenshot | `Shift` + `Print` |

Screenshots are saved to `~/Pictures/Screenshots` and copied to the clipboard. Hardware media and brightness keys work through PipeWire and `brightnessctl`.

### 5. Update

Run from the repository checkout:

```bash
cd HyprSequoia
./update.sh
```

The updater requires a clean Git worktree and accepts fast-forward updates only. After pulling, it returns to the interactive installer and creates another backup before replacing configuration.

### 6. Restore configuration

To restore the latest pre-install backup:

```bash
./restore.sh
```

After confirmation, managed files recorded in the installation manifest are removed and the latest backup is restored. Packages, system services, and personal files outside the manifest are left untouched.

Logs, backups, and the installation manifest are stored in:

```text
~/.local/state/hyprsequoia/
```

See the [lifecycle documentation](docs/LIFECYCLE.md) for details.

### Dock

The Dock starts automatically with the Hyprland session. When the Rust
`nwg-dock` binary is available, HyprSequoia uses the full native backend with
drag ordering, launch bounce, and multi-monitor hotspots; otherwise it falls
back to the Go backend or a lightweight Waybar implementation. See the [Dock
documentation](docs/DOCK.md).

## Architecture

- `configs/hypr/conf.d/`: independently owned compositor modules
- `configs/{waybar,kitty,walker,swaync}/`: desktop application configuration
- `configs/dock/`: native-first bottom Dock and Waybar fallback configuration
- `scripts/lib/`: shared installer and package primitives
- `scripts/bin/`: runtime commands installed in `~/.local/bin`
- `themes/` and `wallpapers/`: project visual assets and variants
- `docs/`: architecture, lifecycle, troubleshooting, and roadmap

Read [ARCHITECTURE.md](docs/ARCHITECTURE.md) and [CONTRIBUTING.md](CONTRIBUTING.md) before contributing.

## Troubleshooting

Inspect the newest log in `~/.local/state/hyprsequoia/logs`, then run:

```bash
hyprctl systeminfo
journalctl --user -b
```

Restart an affected component independently where possible. For example:

```bash
killall waybar
waybar
```

For SDDM login loops, NVIDIA black screens, screen sharing, or Chinese input problems, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## FAQ

**Is this a WhiteSur or another dotfiles project?**

No. The architecture, configuration, scripts, and bundled artwork are original. Optional third-party themes retain their upstream licenses and are not copied into this project.

**Does it support NVIDIA?**

The installer detects NVIDIA hardware and installs common userspace components. Kernel driver selection remains explicit because the correct proprietary or open driver depends on the GPU generation.

**Can I keep KDE?**

Yes, and this is the recommended migration path. Plasma removal runs only when explicitly selected or when `uninstall-kde.sh` is launched manually.

**Why might yay be required?**

Walker may require the AUR. The installer checks current official repositories first and invokes an existing `yay` only when necessary; it never bootstraps an AUR helper silently.

## Roadmap and versioning

HyprSequoia follows [Semantic Versioning](https://semver.org/). See [ROADMAP.md](docs/ROADMAP.md) and [CHANGELOG.md](CHANGELOG.md). Releases before 1.0 may change configuration interfaces.

## Contributing and license

Contributions are welcome under [CONTRIBUTING.md](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md). HyprSequoia is released under the [MIT License](LICENSE).
