# Changelog

All notable changes follow Keep a Changelog and Semantic Versioning.

## [Unreleased]

### Added

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

- Migrated Hyprland window, layer, gesture, and hyprpaper configuration to the
  syntax used by current Arch packages.
- NVIDIA installs now preserve an existing driver or prompt for the appropriate
  open/proprietary DKMS module and matching standard-kernel headers.
- Optional session components now start independently with timestamped logs.

### Fixed

- Prevented SDDM login loops caused by removed Hyprland configuration keys and
  missing generic monitor rules.
- Replaced substring-based GPU detection with PCI vendor IDs, installed both
  graphics stacks on hybrid systems, and prevented unsupported Arch partial
  upgrades that could leave Hyprland libraries ABI-incompatible.
- Added pre-login Hyprland/JSON validation, transactional rollback, Lua-config
  precedence handling, and a bounded TTY diagnostic collector.
- Removed the obsolete Hyprlock `general:grace` option.

## [0.1.0] - 2026-07-19

### Added

- Initial public foundation.
