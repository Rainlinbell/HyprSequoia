# Architecture

HyprSequoia separates lifecycle code from session configuration. Root commands
are stable user entry points. `scripts/lib` owns shared behavior; runtime helpers
in `scripts/bin` must remain independently executable. Each application owns one
directory below `configs`.

Hyprland loads numbered modules in a predictable order: environment, input,
appearance, rules, bindings, then autostart. A module may rely on earlier
variables but must not redefine another module's responsibility. Local users can
create `~/.config/hypr/local.conf` and add it as the final source in
`hyprland.conf`; the installer does not create that override file.

## Installation transaction

1. Validate user and operating system.
2. Resolve profile and hardware hints.
3. Install packages before modifying user configuration.
4. Back up only component trees the project manages.
5. deploy files and record each path in the installation manifest.
6. Enable required system services.
7. Commit; on an earlier failure, restore the configuration snapshot.

Package installation itself is not rolled back: removing newly installed shared
packages could break unrelated applications. Configuration rollback is bounded
and deterministic.

## Dock backends

The Dock is isolated under `configs/dock` and launched by its lifecycle wrapper.
The wrapper feature-detects the Rust `nwg-dock` CLI, then the Hyprland-specific Go
backend, and finally starts a Waybar-only fallback. This keeps the base install
usable without compiling Rust while allowing users to opt into the complete
native interaction model later. Backend state, recent applications, and pins
are kept outside the repository in XDG state/cache locations.

## Security boundaries

The installer runs as the user and elevates only package/service operations.
Runtime menu actions use systemd-logind, so authorization remains governed by
polkit. No remote code is piped into a shell. Backups use a private umask.
