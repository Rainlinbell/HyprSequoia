# HyprSequoia Dock

The Dock is a separate, bottom-centered Wayland layer. It is started by
`~/.config/dock/scripts/dock.sh` after the normal top menu bar and does not
share the top bar's Waybar process or configuration.

## Backend selection

The launcher uses this order:

1. **Rust `nwg-dock`** — the feature-complete optional backend. It provides
   per-monitor windows and hotplug handling, cursor-tracked auto-hide,
   running/focused indicators, launch bounce, icon scaling, and
   drag-to-reorder/remove. Install its GTK4 dependencies and binary when you
   want the complete macOS-style behavior:

   ```bash
   sudo pacman -S --needed gtk4 gtk4-layer-shell rust
   cargo install nwg-dock
   ```

2. **Go `nwg-dock-hyprland`** — the default installed native backend. It
   provides Hyprland client buttons, pinned apps, focus state, reliable
   auto-hide hotspots, CSS, and multiple outputs. It does not provide the Rust
   backend's drag ordering, launch animation, or pointer magnification.

3. **Waybar `wlr/taskbar`** — the last-resort fallback already installed by
   HyprSequoia. It supplies static launchers, running task buttons, active
   indicators, a recent-app menu, Trash, and hover scaling. It remains visible
   and clickable because Waybar cannot provide a reliable pointer-aware Dock
   hotspot; auto-hide belongs to either native backend.

The Rust backend is a separate upstream Wayland application, not vendored into
this repository. The wrapper detects it without hardcoding a monitor name or
requiring an AUR helper. See the upstream feature and configuration reference:
[nwg-dock 0.5](https://docs.rs/crate/nwg-dock/latest).

## Files

- `configs/dock/config.jsonc` — Waybar fallback layout and launcher modules
- `configs/dock/style.css` — Waybar fallback glass surface and hover states
- `configs/dock/nwg-dock-config.toml` — native backend behavior/layout defaults
- `configs/dock/nwg-style.css` — native backend dark GTK style
- `configs/dock/scripts/dock.sh` — backend detection and lifecycle commands
- `configs/dock/scripts/launch.sh` — app launch mapping and recent history
- `configs/dock/scripts/reorder.sh` — fallback favorites and native pin sync
- `configs/dock/favorites.list` — default fallback favorites order

## Controls

`Super` + `B` toggles the Dock. The command-line lifecycle controls are:

```bash
~/.config/dock/scripts/dock.sh status
~/.config/dock/scripts/dock.sh show
~/.config/dock/scripts/dock.sh hide
~/.config/dock/scripts/dock.sh restart
~/.config/dock/scripts/theme.sh toggle
```

The native Rust dock supports direct drag-to-reorder and drag-off-to-remove.
On the Waybar fallback, right-click any favorite and use the reorder menu; the
result is saved to `~/.config/dock/favorites.list` and synchronized to the
shared native pin file at `~/.cache/mac-dock-pinned`.

Favorite launches are stored, newest first, in
`~/.local/state/hyprsequoia/dock/recent`. The list is bounded and contains only
the project's known application IDs; no window titles or document paths are
persisted.

## Customization

Edit `favorites.list` for the fallback order, then restart the Dock. Keep
personal CSS overrides in a separate file and pass it through a local wrapper
so updates do not overwrite them. The native config follows the upstream TOML
schema; CLI flags in `dock.sh` intentionally override only runtime-sensitive
settings such as auto-hide and the launcher command.
