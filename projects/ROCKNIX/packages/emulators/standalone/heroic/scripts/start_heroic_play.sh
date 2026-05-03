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

if [ "${DEVICE_HAS_DUAL_SCREEN}" = "true" ]; then
  swaymsg 'seat seat1 fallback true'
fi
swaymsg for_window [app_id="heroic"] fullscreen enable
swaymsg for_window [class="heroic"] fullscreen enable

export ELECTRON_OZONE_PLATFORM_HINT=wayland
HEROIC_ARGS=(--no-sandbox --ozone-platform=wayland)
[ "$#" -gt 0 ] && HEROIC_ARGS+=("$@")
cd "$(dirname "${HEROIC_BIN}")" || exit 1
"${HEROIC_BIN}" "${HEROIC_ARGS[@]}" &
HEROIC_PID=$!
wait "${HEROIC_PID}"
if [ "${DEVICE_HAS_DUAL_SCREEN}" = "true" ]; then
  swaymsg 'seat seat1 fallback false'
fi
