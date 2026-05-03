#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

source /etc/profile
set_kill set "-9 heroic Heroic"

_heroic_common_loaded=0
for _hcf in /usr/share/heroic/heroic_common.sh /storage/.config/heroic-launchers/heroic_common.sh; do
  [ -r "${_hcf}" ] || continue
  # shellcheck source=/dev/null
  . "${_hcf}"
  _heroic_common_loaded=1
  break
done
if [ "${_heroic_common_loaded}" != "1" ]; then
  echo "Heroic: heroic_common.sh not found (/usr/share/heroic or /storage/.config/heroic-launchers)." >&2
  exit 1
fi
heroic_ensure_installed || exit 1

quit_and_notify() {
  command -v mako-notify >/dev/null 2>&1 && mako-notify "$1" -no-es
  if [ "${DEVICE_HAS_DUAL_SCREEN}" = "true" ]; then
    swaymsg 'seat seat1 fallback false'
  fi
  exit 0
}

if [ "${DEVICE_HAS_DUAL_SCREEN}" = "true" ]; then
  swaymsg 'seat seat1 fallback true'
fi
swaymsg for_window [app_id="heroic"] fullscreen enable
swaymsg for_window [class="heroic"] fullscreen enable

export ELECTRON_OZONE_PLATFORM_HINT=wayland
cd "$(dirname "${HEROIC_BIN}")" || exit 1

WIDTH=""
HEIGHT=""
eval "$(swaymsg -t get_outputs | jq -r '
  .[] | select(.focused == true) |
  "W=\(.current_mode.width) H=\(.current_mode.height) TRANSFORM=\(.transform)"
')"
if [[ "${TRANSFORM:-}" == "90" || "${TRANSFORM:-}" == "270" || "${TRANSFORM:-}" == "flipped-90" || "${TRANSFORM:-}" == "flipped-270" ]]; then
  WIDTH=$H
  HEIGHT=$W
else
  WIDTH=$W
  HEIGHT=$H
fi

if ! command -v gamescope >/dev/null 2>&1; then
  quit_and_notify "Heroic: gamescope not installed."
fi

if [ -z "${WIDTH:-}" ]; then
  quit_and_notify "Heroic: display size not found."
fi

gamescope -f -W "${WIDTH}" -H "${HEIGHT}" -- "${HEROIC_BIN}" --no-sandbox "$@" &
HEROIC_PID=$!
wait "${HEROIC_PID}"
if [ "${DEVICE_HAS_DUAL_SCREEN}" = "true" ]; then
  swaymsg 'seat seat1 fallback false'
fi
