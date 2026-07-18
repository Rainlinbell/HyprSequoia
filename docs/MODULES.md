# Module reference

| Module | Purpose | Runtime dependency |
|---|---|---|
| Hyprland | Composition, input, animation, bindings | `hyprland` |
| Waybar | Sequoia-style menu bar and status controls | `waybar`, `networkmanager`, `bluetoothctl` |
| Dock | Bottom-centered application dock with native/fallback backends | `nwg-dock` (optional), `waybar` |
| Walker | Spotlight-style search | `walker-bin` |
| SwayNC | Notifications and media panel | `swaync` |
| Hyprlock / Hypridle | Lock and idle policy | `hyprlock`, `hypridle` |
| Hyprpaper | Project wallpaper | `hyprpaper` |
| Kitty | Default terminal | `kitty` |
| Screenshot helper | Region/full capture and clipboard | `grim`, `slurp`, `wl-clipboard` |

Each module can be stopped or replaced independently. Remove its `exec-once`
line and corresponding application directory; avoid editing unrelated modules.

## Menu bar customization

The bar is deliberately output-agnostic: `configs/waybar/config.jsonc` does not
name a monitor, so Waybar starts one instance per available output. Left, center,
and right module arrays can be reordered without changing scripts. Status
helpers live in `configs/waybar/scripts/`; each custom module returns a small
JSON object containing text, tooltip, and state class.

`theme.css` is the active palette. Right-click the Apple logo or choose
**Toggle Light/Dark Mode** in Control Center to switch between the bundled dark
and light palettes. The switch is stored in
`~/.local/state/hyprsequoia/waybar-theme` and Waybar is reloaded with SIGUSR2.
