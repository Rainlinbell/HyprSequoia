# Troubleshooting

## Installer stops at AUR packages

`walker-bin`, some Elephant providers, and `bibata-cursor-theme` may come from
the AUR. On an older checkout the installer stops with a message that they
"require yay". Update the checkout and rerun it:

```bash
git pull --ff-only
./install.sh
```

The current installer accepts an existing `yay` or `paru`. If neither exists,
it prints the `yay-bin` AUR source and asks for explicit confirmation before
installing `base-devel`, cloning the PKGBUILD, and running `makepkg`. Declining
does not deploy or replace user configuration.

Current installations use the prebuilt `elephant-bin` split packages. Older
checkouts selected the source-built `elephant` package, which could end with
`proxy.golang.org: i/o timeout`, followed by `walker-bin` reporting an
unresolved `elephant` dependency. Update the repository and rerun the installer;
the binary package path does not compile or download Go modules:

```bash
git pull --ff-only
./install.sh
```

When upgrading a machine that already has the source-built `elephant` family,
the installer keeps that complete installed family instead of attempting an
unsafe noninteractive replacement with the conflicting `elephant-bin` family.
Fresh installations select the binary family. This prevents the Pacman prompt
`elephant-bin and elephant are in conflict. Remove elephant? [y/N]` from
aborting an otherwise healthy upgrade.

The AUR transaction retries once using the helper's download/build cache. A
second failure stops before configuration deployment and retains the full
installer log; repeated authentication, package-integrity, or build failures
still require investigation rather than an unbounded retry loop.

To install the helper manually instead:

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
```

## Pacman reports "exists in filesystem"

The installer retries an official package transaction once when every reported
conflict is an unowned, non-directory filesystem entry. It moves each entry to
`~/.local/state/hyprsequoia/backups/package-conflicts-*` before retrying; it
never deletes the entry or overwrites a path owned by another package. Owned
paths, directory conflicts, and malformed paths remain hard failures and must
be investigated rather than forced with a global overwrite.

The Chinese profile names the four concrete packages in the `fcitx5-im` group
plus `fcitx5-rime` explicitly, so official repository classification and repair
remain deterministic.

## Session returns to SDDM

Switch to a TTY with `Ctrl+Alt+F3` and sign in as the same non-root user. Do not
keep retrying SDDM: a compositor crash normally returns to the greeter without
showing the real error.

Run the bundled collector after updating/reinstalling HyprSequoia:

```bash
~/.local/bin/hyprsequoia-diagnose
```

If the command has not been installed yet, run it from the repository:

```bash
./scripts/bin/hyprsequoia-diagnose
```

The report is written to
`~/.local/state/hyprsequoia/logs/diagnose-*.log`. It includes versions, GPU and
driver information, config verification, bounded journal tails, crash reports,
and the latest runtime log. Review it before sharing it.

### Verify and start from the TTY

```bash
Hyprland --config ~/.config/hypr/hyprland.conf --verify-config
start-hyprland
```

Use `start-hyprland`, not the compositor binary directly. Hyprland 0.53 added
this wrapper for crash recovery and safe mode. The Arch package's SDDM entry
normally uses it already.

The installer adds `/usr/local/share/wayland-sessions/hyprsequoia.desktop` so
SDDM shows a distinct **HyprSequoia** entry. Its launcher invokes
`start-hyprland` with the deployed `hyprland.conf` explicitly, preventing an
unrelated `hyprland.lua` from shadowing the configuration that the installer
verified. Startup output is retained as
`~/.local/state/hyprsequoia/logs/startup-*.log`. Do not select **Hyprland
(uwsm-managed)** unless `uwsm` is installed. Inspect the available choices with:

```bash
grep -R -E '^(Name|Exec|TryExec)=' \
  /usr/local/share/wayland-sessions/hypr*.desktop \
  /usr/share/wayland-sessions/hypr*.desktop 2>/dev/null
```

HyprSequoia targets current Arch Hyprland and uses the 0.53+ `windowrule`,
`layerrule`, and `gesture` syntax. The installer now verifies the deployed
config and rolls it back if Hyprland rejects it. It also moves an existing
`~/.config/hypr/hyprland.lua` aside after backing it up, because Hyprland 0.55
would otherwise prefer the Lua file and ignore the validated `hyprland.conf`.

If an older installation reports `Using lua config found at
~/.config/hypr/hyprland.lua`, preserve that file and test the managed config:

```bash
mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.disabled
start-hyprland -- -c ~/.config/hypr/hyprland.conf
```

After updating, rerun `./install.sh` so SDDM receives the pinned launcher.

### NVIDIA checklist

Identify the device, installed module, and DRM mode:

```bash
lspci -nnk | grep -A3 -E 'VGA|3D|Display'
pacman -Q nvidia-open-dkms nvidia-dkms nvidia-open nvidia 2>/dev/null
cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null
dkms status 2>/dev/null
```

The modeset value must be `Y`. On Arch, current NVIDIA packages enable it by
default. If it is not enabled, create `/etc/modprobe.d/nvidia.conf` with
`options nvidia_drm modeset=1`, rebuild the initramfs with `sudo mkinitcpio -P`,
and reboot. RTX 50-series hardware requires `nvidia-open-dkms`; open modules are
also normally preferred for GTX 16-series/RTX hardware, while older supported
cards may need `nvidia-dkms`. Every installed kernel needs its matching headers
package. See the [Hyprland NVIDIA guide](https://wiki.hypr.land/0.55.0/Nvidia/)
and [ArchWiki NVIDIA page](https://wiki.archlinux.org/title/NVIDIA) before
changing an existing working driver stack.

Hybrid/multi-GPU systems may need an explicit `AQ_DRM_DEVICES` order, but do not
guess `/dev/dri/card*` numbers. Resolve the stable `by-path` devices first and
follow the [Hyprland multi-GPU guide](https://wiki.hypr.land/Configuring/Multi-GPU/).

### Raw commands

When the collector cannot run, capture these manually:

```bash
journalctl -b -u sddm --no-pager -n 120
journalctl --user -b --no-pager -n 160
find ~/.cache/hyprland -maxdepth 1 -type f -name 'hyprlandCrashReport*' \
  -print -exec tail -n 100 {} \;
```

## Black wallpaper or missing bar

This is not an SDDM login loop: the compositor remains running. Inspect the
newest `session-*`, `wallpaper-*`, and `dock-*` files under
`~/.local/state/hyprsequoia/logs`. Run Waybar in a terminal to expose parser
errors:

```bash
waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css
```

The wallpaper helper rasterizes the bundled SVG to
`~/.cache/hyprsequoia/default.png` with ImageMagick before starting hyprpaper.
If the converter is removed later, the helper logs the problem and leaves the
compositor running. Reload Hyprland with `hyprctl reload` after config edits.

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
