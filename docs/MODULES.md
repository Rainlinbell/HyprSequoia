# Module reference

| Module | Purpose | Runtime dependency |
|---|---|---|
| Hyprland | Composition, input, animation, bindings | `hyprland` |
| Waybar | Menu bar and status controls | `waybar` |
| Walker | Spotlight-style search | `walker-bin` |
| SwayNC | Notifications and media panel | `swaync` |
| Hyprlock / Hypridle | Lock and idle policy | `hyprlock`, `hypridle` |
| Hyprpaper | Project wallpaper | `hyprpaper` |
| Kitty | Default terminal | `kitty` |
| Screenshot helper | Region/full capture and clipboard | `grim`, `slurp`, `wl-clipboard` |

Each module can be stopped or replaced independently. Remove its `exec-once`
line and corresponding application directory; avoid editing unrelated modules.
