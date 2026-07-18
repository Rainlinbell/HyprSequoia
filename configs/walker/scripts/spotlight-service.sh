#!/usr/bin/env bash
# Keep Walker's GTK service warm so SUPER+SPACE opens without cold-start lag.
set -u

export PATH="$HOME/.local/bin:$PATH"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprsequoia"
log_dir="$state_dir/logs"
mkdir -p "$log_dir"
log="$log_dir/spotlight-$(date +%Y%m%d-%H%M%S).log"

if [[ -z ${WAYLAND_DISPLAY:-} ]]; then
  printf '[HyprSequoia Spotlight] no Wayland display; not starting Walker\n' >>"$log"
  exit 0
fi

if ! command -v walker >/dev/null 2>&1; then
  printf '[HyprSequoia Spotlight] walker is not installed\n' >>"$log"
  exit 0
fi

# Avoid a duplicate GApplication service when a user already enabled the
# upstream systemd unit. `pgrep` is optional; launching Walker is still safe
# when procps is not installed because GApplication de-duplicates the service.
if command -v pgrep >/dev/null 2>&1 && pgrep -u "$(id -u)" -x walker >/dev/null 2>&1; then
  exit 0
fi

exec walker --gapplication-service >>"$log" 2>&1
