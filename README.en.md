[简体中文](README.md) · [English](README.en.md)

<div align="center">

# HyprSequoia

An original, modular Hyprland desktop experience for Arch Linux, visually inspired by macOS Tahoe.

</div>

HyprSequoia is a maintainable desktop distribution layer—not a collection of personal dotfiles. It provides guided installation, configuration backups, failure rollback, updates, and restoration for Arch Linux users, KDE migrants, and Linux newcomers.

> **Project status: v0.1 foundation.** The Hyprland session, installer, backup and restore, Tahoe menu bar, resident Dock, Spotlight, unified Control Center, System Settings hub, notifications, light/dark appearance, lock screen, wallpaper, and daily hardware integrations are functional. Full Dock drag ordering and launch bounce remain available through the optional Rust backend; a graphical installer remains a roadmap item.

## Features

- Modular Hyprland configuration with separate input, appearance, rules, bindings, and autostart modules
- Tahoe-style transparent menu bar with network, Bluetooth, volume, battery, clock, notifications, and Control Center
- Tahoe Liquid Glass Spotlight for apps, files, calculations, unit/currency conversion, clipboard, emoji, recents, settings, and quick actions
- SwayNC Control and Notification Center with Wi-Fi, Bluetooth, appearance, Night Shift, brightness, volume, media, and calendar controls
- Bottom resident Tahoe Dock with running indicators, favorites, recents, and multi-monitor support
- Unified HyprSequoia System Settings hub and cross-component light/dark appearance
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
- Walker and some theme components come from the AUR. You may install `yay` or `paru` beforehand; if neither exists, the installer explicitly offers to build `yay-bin` and does nothing when consent is declined.

Update and reboot before installation when practical:

```bash
sudo pacman -Syu
reboot
```

### 2. Download and run the installer

```bash
git clone https://github.com/Rainlinbell/HyprSequoia.git
cd HyprSequoia
./install.sh
```

The installer offers these profiles:

| Option | Purpose |
|---|---|
| Full Install | Complete desktop and common graphical tools; recommended for most users |
| Minimal Install | Core Hyprland desktop components only |
| Chinese Environment | Full install with Fcitx5, Rime, and Noto CJK fonts |
| NVIDIA / AMD / Intel | Manually select a GPU profile; a new NVIDIA setup prompts for open/proprietary DKMS |
| Remove KDE Plasma | Enter the separately confirmed KDE migration flow while preserving SDDM |
| Restore Backup | Restore the most recent pre-install configuration backup |

The installer first performs Arch's required full-system upgrade with `pacman -Syu` and installs packages. Managed configuration is then backed up, deployed, and validated for Hyprland, Waybar, the Dock, and SwayNC. NetworkManager and Bluetooth are enabled last. If deployment or validation fails, the installer restores the backup created by that run.

### 3. Start the desktop

After installation:

1. Log out of the current session.
2. Select **HyprSequoia** from the SDDM session menu (do not select the UWSM-managed entry when `uwsm` is absent).
3. Sign in with your existing account.
4. Press `Super` + `Space` to test Walker, then test the network, Bluetooth, volume, and notification items in the menu bar.

KDE is not removed by default. Keep it as a fallback until HyprSequoia meets your daily needs, then run `./uninstall-kde.sh` if desired.

### 4. Keyboard shortcuts

| Action | Shortcut |
|---|---|
| Spotlight / application search | `Super` + `Space` |
| Spotlight recent files | `Super` + `Shift` + `Space` |
| Spotlight Settings search | `Super` + `Shift` + `S` |
| Spotlight quick actions | `Super` + `Shift` + `A` |
| Terminal | `Super` + `Enter` |
| File manager | `Super` + `E` |
| System Settings | `Super` + `,` |
| Control Center | `Super` + `Shift` + `C` |
| Lock screen | `Super` + `L` |
| Close the active window | `Super` + `Q` |
| Toggle fullscreen | `Super` + `F` |
| Toggle floating | `Super` + `V` |
| Show the Dock | `Super` + `B` |
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

The updater requires a clean Git worktree and accepts fast-forward updates only. If the first HTTPS fetch encounters a transient `SSL_read` disconnect, it retries once over HTTP/1.1 with certificate verification still enabled. After pulling, it returns to the interactive installer and creates another backup before replacing configuration.

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

### Spotlight

Press `Super+Space` for the centered Walker Spotlight. Use `/` for files, `=`
for calculations and unit/currency conversion, `:` for clipboard history, `,`
for emoji and symbols, `.` for Unicode, and `;` to switch providers. Walker is
kept warm as a session service and Elephant supplies history-aware ranking. A
installer adds only the targeted providers used by these features, not the
catch-all provider bundle. See the [Spotlight documentation](docs/SPOTLIGHT.md)
for theming, keyboard operation, and troubleshooting.

### Dock

The Dock starts in resident mode with the Hyprland session and no longer uses
an auto-hide hotspot. When the Rust `nwg-dock` binary is available,
HyprSequoia uses the full native backend with drag ordering and launch bounce;
otherwise it falls back to the Go backend or a lightweight Waybar
implementation. See the [Dock documentation](docs/DOCK.md) and [appearance
guide](docs/APPEARANCE.md).

## Architecture

- `configs/hypr/conf.d/`: independently owned compositor modules
- `configs/sddm/`: HyprSequoia session entry backed by `start-hyprland`
- `configs/{waybar,kitty,walker,swaync}/`: desktop application configuration
- `configs/applications/`: HyprSequoia desktop application entries
- `configs/dock/`: native-first bottom Dock and Waybar fallback configuration
- `scripts/lib/`: shared installer and package primitives
- `scripts/bin/`: runtime commands installed in `~/.local/bin`
- `themes/` and `wallpapers/`: project visual assets and variants
- `docs/`: architecture, lifecycle, troubleshooting, and roadmap

Read [ARCHITECTURE.md](docs/ARCHITECTURE.md) and [CONTRIBUTING.md](CONTRIBUTING.md) before contributing.

## Troubleshooting

### Black screen followed by SDDM

This means the Hyprland session exited while starting; it is not merely a failed Waybar or Dock. Press `Ctrl` + `Alt` + `F3`, sign in to the same account, then update and rerun the installer:

```bash
cd ~/HyprSequoia   # use the actual checkout path if different
git pull --ff-only
./install.sh
```

This release migrates window, layer, and gesture rules to Hyprland 0.53+ syntax, adds an output-agnostic monitor fallback, and runs `Hyprland --verify-config` before installation can complete. It also installs a clearly named **HyprSequoia** SDDM entry that invokes `start-hyprland` and warns against selecting an unavailable UWSM-managed session. NVIDIA users must reboot after driver installation.

If SDDM still returns, run from the TTY:

```bash
~/.local/bin/hyprsequoia-diagnose
cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null
```

The report is saved under `~/.local/state/hyprsequoia/logs/diagnose-*.log`. Review it for personal information before sharing it.

### Component failures

Inspect the newest install and session logs in `~/.local/state/hyprsequoia/logs`, then run:

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

Yes. The installer preserves an installed NVIDIA driver. On a new setup it prompts for `nvidia-open-dkms` or `nvidia-dkms`, adds headers for standard Arch kernels, and installs `nvidia-utils` plus `egl-wayland`. RTX 50-series GPUs require the open kernel modules; RTX/GTX 16-series and newer hardware generally prefers them, while older supported GPUs should use proprietary DKMS. Reboot after installing the driver.

**Can I keep KDE?**

Yes, and this is the recommended migration path. Plasma removal runs only when explicitly selected or when `uninstall-kde.sh` is launched manually.

**Why might yay be required?**

Walker, Elephant providers, and some theme components may require the AUR. The
installer checks official repositories first and prefers an existing `yay` or
`paru`. If neither exists, it prints the `yay-bin` AUR source and asks for
confirmation; only an explicit `y` installs `base-devel`, clones the PKGBUILD,
and runs `makepkg`.

## Roadmap and versioning

HyprSequoia follows [Semantic Versioning](https://semver.org/). See [ROADMAP.md](docs/ROADMAP.md) and [CHANGELOG.md](CHANGELOG.md). Releases before 1.0 may change configuration interfaces.

## Contributing and license

Contributions are welcome under [CONTRIBUTING.md](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md). HyprSequoia is released under the [MIT License](LICENSE).
