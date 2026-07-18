#!/usr/bin/env bash
# Start, stop, and control the native or Waybar fallback dock backend.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
config_dir=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprsequoia/logs"
mkdir -p "$log_dir" "$DOCK_RUNTIME_DIR"

running() { [[ -r $DOCK_PID_FILE ]] && kill -0 "$(<"$DOCK_PID_FILE")" 2>/dev/null; }

current_backend() {
  local backend
  if [[ -r $DOCK_BACKEND_FILE ]]; then
    IFS= read -r backend <"$DOCK_BACKEND_FILE" || true
    printf '%s\n' "${backend:-waybar}"
  else
    printf '%s\n' waybar
  fi
}

# Return the Rust backend only when its feature-bearing CLI is present.
native_binary() {
  local candidate help path
  for candidate in "$HOME/.cargo/bin/nwg-dock" "$(command -v nwg-dock 2>/dev/null || true)"; do
    [[ -x $candidate ]] || continue
    help=$("$candidate" --help 2>&1 || true)
    if grep -q -- '--launch-animation' <<<"$help" && grep -q -- '--hide-timeout' <<<"$help"; then
      path=$candidate
      printf '%s\n' "$path"
      return 0
    fi
  done
  return 1
}

# Seed the native backend's shared pin file from the project defaults once.
sync_initial_pins() {
  [[ -r $DOCK_FAVORITES ]] || return 0
  mkdir -p "$HOME/.cache"
  if [[ ! -e $HOME/.cache/mac-dock-pinned ]]; then
    # shellcheck disable=SC2016
    sed -e 's/^finder$/thunar/' -e 's/^files$/thunar/' -e 's/^code$/code/' \
      -e 's/^terminal$/kitty/' -e 's/^settings$/systemsettings/' \
      "$DOCK_FAVORITES" | awk 'NF && !seen[$0]++' >"$HOME/.cache/mac-dock-pinned"
  fi
  [[ -e $HOME/.cache/nwg-dock-pinned ]] || cp -- "$HOME/.cache/mac-dock-pinned" "$HOME/.cache/nwg-dock-pinned"
}

# Apply the persisted favorite order to the Waybar fallback configuration.
sync_fallback_order() {
  [[ -r $DOCK_FAVORITES && -r $config_dir/config.jsonc ]] || return 0
  local modules='  "modules-center": [' app tmp
  while IFS= read -r app; do
    [[ -n $app && $app != \#* ]] && modules+="\"custom/$app\", "
  done <"$DOCK_FAVORITES"
  modules+='"custom/recent", "wlr/taskbar", "custom/trash", "custom/launcher"],'
  tmp=$(mktemp "$config_dir/config.XXXXXX")
  # shellcheck disable=SC2016
  awk -v replacement="$modules" 'index($0, "\"modules-center\":") {print replacement; next} {print}' "$config_dir/config.jsonc" >"$tmp"
  mv -- "$tmp" "$config_dir/config.jsonc"
}

# Stop the selected backend and its fallback pointer watcher.
stop_backend() {
  if [[ -r $DOCK_WATCHER_PID_FILE ]]; then
    kill "$(<"$DOCK_WATCHER_PID_FILE")" 2>/dev/null || true
    rm -f -- "$DOCK_WATCHER_PID_FILE"
  fi
  if [[ -r $DOCK_PID_FILE ]]; then
    kill "$(<"$DOCK_PID_FILE")" 2>/dev/null || true
    rm -f -- "$DOCK_PID_FILE"
  fi
  rm -f -- "$DOCK_BACKEND_FILE"
}

# Start the preferred native dock, then fall back to Waybar when unavailable.
start_backend() {
  running && exit 0
  sync_initial_pins
  sync_fallback_order
  local log pid native backend
  log="$log_dir/dock-$(date +%Y%m%d-%H%M%S).log"
  if native=$(native_binary); then
    "$native" --config "$config_dir/nwg-dock-config.toml" -d -i 48 --mb 10 --hide-timeout 400 --opacity 78 --launch-animation -s "$config_dir/nwg-style.css" -c "$config_dir/scripts/launch.sh menu" >>"$log" 2>&1 &
    pid=$!
    backend=rust
  elif command -v nwg-dock-hyprland >/dev/null 2>&1; then
    nwg-dock-hyprland -d -p bottom -a center -i 48 -mb 10 -l overlay -s "$config_dir/nwg-style.css" -c "$config_dir/scripts/launch.sh menu" >>"$log" 2>&1 &
    pid=$!
    backend=go
  elif command -v waybar >/dev/null 2>&1; then
    waybar -c "$config_dir/config.jsonc" -s "$config_dir/style.css" >>"$log" 2>&1 &
    pid=$!
    backend=waybar
  else
    notify 'HyprSequoia Dock' 'Install Waybar or nwg-dock to enable the dock.'
    return 1
  fi
  # Catch incompatible or immediately-crashing native binaries and fall back.
  sleep 0.5
  if ! kill -0 "$pid" 2>/dev/null; then
    printf '[HyprSequoia Dock] %s backend exited during startup; trying Waybar.\n' "$backend" >>"$log"
    if [[ $backend != waybar ]] && command -v waybar >/dev/null 2>&1; then
      waybar -c "$config_dir/config.jsonc" -s "$config_dir/style.css" >>"$log" 2>&1 &
      pid=$!
      backend=waybar
    else
      return 1
    fi
  fi
  if [[ $backend == waybar ]]; then
    "$config_dir/scripts/autohide.sh" "$pid" >>"$log" 2>&1 &
    printf '%s\n' "$!" >"$DOCK_WATCHER_PID_FILE"
  fi
  printf '%s\n' "$backend" >"$DOCK_BACKEND_FILE"
  printf '%s\n' "$pid" >"$DOCK_PID_FILE"
}

case ${1:-start} in
  start) start_backend;;
  stop) stop_backend;;
  restart) stop_backend; sleep 0.2; start_backend;;
  toggle)
    if running; then
      backend=$(current_backend)
      if [[ $backend == rust ]]; then pkill -RTMIN+1 -x nwg-dock
      elif [[ $backend == go ]]; then pkill -RTMIN+1 -x nwg-dock-hyprland
      else kill -SIGUSR1 "$(<"$DOCK_PID_FILE")"; fi
    else start_backend; fi;;
  show)
    if running; then
      backend=$(current_backend)
      if [[ $backend == rust ]]; then pkill -RTMIN+2 -x nwg-dock
      elif [[ $backend == go ]]; then pkill -RTMIN+2 -x nwg-dock-hyprland
      else kill -SIGUSR2 "$(<"$DOCK_PID_FILE")"; fi
    fi;;
  hide)
    if running; then
      backend=$(current_backend)
      if [[ $backend == rust ]]; then pkill -RTMIN+3 -x nwg-dock
      elif [[ $backend == go ]]; then pkill -RTMIN+3 -x nwg-dock-hyprland
      else kill -SIGUSR1 "$(<"$DOCK_PID_FILE")"; fi
    fi;;
  status) running && printf 'running pid=%s\n' "$(<"$DOCK_PID_FILE")" || printf 'stopped\n';;
  *) printf 'Usage: %s {start|stop|restart|toggle|show|hide|status}\n' "$0" >&2; exit 2;;
esac
