#!/bin/bash

## Running
#
# run_or_install_gog_game $gog_game_id $game_name
#
## Configuration
#
#  $CORE -- wine or umu
#  $GAMESCOPE -- If it shuold be run with Gamescope
#
#    wine:
#      - $DXVK (0|1 default 1)
#    umu:
#      - PROTON_PATH
##

. /etc/profile
INFO_FILE=$(find /roms/gog/games -name "goggame-${1}.info" -print -quit)
echo "[GOG]: Info file ${INFO_FILE}"
echo "[GOG]: $1 $2"
echo "[GOG]: gamescope: $GAMESCOPE | core: $CORE | dxvk: $DXVK | proton path: $PROTON_PATH"
if [[ -z "${INFO_FILE}" ]]; then
  echo "[GOG]: ${2} not installed"
  sway_fullscreen "qterminal" &
  qterminal -e "install_gog_game \"${2}/0\"; killall -9 qterminal"
  echo "[GOG]: DONE INSTALLING"
fi


# Usage
echo "Core: $core"
echo "Emulator: $emulator"
echo "Platform: $platform"

INFO_FILE=$(find /roms/gog/games -name "goggame-${1}.info" -print -quit)
echo "[GOG]: Info file ${INFO_FILE}"
if [[ -z "${INFO_FILE}" ]]; then
  echo "[GOG]: Install has failed"
  echo "[GOG]: No info file found"
  exit 1
fi

echo "[GOG]: running $2"
echo "[GOG]: using core: $CORE"

GAME_DIR=$(dirname "${INFO_FILE}")
EXECUTABLE=$(jq -r '.playTasks[0].path' $INFO_FILE)
set_kill set "-9 ${EXECUTABLE}"

mkdir -p "~/.wine_gog/${2}"
WINEPREFIX="~/.wine_gog/${2}"
WINEDEBUG=-all

echo "[GOG]: WINEPREFIX ${WINEPREFIX}"
echo "[GOG]: working dir: ${GAME_DIR}"
echo "[GOG]: executable: ${EXECUTABLE}"

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

FULL_PATH="${GAME_DIR}/${EXECUTABLE}"

swaymsg for_window [class="${EXECUTABLE}"] fullscreen enable
swaymsg for_window [app_id="${EXECUTABLE}"] fullscreen enable

if [ "\$CORE" = "umu" ]; then
  echo "[GOG]: running with umu"
  echo "[GOG]: proton path=${PROTON_PATH}"
  echo "[GOG]: Gamescope=${GAMESCOPE}"
  GAMEID="${1}" STORE="GOG" PROTON_PATH="GE_PROTON" WINEPREFIX="${WINEPREFIX}" ~/.local/umu-run  "${FULL_PATH}"
else
  echo "[GOG]: running with raw wine"

  if file "${FULL_PATH}" | grep -q "PE32" && ! file "${FULL_PATH}" | grep -q "PE32+"; then
    export WINEARCH=win32
    export WINEPREFIX=~/.wine32
    echo "[GOG]: WINE32 Detected"
  elif file "${FULL_PATH}" | grep -q "PE32+"; then
    echo "[GOG]: WINE64 Detected"
    export WINEPREFIX=~/.wine64
  else
    echo "[GOG]: Unknown file architecture"
  fi

  echo "[GOG]: DXVK=${DXVK}"
  echo "[GOG]: Gamescope=${GAMESCOPE}"
  # rocknix wget doesn't support https for now
  export WINETRICKS_DOWNLOADER="curl"

  if ! winetricks list-installed | grep -q "^dxvk$" && [ "${DXVK}" = "1" ]; then
      "[GOG]: Installing dxvk"
      winetricks dxvk
  fi

  wine "${FULL_PATH}"
  wineserver -k
fi
