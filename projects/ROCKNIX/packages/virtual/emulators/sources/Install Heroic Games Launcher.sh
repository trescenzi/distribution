#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

source /etc/profile

heroic_source_common() {
  local mod
  mod="$(cd "$(dirname "$0")" && pwd)"
  if [ -r "${mod}/scripts/heroic_common.inc" ]; then
    # shellcheck source=/dev/null
    . "${mod}/scripts/heroic_common.inc"
    return 0
  fi
  if [ -r /usr/share/heroic/heroic_common.sh ]; then
    # shellcheck source=/dev/null
    . /usr/share/heroic/heroic_common.sh
    return 0
  fi
  echo "Heroic support files missing (heroic_common). Reflash or update ROCKNIX."
  sleep 10
  return 1
}

heroic_source_common || exit 1
heroic_ensure_installed || exit 1
heroic_seed_rom_launchers
echo ""
echo "Heroic installed successfully. You can now launch it from EmulationStation in the Heroic section."
sleep 10
