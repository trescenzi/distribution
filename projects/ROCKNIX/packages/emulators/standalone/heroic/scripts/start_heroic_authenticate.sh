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

WVKBD_PID=""
KB_WATCHER_PID=""
TOUCHKB_WAS_ACTIVE="0"

cleanup_keyboard_listener() {
  if [ -n "${KB_WATCHER_PID}" ]; then
    kill "${KB_WATCHER_PID}" 2>/dev/null || true
  fi
  if [ -n "${WVKBD_PID}" ]; then
    kill "${WVKBD_PID}" 2>/dev/null || true
  fi
  if [ "${TOUCHKB_WAS_ACTIVE}" = "1" ]; then
    systemctl start touchkeyboard.service >/dev/null 2>&1 || true
  fi
}

start_keyboard_toggle_listener() {
  command -v bash >/dev/null 2>&1 || return 0
  [ -n "${WVKBD_PID}" ] || return 0
  local listener=""
  for candidate in \
    "/usr/bin/heroic-keyboard-toggle.sh" \
    "/storage/.config/heroic-launchers/heroic-keyboard-toggle.sh"; do
    [ -x "${candidate}" ] || continue
    listener="${candidate}"
    break
  done
  [ -n "${listener}" ] || return 0
  bash "${listener}" "${WVKBD_PID}" >/dev/null 2>&1 &
  KB_WATCHER_PID=$!
}

trap 'cleanup_keyboard_listener' EXIT

cd "$(dirname "${HEROIC_BIN}")" || exit 1
if [ "${DEVICE_HAS_DUAL_SCREEN}" = "true" ]; then
  swaymsg 'seat seat1 fallback true'
fi
swaymsg for_window [app_id="heroic"] fullscreen enable
swaymsg for_window [class="heroic"] fullscreen enable

if systemctl is-active --quiet touchkeyboard.service; then
  TOUCHKB_WAS_ACTIVE="1"
  systemctl stop touchkeyboard.service >/dev/null 2>&1 || true
fi
killall wvkbd-mobintl >/dev/null 2>&1 || true
sleep 0.2
/usr/bin/wvkbd-mobintl -L 500 -fg 6b6b75 -fg-sp 6b6b75 -bg 1d1d1d --text ffffff --text-sp ffffff -press 000000 --press-sp 000000 -fn 48 -l simple --hidden >/dev/null 2>&1 &
WVKBD_PID=$!
sleep 0.25
kill -SIGUSR2 "${WVKBD_PID}" 2>/dev/null || true
if ! kill -0 "${WVKBD_PID}" 2>/dev/null; then
  sleep 0.1
  kill -SIGUSR2 "${WVKBD_PID}" 2>/dev/null || true
fi
start_keyboard_toggle_listener

export ELECTRON_OZONE_PLATFORM_HINT=wayland
HEROIC_ARGS=(--no-sandbox --ozone-platform=wayland)
"${HEROIC_BIN}" "${HEROIC_ARGS[@]}" &
HEROIC_PID=$!
wait "${HEROIC_PID}"
if [ "${DEVICE_HAS_DUAL_SCREEN}" = "true" ]; then
  swaymsg 'seat seat1 fallback false'
fi
