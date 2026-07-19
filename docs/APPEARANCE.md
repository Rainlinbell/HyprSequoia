# Tahoe appearance system

HyprSequoia uses an original GTK/CSS implementation inspired by the visual
principles of macOS Tahoe. It does not copy Apple assets or third-party
dotfiles. The shared design language consists of transparent navigation,
layered translucent surfaces, bright inner highlights, large continuous
corners, restrained blue accents, and short ease-out transitions.

## Covered surfaces

- Waybar is a transparent menu bar whose controls become glass capsules on
  hover.
- The resident Dock uses a lower-opacity glass surface, 26px corners, running
  indicators, focus highlights, and icon hover scaling.
- SwayNC is both Control Center and Notification Center. It contains Wi-Fi,
  Bluetooth, appearance, Night Shift, Settings, capture, volume, brightness,
  media, calendar, Do Not Disturb, and notification history.
- Walker supplies the Spotlight and System Settings surfaces with the same
  palette, search field geometry, selection treatment, and preview material.
- Hyprlock, Kitty, Hyprland windows, shadows, blur, and animation curves use
  matching spacing, radius, opacity, and accent values.
- The default `tahoe.png` is an original alpine-lake wallpaper generated for
  this project; it is not an Apple wallpaper or a reproduction of one.

Inter is installed from the Arch official repository and is the primary UI
font. Noto Sans CJK provides Chinese fallback, while JetBrainsMono Nerd Font is
reserved for icon glyphs and terminal content.

GTK applications use the matching light/dark `adw-gtk3` palette with Papirus
icons and the Bibata Ice cursor. This keeps third-party toolkit windows
coherent without bundling or copying Apple themes or proprietary assets.

Linux applications keep their own toolkit layout. HyprSequoia sets the GTK
light/dark preference but does not overwrite application-specific themes or
pretend that KDE, GTK, and browser content can be made pixel-identical.

## Appearance commands

```bash
hyprsequoia-theme dark
hyprsequoia-theme light
hyprsequoia-theme toggle
hyprsequoia-theme status
```

The controller atomically updates the generated `theme.css` files for Waybar,
Dock, SwayNC, and Walker, then reloads the components that support live CSS
reload. The selected mode is stored at
`~/.local/state/hyprsequoia/appearance` and restored by later installs.

Open the settings hub with `Super` + `,`, or right-click Control Center:

```bash
hyprsequoia-settings
```

`Super` + `Shift` + `C` opens Control Center directly.

To reapply every running surface without logging out:

```bash
hyprsequoia-refresh
```

## Customization

Edit immutable palette sources such as `theme-dark.css` and `theme-light.css`,
not the generated `theme.css` files. Run `hyprsequoia-theme dark` or
`hyprsequoia-theme light` after changes. Component structure remains in each
component's `style.css`; keeping geometry separate from colors makes later
theme variants and accessibility adjustments predictable.

Compositor blur is applied through output-agnostic Hyprland layer rules. The
CSS remains readable without blur, so a disabled GPU effect degrades to a
translucent surface instead of making controls invisible.
