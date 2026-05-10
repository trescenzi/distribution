#! /bin/bash

echo "[GOG]: loading game info"
mkdir -p /roms/gog
if [[ -z /roms/gog/gog_games.json ]]; then
  echo "[GOG]: loading game list"
  lgogdownloader --list json > /roms/gog/gog_games.json
fi

jq -r '.[] | [.title, .product_id, .gamename] | @tsv' /roms/gog/gog_games.json | while IFS=$'\t' read -r title id name; do
    cat > "/roms/gog/${title}.sh" <<EOF
#!/bin/bash

. /etc/profile
info_file=\$(find /roms/gog/games -name "goggame-${id}.info" -print -quit)
echo "[GOG]: Info file \$info_file"
if [[ -z "\$info_file" ]]; then
  echo "[GOG]: ${title} not installed"
  echo "[GOG]: installing this might take time"
  install_gog_game "${name}/0"
  echo "[GOG]: DONE INSTALLING"
fi

info_file=\$(find /roms/gog/games -name "goggame-${id}.info" -print -quit)
echo "[GOG]: Info file \$info_file"
if [[ -z "\$info_file" ]]; then
  echo "[GOG]: Install has failed"
  echo "[GOG]: No info file found"
  exit 1
fi

echo "[GOG]: running ${title}"
echo "[GOG]: using core: \$CORE"

game_dir=\$(dirname "\$info_file")
executable=\$(jq -r '.playTasks[0].path' "\$info_file")
set_kill set "-9 \$executable"

mkdir -p "~/.wine_gog/${name}"
WINEPREFIX="~/.wine_gog/${name}"
WINEDEBUG=-all

echo "[GOG]: WINEPREFIX \$WINEPREFIX"
echo "[GOG]: working dir: \$game_dir"
echo "[GOG]: executable: \$executable"

FULL_PATH="\$game_dir/\$executable"

swaymsg for_window [class="\$executable"] fullscreen enable

if [ "\$CORE" = "umu" ]; then
  echo "[GOG]: running with umu"
  echo "[GOG]: proton path= \$PROTON_PATH"
  echo "[GOG]: Gamescope = \$GAMESCOPE"
  GAMEID="$id" STORE="GOG" PROTON_PATH=GE_PROTON WINEPREFIX="\$WINEPREFIX" ~/.local/umu-run  "\$FULL_PATH" &
else
  echo "[GOG]: running with raw wine"
  echo "[GOG]: DXVK = \$DXVK"
  echo "[GOG]: Gamescope = \$GAMESCOPE"
  export WINETRICKS_DOWNLOADER="curl"

  if ! winetricks list-installed | grep -q "^dxvk$" && [ "\$DXVK" = "1" ]; then
      "[GOG]: Installing dxvk"
      winetricks dxvk
  fi

  wine "\$FULL_PATH" &
fi

PID=$!
wait PID
EOF
    chmod +x "/roms/gog/${title}.sh"
done
