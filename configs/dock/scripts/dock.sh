#!/usr/bin/env bash
# Start, stop, and control the native or Waybar fallback dock backend.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
config_dir=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprsequoia/logs"
mkdir -p "$log_dir" "$DOCK_RUNTIME_DIR"

running() {
  [[ -r $DOCK_PID_FILE ]] || return 1
  local pid found=0 healthy=1
  while IFS= read -r pid; do
    [[ $pid =~ ^[0-9]+$ ]] || continue
    found=1
    kill -0 "$pid" 2>/dev/null || healthy=0
  done <"$DOCK_PID_FILE"
  ((found && healthy))
}

signal_pids() {
  local signal=$1 pid
  [[ -r $DOCK_PID_FILE ]] || return 1
  while IFS= read -r pid; do
    [[ $pid =~ ^[0-9]+$ ]] || continue
    kill "-$signal" "$pid" 2>/dev/null || true
  done <"$DOCK_PID_FILE"
}

current_backend() {
  local backend
  if [[ -r $DOCK_BACKEND_FILE ]]; then
    IFS= read -r backend <"$DOCK_BACKEND_FILE" || true
    printf '%s\n' "${backend:-waybar}"
  else
    printf '%s\n' waybar
  fi
}

# The Go backend resolves -s below its own XDG configuration directory. Stage
# the selected project palette there so custom XDG_CONFIG_HOME values work too.
stage_go_style() {
  local style_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nwg-dock-hyprland"
  install -Dm644 "$config_dir/nwg-style.css" "$style_dir/hyprsequoia.css"
  printf '%s\n' hyprsequoia.css
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
  local pin_file pin_dir tmp
  mkdir -p "${DOCK_RUST_PIN_FILE%/*}" "${DOCK_GO_PIN_FILE%/*}"
  if [[ ! -e $DOCK_RUST_PIN_FILE ]]; then
    normalize_dock_pins <"$DOCK_FAVORITES" >"$DOCK_RUST_PIN_FILE"
  fi
  [[ -e $DOCK_GO_PIN_FILE ]] || cp -- "$DOCK_RUST_PIN_FILE" "$DOCK_GO_PIN_FILE"
  # Migrate historical aliases to a real installed client ID when possible,
  # or to a fallback-aware project proxy on minimal installations.
  for pin_file in "$DOCK_RUST_PIN_FILE" "$DOCK_GO_PIN_FILE"; do
    [[ -f $pin_file ]] || continue
    pin_dir=${pin_file%/*}
    tmp=$(mktemp "$pin_dir/hyprsequoia-pins.XXXXXX")
    normalize_dock_pins <"$pin_file" >"$tmp"
    mv -- "$tmp" "$pin_file"
  done
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

# Stop the selected backend and clean a watcher left by pre-resident releases.
stop_backend() {
  local pid
  if [[ -r $DOCK_WATCHER_PID_FILE ]]; then
    kill "$(<"$DOCK_WATCHER_PID_FILE")" 2>/dev/null || true
    rm -f -- "$DOCK_WATCHER_PID_FILE"
  fi
  if [[ -r $DOCK_PID_FILE ]]; then
    while IFS= read -r pid; do
      [[ $pid =~ ^[0-9]+$ ]] || continue
      kill "$pid" 2>/dev/null || true
    done <"$DOCK_PID_FILE"
    rm -f -- "$DOCK_PID_FILE"
  fi
  rm -f -- "$DOCK_BACKEND_FILE"
}

# Start the preferred native dock in resident mode, then fall back to Waybar.
start_backend() {
  running && exit 0
  # A partially alive multi-monitor backend must be replaced as one unit.
  stop_backend
  sync_initial_pins
  sync_fallback_order
  local log pid native backend go_style output startup_failed=0
  local -a pids=() outputs=() args=()
  log="$log_dir/dock-$(date +%Y%m%d-%H%M%S).log"
  if native=$(native_binary); then
    "$native" --config "$config_dir/nwg-dock-config.toml" -r -i 50 --mb 10 --opacity 72 --launch-animation -s "$config_dir/nwg-style.css" -c "$config_dir/scripts/launch.sh menu" >>"$log" 2>&1 &
    pids+=("$!")
    backend=rust
  elif command -v nwg-dock-hyprland >/dev/null 2>&1; then
    go_style=$(stage_go_style)
    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
      mapfile -t outputs < <(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.disabled != true) | .name' 2>/dev/null)
    fi
    ((${#outputs[@]})) || outputs=('')
    for output in "${outputs[@]}"; do
      args=(-r -x -p bottom -a center -i 50 -mb 10 -s "$go_style" -c "$config_dir/scripts/launch.sh menu")
      # Upstream creates one resident surface on the focused monitor. Select
      # every active output explicitly and allow one process per output.
      [[ -n $output ]] && args+=(-m -o "$output")
      nwg-dock-hyprland "${args[@]}" >>"$log" 2>&1 &
      pids+=("$!")
    done
    backend=go
  elif command -v waybar >/dev/null 2>&1; then
    waybar -c "$config_dir/config.jsonc" -s "$config_dir/style.css" >>"$log" 2>&1 &
    pids+=("$!")
    backend=waybar
  else
    notify 'HyprSequoia Dock' 'Install Waybar or nwg-dock to enable the dock.'
    return 1
  fi
  # Catch incompatible or immediately-crashing native binaries and fall back.
  sleep 0.5
  for pid in "${pids[@]}"; do
    kill -0 "$pid" 2>/dev/null || startup_failed=1
  done
  if ((startup_failed)); then
    printf '[HyprSequoia Dock] %s backend exited during startup; trying Waybar.\n' "$backend" >>"$log"
    for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
    pids=()
    if [[ $backend != waybar ]] && command -v waybar >/dev/null 2>&1; then
      waybar -c "$config_dir/config.jsonc" -s "$config_dir/style.css" >>"$log" 2>&1 &
      pids+=("$!")
      backend=waybar
    else
      return 1
    fi
  fi
  # Every backend is resident by design. This keeps the Dock predictable and
  # clickable on touchpads, virtual machines, and nested Wayland sessions.
  printf '%s\n' "$backend" >"$DOCK_BACKEND_FILE"
  printf '%s\n' "${pids[@]}" >"$DOCK_PID_FILE"
}

case ${1:-start} in
  start) start_backend;;
  stop) stop_backend;;
  restart) stop_backend; sleep 0.2; start_backend;;
  toggle)
    if running; then
      backend=$(current_backend)
      if [[ $backend == rust || $backend == go ]]; then signal_pids RTMIN+1
      else signal_pids SIGUSR1; fi
    else start_backend; fi;;
  show)
    if running; then
      backend=$(current_backend)
      if [[ $backend == rust || $backend == go ]]; then signal_pids RTMIN+2
      else signal_pids SIGUSR2; fi
    fi;;
  hide)
    if running; then
      backend=$(current_backend)
      if [[ $backend == rust || $backend == go ]]; then signal_pids RTMIN+3
      else signal_pids SIGUSR1; fi
    fi;;
  status)
    if running; then
      printf 'running backend=%s pids=' "$(current_backend)"
      paste -sd, "$DOCK_PID_FILE"
    else
      printf 'stopped\n'
    fi;;
  *) printf 'Usage: %s {start|stop|restart|toggle|show|hide|status}\n' "$0" >&2; exit 2;;
esac
