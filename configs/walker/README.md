# HyprSequoia Spotlight

This directory is the complete Walker frontend for the HyprSequoia Spotlight
palette. It is intentionally separate from Waybar and Dock so it can be
replaced or disabled without changing the compositor session.

## Files

- `config.toml` — centered, keyboard-first Walker profile and provider routing.
- `themes/sequoia/` — original GTK4 layout, item templates, and WhiteSur-style
  dark palette.
- `scripts/spotlight-service.sh` — keeps Walker's GApplication service warm.
- `scripts/recent-files.sh` — lightweight recent-file picker using XDG folders.
- `scripts/settings-search.sh` — searches Settings desktop entries.
- `scripts/quick-actions.sh` — reversible Hyprland/session actions.

## Prefixes

| Prefix | Search mode |
|---|---|
| none | Applications, files, calculations, clipboard, symbols, Unicode |
| `/` | Files |
| `=` | Calculator, unit conversion, currency conversion |
| `:` | Clipboard history |
| `,` | Emoji and symbol search |
| `.` | Unicode search |
| `;` | Provider switcher |

`elephant-calc` delegates unit and currency expressions to qalc. Examples:
`=50 km to miles` and `=100 USD to EUR`.

## Shortcuts

- `Super + Space` — full Spotlight palette.
- `Super + Shift + Space` — recent files.
- `Super + Shift + S` — Settings search.
- `Super + Shift + A` — quick actions.

Arrow keys, `Ctrl+J`/`Ctrl+K`, `Tab`, `Enter`, and `Escape` are all supported;
mouse input is disabled by default.

## Dependencies

The installer adds only the providers used by this profile:
`elephant`, `elephant-desktopapplications`, `elephant-calc`,
`elephant-files`, `elephant-clipboard`, `elephant-symbols`,
`elephant-unicode`, and `elephant-providerlist`. These are the targeted
providers required by the advertised Spotlight modes; the installer does not
pull the catch-all provider bundle. No web service, tracker, or second launcher
is required.

## Customization

Change `theme = "sequoia"` in `config.toml` to select another theme directory.
Edit the CSS variables in `themes/sequoia/style.css` for the palette, then
reload Walker with `walker --debug` or restart the session service. Hyprland's
`layerrule` for the `walker` namespace supplies the compositor-side blur and
fade; no monitor name is embedded in this module.
