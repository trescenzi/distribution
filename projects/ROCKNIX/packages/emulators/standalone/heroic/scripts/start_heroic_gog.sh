#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

source /etc/profile
set_kill set "-9 heroic Heroic"

# Check if app ID is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <APP_ID>"
    exit 1
fi

APP_ID="$1"
CONFIG_FILE="$HOME/.config/heroic/GamesConfig/${APP_ID}.json"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found: $CONFIG_FILE"
    exit 1
fi

# Read the config file
APP_CONFIG=$(jq -r ".[\"$APP_ID\"]" "$CONFIG_FILE")

# Extract relevant fields
WINE_PREFIX=$(echo "$APP_CONFIG" | jq -r '.winePrefix')
WINE_BIN=$(echo "$APP_CONFIG" | jq -r '.wineVersion.bin')
ENABLE_ESYNC=$(echo "$APP_CONFIG" | jq -r '.enableEsync')
ENABLE_FSYNC=$(echo "$APP_CONFIG" | jq -r '.enableFsync')
ENABLE_DXVK_NVAPI=$(echo "$APP_CONFIG" | jq -r '.autoInstallDxvkNvapi')
BATTLEYE_RUNTIME=$(echo "$APP_CONFIG" | jq -r '.battlEyeRuntime')
EAC_RUNTIME=$(echo "$APP_CONFIG" | jq -r '.eacRuntime')

# Construct the command
CMD="HEROIC_APP_NAME=$APP_ID \
HEROIC_APP_RUNNER=gog \
GAMEID=umu-0 \
HEROIC_APP_SOURCE=gog \
STORE=gog \
STEAM_COMPAT_INSTALL_PATH=\"/storage/Games/Heroic/Hollow Knight Silksong\" \
LD_PRELOAD= \
WINEPREFIX=\"$WINE_PREFIX\" \
WINEDLLOVERRIDES=winemenubuilder.exe=d \
WINE_FULLSCREEN_FSR=0"

# Add esync/fsync if enabled
if [ "$ENABLE_ESYNC" = "true" ]; then
  CMD="$CMD WINEESYNC=1"
fi
if [ "$ENABLE_FSYNC" = "true" ]; then
  CMD="$CMD WINEFSYNC=1"
fi
if [ "$ENABLE_DXVK_NVAPI" = "true" ]; then
  CMD="$CMD DXVK_ENABLE_NVAPI=1 DXVK_NVAPI_ALLOW_OTHER_DRIVERS=1"
fi

# Add BattlEye and EAC runtime paths if enabled
if [ "$BATTLEYE_RUNTIME" = "true" ]; then
  CMD="$CMD PROTON_BATTLEYE_RUNTIME=/storage/.config/heroic/tools/runtimes/battleye_runtime"
fi
if [ "$EAC_RUNTIME" = "true" ]; then
  CMD="$CMD PROTON_EAC_RUNTIME=/storage/.config/heroic/tools/runtimes/eac_runtime"
fi

CMD="$CMD ORIG_LD_LIBRARY_PATH= GOGDL_CONFIG_PATH=/storage/.config/heroic/gogdlConfig"

# Final command
CMD="$CMD /storage/.local/share/heroic-arm64/Heroic-2.21.0-linux-arm64/resources/app.asar.unpacked/build/bin/arm64/linux/gogdl --auth-config-path /storage/.config/heroic/gog_store/auth.json launch \"/storage/Games/Heroic/Hollow Knight Silksong\" $APP_ID --wine $WINE_BIN --platform windows"

eval $CMD
