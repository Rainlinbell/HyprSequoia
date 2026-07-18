# HyprSequoia menu bar

The menu bar is an output-agnostic Waybar module. It intentionally omits an
`output` or monitor name: Waybar creates a bar for every available Hyprland
output, and `separate-outputs` keeps window information local to each screen.

## Files

- `configs/waybar/config.jsonc` — module order, polling intervals, and click actions
- `configs/waybar/style.css` — layout, spacing, hover states, and typography
- `configs/waybar/theme.css` — active dark palette
- `configs/waybar/theme-light.css` — light palette selected by `theme.sh`
- `configs/waybar/scripts/` — small, independently testable status and popup helpers

The top-level arrays in `config.jsonc` are the customization API. Reorder a
module, remove it, or add a supported Waybar module without changing the shell
helpers. Custom status scripts return Waybar's JSON protocol (`text`,
`tooltip`, and `class`) and degrade to an informative unavailable state when an
optional command is missing.

## Popups and actions

The Apple logo, application labels, and Control Center open Walker's
layer-shell dmenu. This keeps popup placement and keyboard focus consistent on
all monitors. Notification Center uses SwayNC. Network and audio actions open
the native NetworkManager and PulseAudio/PipeWire panels.

Right-clicking the Apple logo or choosing **Toggle Light/Dark Mode** replaces
the imported palette and sends Waybar `SIGUSR2`; the compositor keeps the
rounded translucent surface blurred through the `layerrule = blur,waybar`
Hyprland rule.

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
