#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

source /etc/profile

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
heroic_seed_rom_launchers
echo ""
echo "Heroic installed successfully. You can now launch it from EmulationStation in the Heroic section."
sleep 10
