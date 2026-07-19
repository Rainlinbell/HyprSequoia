#!/usr/bin/env bash
# Reorder fallback favorites and synchronize the native dock pin file.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
init_state
[[ -r $DOCK_FAVORITES ]] || exit 0
selected=$(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' "$DOCK_FAVORITES" | walker --dmenu -p 'Choose app to reorder' 2>/dev/null || true)
[[ -n $selected ]] || exit 0
action=$(printf '%s\n' 'Move Up' 'Move Down' 'Remove from Favorites' | walker --dmenu -p "$selected" 2>/dev/null || true)
mapfile -t apps < <(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' "$DOCK_FAVORITES")
index=-1
for i in "${!apps[@]}"; do [[ ${apps[$i]} == "$selected" ]] && index=$i; done
((index >= 0)) || exit 0
case $action in
  'Move Up')
    if ((index > 0)); then tmp=${apps[index - 1]}; apps[index - 1]=${apps[index]}; apps[index]=$tmp; fi;;
  'Move Down')
    if ((index < ${#apps[@]} - 1)); then tmp=${apps[index + 1]}; apps[index + 1]=${apps[index]}; apps[index]=$tmp; fi;;
  'Remove from Favorites') unset 'apps[index]';;
  *) exit 0;;
esac
printf '%s\n' "${apps[@]}" >"$DOCK_FAVORITES"
mkdir -p "${DOCK_RUST_PIN_FILE%/*}" "${DOCK_GO_PIN_FILE%/*}"
printf '%s\n' "${apps[@]}" | normalize_dock_pins >"$DOCK_RUST_PIN_FILE"
cp -- "$DOCK_RUST_PIN_FILE" "$DOCK_GO_PIN_FILE"
# Regenerate the fallback module order while leaving definitions untouched.
modules='  "modules-center": ['
for app in "${apps[@]}"; do modules+="\"custom/$app\", "; done
modules+='"custom/recent", "wlr/taskbar", "custom/trash", "custom/launcher"],'
tmp=$(mktemp "$DOCK_CONFIG_DIR/config.XXXXXX")
# shellcheck disable=SC2016
awk -v replacement="$modules" 'index($0, "\"modules-center\":") {print replacement; next} {print}' "$DOCK_CONFIG_DIR/config.jsonc" >"$tmp"
mv -- "$tmp" "$DOCK_CONFIG_DIR/config.jsonc"
"$DOCK_CONFIG_DIR/scripts/dock.sh" restart
