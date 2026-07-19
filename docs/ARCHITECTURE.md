# Architecture

HyprSequoia separates lifecycle code from session configuration. Root commands
are stable user entry points. `scripts/lib` owns shared behavior; runtime helpers
in `scripts/bin` must remain independently executable. Each application owns one
directory below `configs`.

Project-owned application launchers live in `configs/applications` and are
installed under `~/.local/share/applications`. They are recorded in the same
manifest as runtime helpers so restore removes only entries owned by this
project.

Hyprland loads numbered modules in a predictable order: environment, monitor
fallback, input, appearance, rules, bindings, then autostart. A module may rely
on earlier variables but must not redefine another module's responsibility.
Local users can edit `~/.config/hypr/local.conf`, which is sourced last; the
installer creates an empty placeholder and preserves it across updates so
monitor and device overrides are never lost.

## Installation transaction

1. Validate user and operating system.
2. Resolve profile and hardware hints.
3. Install packages before modifying user configuration.
4. Back up only component trees the project manages.
5. Deploy files and record each path in the installation manifest.
6. Verify the active Hyprland and JSON configurations without starting a session.
7. Validate the SDDM/login stack and enable required system services.
8. Install the local `start-hyprland` session entry.
9. Commit; on an earlier failure, restore the configuration snapshot.

Package installation itself is not rolled back: removing newly installed shared
packages could break unrelated applications. Configuration rollback is bounded
and deterministic.

## Session startup

Hyprland starts one `hyprsequoia-session` helper after importing the Wayland
environment. The helper launches each optional service independently and writes
one timestamped session log. A missing or crashing bar, wallpaper provider,
notification daemon, clipboard watcher, or Dock therefore cannot terminate the
compositor or hide the cause of a partial startup.

Spotlight follows the same isolation boundary. Elephant owns provider data,
while Walker stays warm as a GTK GApplication service and is activated by the
`Super+Space` binding. Recent-file, Settings, and quick-action pickers are
bounded scripts that reuse Walker's dmenu mode instead of adding resident
indexers or another launcher.

The System Settings hub follows the same boundary: `hyprsequoia-settings`
routes to existing NetworkManager, Blueman, PipeWire, Hyprland, and project
helpers rather than introducing another privileged daemon. SwayNC owns the
Control Center surface and calls `hyprsequoia-control` for idempotent toggle
state. `hyprsequoia-theme` is the single writer for generated appearance
palettes across Waybar, Dock, SwayNC, and Walker.

## Dock backends

The Dock is isolated under `configs/dock` and launched by its lifecycle wrapper.
The wrapper feature-detects the Rust `nwg-dock` CLI, then the Hyprland-specific Go
backend, and finally starts a Waybar-only fallback. This keeps the base install
usable without compiling Rust while allowing users to opt into the complete
native interaction model later. Every backend starts in resident mode, so no
pointer hotspot is required. Backend state, recent applications, and pins are
kept outside the repository in XDG state/cache locations.

## Security boundaries

The installer runs as the user and elevates only package/service operations.
Runtime menu actions use systemd-logind, so authorization remains governed by
polkit. No remote code is piped into a shell. Backups use a private umask.
