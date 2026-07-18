# HyprSequoia

HyprSequoia is an original, modular Hyprland desktop experience for Arch Linux,
inspired by the clarity and spatial rhythm of macOS Sequoia. It is a maintained
desktop distribution layer—not a dump of personal dotfiles.

> **Project status:** v0.1 foundation. The session, installer, backup/restore,
> menu bar, launcher, notifications, lock screen, wallpaper, and daily-use
> integrations are functional. Dock magnification, drag reordering, unified
> Control Center, automatic light/dark scheduling, and graphical installer are
> planned and are not represented as finished features.

## Install

Start from an updated Arch Linux installation with a regular sudo-enabled user
and working internet access:

```bash
git clone https://github.com/Rainlinbell/HyprSequoia.git
cd HyprSequoia
chmod +x install.sh update.sh restore.sh uninstall-kde.sh
./install.sh
```

The interactive installer detects the GPU, installs the selected package
profile, backs up managed configuration, deploys modules, enables networking and
Bluetooth, and rolls configuration back if deployment fails. Log out and choose
**Hyprland** in SDDM after installation.

The installer never removes Plasma implicitly. The KDE migration option invokes
a separate confirmation-based tool and always preserves SDDM.

## Daily use

| Action | Shortcut |
|---|---|
| Spotlight / application search | `Super` + `Space` |
| Terminal | `Super` + `Enter` |
| File manager | `Super` + `E` |
| Lock | `Super` + `L` |
| Region screenshot | `Print` |
| Full screenshot | `Shift` + `Print` |
| Close window | `Super` + `Q` |

Menu-bar network, Bluetooth, sound, battery, calendar, and notification items
are clickable. Hardware media and brightness keys work through PipeWire and
`brightnessctl`.

## Update and restore

```bash
./update.sh       # requires a clean Git worktree; fast-forward updates only
./restore.sh      # restores the most recent pre-install managed config
```

Backups and logs are stored under
`~/.local/state/hyprsequoia`. See [lifecycle documentation](docs/LIFECYCLE.md)
before removing or customizing managed files.

## Architecture

- `configs/hypr/conf.d/`: independently owned compositor modules
- `configs/{waybar,kitty,walker,swaync}/`: application configuration
- `scripts/lib/`: shared installer and package primitives
- `scripts/bin/`: small runtime commands installed into `~/.local/bin`
- `themes/` and `wallpapers/`: project-owned visual assets and variants
- `docs/`: operations, troubleshooting, architecture, and roadmap

Read [ARCHITECTURE.md](docs/ARCHITECTURE.md) before contributing.

## Troubleshooting

First inspect the newest file in `~/.local/state/hyprsequoia/logs`. Validate the
session with `hyprctl systeminfo`, then restart individual components rather than
the entire session (`killall waybar && waybar`, for example). Detailed fixes are
in [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## FAQ

**Is this a WhiteSur or another dotfiles project?** No. The architecture,
configuration, scripts, and bundled artwork are original. Optional third-party
themes remain under their upstream licenses and are not vendored.

**Does it support NVIDIA?** The installer detects NVIDIA hardware. Driver
selection remains explicit because proprietary/open driver suitability depends
on GPU generation; see the troubleshooting guide.

**Can I keep KDE?** Yes. This is the default and recommended migration path.

**Why is Walker installed through yay?** Walker may require the AUR. The
installer checks current repository
availability before deciding and refuses to bootstrap an AUR helper silently.

## Roadmap and versioning

HyprSequoia follows [Semantic Versioning](https://semver.org/). See
[ROADMAP.md](docs/ROADMAP.md) and [CHANGELOG.md](CHANGELOG.md). Releases before
1.0 may intentionally change configuration interfaces.

## Contributing and license

Contributions are welcome under [CONTRIBUTING.md](CONTRIBUTING.md) and our
[Code of Conduct](CODE_OF_CONDUCT.md). HyprSequoia is MIT licensed.
