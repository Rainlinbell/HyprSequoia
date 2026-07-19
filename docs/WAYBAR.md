# HyprSequoia menu bar

The menu bar is an output-agnostic Waybar module. It intentionally omits an
`output` or monitor name: Waybar creates a bar for every available Hyprland
output, and `separate-outputs` keeps window information local to each screen.

## Files

- `configs/waybar/config.jsonc` — module order, polling intervals, and click actions
- `configs/waybar/style.css` — layout, spacing, hover states, and typography
- `configs/waybar/theme.css` — active dark palette
- `configs/waybar/theme-{dark,light}.css` — immutable Tahoe palettes
- `configs/waybar/scripts/` — small, independently testable status and popup helpers

The top-level arrays in `config.jsonc` are the customization API. Reorder a
module, remove it, or add a supported Waybar module without changing the shell
helpers. Custom status scripts return Waybar's JSON protocol (`text`,
`tooltip`, and `class`) and degrade to an informative unavailable state when an
optional command is missing.

## Popups and actions

The Apple logo and application labels use Walker's layer-shell dmenu. Control
Center and Notification Center use one Tahoe-styled SwayNC panel with network,
Bluetooth, appearance, Night Shift, audio, brightness, media, Do Not Disturb,
and notification controls. Right-click Control Center to open the project-owned
System Settings hub.

Right-clicking the Apple logo or selecting the appearance tile runs
`hyprsequoia-theme`. It atomically replaces the active Waybar, Dock, SwayNC,
and Walker palettes, updates the GTK color preference, reloads the affected
components, and saves the choice in XDG state. The menu bar background itself
is transparent; hover controls and popups use Liquid Glass surfaces.

## Adding a module

1. Add the module identifier to one of `modules-left`, `modules-center`, or
   `modules-right`.
2. Add its configuration object below the arrays.
3. If it is a custom script, place the script in `configs/waybar/scripts/`, add
   a `# shellcheck source=common.sh` line when sourcing the helper, and test it
   with `bash -n` plus a representative invocation.
4. Add the module's package or optional dependency to the installer only when
   it is available in Arch's official repositories or its AUR requirement is
   explicitly documented.

After an edit, reload with `killall -SIGUSR2 waybar` or restart Waybar from a
terminal so parser errors remain visible.
