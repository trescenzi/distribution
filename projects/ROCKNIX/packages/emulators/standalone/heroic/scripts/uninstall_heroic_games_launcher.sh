#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

source /etc/profile

HEROIC_BASE="${HEROIC_BASE:-/storage/.local/share/heroic-arm64}"
APPLICATIONS="${APPLICATIONS:-/storage/.local/share/applications}"
ROMS_DIR="${ROMS_DIR:-/storage/roms/heroic}"

rm -rf "${HEROIC_BASE}"
rm -f "${APPLICATIONS}/Heroic.desktop"

if [ -d "${ROMS_DIR}" ]; then
  rm -f "${ROMS_DIR}/Configure Heroic.sh" \
    "${ROMS_DIR}/Play Heroic.sh" \
    "${ROMS_DIR}/Play Heroic (Gamescope).sh" \
    "${ROMS_DIR}/000 Heroic (Configure).sh" \
    "${ROMS_DIR}/000 Heroic (Play).sh" \
    "${ROMS_DIR}/000 Heroic (Gamescope).sh"
fi

echo ""
echo "Heroic launcher removed. Install files under ${HEROIC_BASE} were deleted."
echo "Config under /storage/.config/heroic (accounts and library metadata) and per-game scripts in ${ROMS_DIR} were kept."
sleep 5
