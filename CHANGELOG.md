# Changelog

All notable changes follow Keep a Changelog and Semantic Versioning.

## [Unreleased]

### Added

- Original Tahoe alpine-lake PNG wallpaper designed for translucent desktop
  surfaces, with the existing SVG retained as a converter fallback.
- Stable desktop-entry fallback proxies and a bounded
  `hyprsequoia-dock-launch` bridge into the project launcher fallbacks.
- `hyprsequoia-refresh` for applying menu-bar, Control Center, Spotlight,
  wallpaper, and Dock changes to an active HyprSequoia session.
- Tahoe Liquid Glass appearance system spanning the transparent menu bar,
  resident Dock, Control Center, Notification Center, Spotlight, lock screen,
  terminal, Hyprland decoration, and dark/light palettes.
- Unified SwayNC Control Center with Wi-Fi, Bluetooth, appearance, Night Shift,
  Settings, capture, volume, brightness, media, Do Not Disturb, and history.
- Project-owned `hyprsequoia-settings`, `hyprsequoia-theme`, and
  `hyprsequoia-control` runtime tools plus a desktop application entry.
- Sequoia-style Walker Spotlight with a centered blurred theme, preview pane,
  warm service startup, keyboard navigation, ranked multi-provider search,
  recent files, Settings search, and quick actions.
- Targeted Elephant providers for applications, files, calculations,
  unit/currency conversion, clipboard history, emoji/symbols, and Unicode.
- Explicit, consent-based `yay-bin` bootstrap when required AUR packages are
  requested and neither `yay` nor `paru` is installed.
- A named SDDM `HyprSequoia` session that always uses `start-hyprland`, plus
  SDDM version/backend and unavailable-UWSM validation.
- Native-first Sequoia Dock wrapper with Rust `nwg-dock`, Go fallback, and
  Waybar fallback configurations.
- Dock launchers, running indicators, recent applications, Trash, favorites
  reorder support, auto-hide watcher, themes, and lifecycle documentation.
- Sequoia-style multi-monitor Waybar menu bar with Apple/app menus, window title,
  clipboard, keyboard layout, network, Bluetooth, VPN, brightness, audio,
  microphone, battery, calendar, clock, notifications, and Control Center.
- Modular Waybar status scripts with dark/light palette switching.
- Chinese-first GitHub README with an English language switch and expanded usage instructions.
- Original modular Hyprland session foundation.
- Transactional interactive Arch installer with profiles and logs.
- Managed backup, restore, update, and conservative Plasma migration tools.
- Waybar menu bar, Walker launcher, SwayNC notifications, Hyprlock, Hypridle,
  Hyprpaper, Kitty, screenshots, media keys, and Chinese input profile.
- CI linting, contributor templates, architecture and operations documentation.

### Changed

- Install the official `inter-font`, `adw-gtk-theme`, and Papirus icons; use
  Inter for desktop UI text and compact the menu-bar status cluster.
- Install Firefox and, when no compatible editor already exists, the official
  Code build with the full profile; retain proxy fallbacks for minimal profiles.
- Run every Dock backend in permanent resident mode and make `Super+B` a
  recovery/show action instead of an auto-hide toggle.
- Route Apple-menu Settings and Dock Settings through the unified HyprSequoia
  settings hub, while retaining installed desktop settings tools as fallbacks.
- Migrated Hyprland window, layer, gesture, and hyprpaper configuration to the
  syntax used by current Arch packages.
- NVIDIA installs now preserve an existing driver or prompt for the appropriate
  open/proprietary DKMS module and matching standard-kernel headers.
- Optional session components now start independently with timestamped logs.

### Fixed

- Stage Go `nwg-dock-hyprland` CSS in its real XDG configuration directory,
  scope glass styling to the Dock root, and migrate historical pins to an
  installed client ID or guaranteed launch proxy so clicks no longer silently
  execute missing commands.
- Start one Go Dock instance per detected output, track every PID, honor XDG
  cache/data locations, and send visibility signals directly to owned PIDs.
- Match current SwayNC GTK4 button, calendar, media, and notification nodes and
  constrain the two-column Control Center to low-resolution displays.
- Retry one failed updater fetch over HTTP/1.1 without disabling TLS
  verification, covering intermittent GitHub `SSL_read` disconnects.
- Install the official Hyprland-native Dock by default; make the Waybar fallback
  visible/clickable instead of polling an unusably narrow autohide hotspot.
- Install `librsvg`, prefer `rsvg-convert`, reject empty cached wallpaper images,
  and add explicit wallpaper startup logging before launching hyprpaper.
- Added VM graphics preflight: Mesa utilities are installed for every profile;
  VMware guests receive `open-vm-tools` services and installation stops before
  SDDM deployment when no DRM render node exists or EGL reports disabled 3D.
- Flag VMware's `No 3D enabled` signature directly in diagnostic reports.
- Detect and repair zero-byte `/usr/lib/*.so*` files by reinstalling and
  verifying their owning official package; unowned and foreign-package files
  remain warnings rather than unsafe automatic mutations.
- Made Elephant package-family selection upgrade-aware: existing source-package
  installations remain on their installed family, while fresh installations
  use binaries, avoiding a noninteractive `elephant-bin`/`elephant` conflict.
- Added a guarded Pacman transaction retry that backs up only unowned
  `exists in filesystem` conflicts, refuses owned/directory paths, and then
  retries once; the Chinese profile now expands `fcitx5-im` to concrete
  official packages for deterministic resolution.
- Added one bounded AUR retry that reuses the helper cache, while keeping
  repeated package/build errors as hard failures before configuration deploy.
- Recorded the top-level lifecycle scripts as executable in Git and removed the
  conflicting post-clone `chmod` step that made later fast-forward pulls fail.
- Switched Spotlight's Elephant runtime and targeted providers to their
  prebuilt AUR split packages, avoiding unnecessary Go compilation and
  `proxy.golang.org` failures during a normal desktop installation.
- Made `update.sh` fetch and fast-forward the resolved remote branch explicitly,
  report the before/after commit, support checkouts without an upstream, and
  state clearly that the subsequent installer must finish before deployment.
- Pinned the SDDM session to the deployed and verified `hyprland.conf`, so a
  preferred `hyprland.lua` cannot silently shadow it; startup output and actual
  configuration precedence are now included in diagnostics.
- Prevented SDDM login loops caused by removed Hyprland configuration keys and
  missing generic monitor rules.
- Replaced substring-based GPU detection with PCI vendor IDs, installed both
  graphics stacks on hybrid systems, and prevented unsupported Arch partial
  upgrades that could leave Hyprland libraries ABI-incompatible.
- Added pre-login Hyprland/JSON validation, transactional rollback, Lua-config
  precedence handling, and a bounded TTY diagnostic collector.
- Expanded login-loop diagnostics with SDDM session selection, per-user logs,
  config overrides, DKMS state, and stable DRM device paths.
- Removed the obsolete Hyprlock `general:grace` option.

## [0.1.0] - 2026-07-19

### Added

- Initial public foundation.
