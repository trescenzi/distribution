#! /bin/bash

mkdir -p /roms/gog/games
mkdir -p /roms/gog/xml

GAME="."
if [[ -n "$1" ]]; then
  GAME="$1/0"
fi

echo "[GOG]: Installing $GAME"
CMD="lgogdownloader --platform win --galaxy-platform windows --directory /roms/gog/games --xml-directory /roms/gog/xml --galaxy-install $GAME"
echo "[GOG]: running $CMD"
eval $CMD
