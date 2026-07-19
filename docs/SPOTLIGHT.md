# Spotlight

HyprSequoia Spotlight is a centered macOS Tahoe-style command palette built
from Walker (GTK4/layer-shell) and Elephant (the provider service). The module
is Wayland-native and remains independent from the menu bar and Dock.

## Startup path

1. Hyprland binds `Super+Space` to `walker`.
2. `hyprsequoia-session` starts Elephant and the Walker GApplication service
   once per login.
3. Walker reuses the warm service, so opening the palette does not start a new
   provider process for every query.
4. The `walker` layer namespace is blurred and animated by Hyprland; the GTK
   theme supplies the rounded WhiteSur surface and selection states.

If a systemd user unit already runs Walker, the service helper detects it and
does not create a second process.

## Search model

The default query combines application search, files, calculations, clipboard
history, symbols, and Unicode. Elephant's application provider keeps usage
history and currently open applications in its ranking. Prefixes make heavier
providers opt-in when a user wants a focused result set:

| Input | Provider | Example |
|---|---|---|
| `/` | files | `/report.pdf` |
| `=` | calc | `=sqrt(2)` |
| `:` | clipboard | `:ssh host` |
| `,` | symbols | `,heart` |
| `.` | unicode | `.greek alpha` |
| `;` | providerlist | switch provider |

The calculator provider also handles unit and currency conversion when qalc is
available. It is intentionally offline-first; exchange-rate freshness is
controlled by qalc rather than by a custom network script.

## Auxiliary pickers

The scripts under `configs/walker/scripts/` cover workflows that do not need a
resident database:

- `recent-files.sh` scans common XDG folders to a bounded depth and presents
  the newest 80 files through Walker dmenu.
- `settings-search.sh` filters `.desktop` files by Settings/System categories
  and launches the selected desktop ID.
- `quick-actions.sh` exposes lock, Dock/theme toggles, reloads, screenshots,
  and system settings without destructive power actions.

All three are keyboard-only and exit cleanly if an optional command is absent.

## Theme and blur

`configs/walker/themes/sequoia/` contains the layout and CSS rather than
depending on a system-wide theme. The panel is centered by the GTK layout and
uses SF Pro fallbacks (`Inter`, `Cantarell`). Hyprland's `walker` layer rules
enable blur, popup blur, and a fade animation. If the compositor does not
support blur, the opaque translucent palette remains readable.

## Troubleshooting

```bash
elephant listproviders
walker --debug
pgrep -a -u "$USER" 'walker|elephant'
journalctl --user -b --no-pager | grep -Ei 'walker|elephant|spotlight'
```

If the palette opens but has no results, install the missing provider package
and restart Elephant. If it opens slowly, ensure
`~/.config/walker/scripts/spotlight-service.sh` is executable and that the
session log under `~/.local/state/hyprsequoia/logs/` contains a successful
`--gapplication-service` start.
