# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)
#
# Sourced by start_heroic_*.sh and Tools install/scan.
# Image: /usr/share/heroic/heroic_common.sh; modules: scripts/heroic_common.inc;
# upload-to-device.sh can mirror scripts under /storage/.config/heroic-launchers/.

HEROIC_BASE="/storage/.local/share/heroic-arm64"
HEROIC_LAUNCHER_DIRS="/usr/bin /storage/.config/heroic-launchers"
HEROIC_TAR_URL="https://codeberg.org/trescenzi/rocknix-ports/raw/branch/main/heroic/Heroic-2.21.0-linux-arm64.tar.xz"
HEROIC_BIN=""

resolve_heroic_bin() {
  HEROIC_BIN=""
  for candidate in "${HEROIC_BASE}"/Heroic*/heroic "${HEROIC_BASE}"/heroic; do
    [ -x "${candidate}" ] || continue
    HEROIC_BIN="${candidate}"
    return 0
  done
  return 1
}

heroic_write_es_stub() {
  local dest="$1"
  local launcher_name="$2"
  cat >"${dest}" <<EOF
#!/bin/bash
HEROIC_LAUNCHER_NAME="${launcher_name}"
for HEROIC_LAUNCHER_DIR in ${HEROIC_LAUNCHER_DIRS}; do
  H="\${HEROIC_LAUNCHER_DIR}/\${HEROIC_LAUNCHER_NAME}"
  [ -x "\$H" ] || continue
  exec "\$H" "\$@"
done
echo "Heroic: \${HEROIC_LAUNCHER_NAME} not found under ${HEROIC_LAUNCHER_DIRS// / or }. Install the heroic package or run upload-to-device.sh." >&2
exit 127
EOF
  chmod 0755 "${dest}"
}

# ES hides the Heroic system when /storage/roms/heroic has no .sh entries.
heroic_seed_rom_launchers() {
  local seed="/usr/config/heroic"
  local roms="/storage/roms/heroic"
  mkdir -p "${roms}"

  rm -f \
    "${roms}/000 Heroic (Configure).sh" \
    "${roms}/000 Heroic (Play).sh" \
    "${roms}/000 Heroic (Gamescope).sh"

  if [ -d "${seed}" ]; then
    local f
    shopt -s nullglob
    for f in "${seed}"/*.sh; do
      cp -f "${f}" "${roms}/"
    done
    shopt -u nullglob
  fi

  heroic_write_es_stub "${roms}/Configure Heroic.sh" "start_heroic_authenticate.sh"
  heroic_write_es_stub "${roms}/Play Heroic.sh" "start_heroic_play.sh"
  heroic_write_es_stub "${roms}/Play Heroic (Gamescope).sh" "start_heroic_play_gamescope.sh"
}

heroic_ensure_installed() {
  if resolve_heroic_bin; then
    return 0
  fi
  local LOCK_DIR="/tmp/heroic-arm64.lock"
  if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
    echo "Heroic install in progress, please retry in a few seconds."
    return 1
  fi
  trap 'rmdir "${LOCK_DIR}" 2>/dev/null || true' RETURN
  mkdir -p "${HEROIC_BASE}"
  local TMP_ARCHIVE="/tmp/heroic-arm64.tar.xz"
  wget -c -t 5 -O "${TMP_ARCHIVE}" "${HEROIC_TAR_URL}" || return 1
  rm -rf "${HEROIC_BASE}/Heroic-Games-Launcher"
  tar -xJf "${TMP_ARCHIVE}" -C "${HEROIC_BASE}" || return 1
  rm -f "${TMP_ARCHIVE}"
  resolve_heroic_bin || return 1
  chmod +x "${HEROIC_BIN}" || true
  return 0
}
