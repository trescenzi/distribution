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

ROMS_DIR="/storage/roms/heroic"
LEGENDARY_INSTALLED="/storage/.config/heroic/legendaryConfig/legendary/installed.json"
GOG_INSTALLED="/storage/.config/heroic/gog_store/installed.json"
NILE_INSTALLED="/storage/.config/heroic/nile_config/installed.json"

mkdir -p "${ROMS_DIR}"

for launcher in "${ROMS_DIR}"/*.sh; do
  [ -f "${launcher}" ] || continue
  case "$(basename "${launcher}")" in
    "Configure Heroic.sh"|"Play Heroic.sh"|"Play Heroic (Gamescope).sh")
      ;;
    *)
      rm -f "${launcher}"
      ;;
  esac
done

sanitize_filename() {
  echo "$1" | sed 's#[/\\:*?"<>|]#_#g'
}

heroic_library_title_map_json() {
  local path="$1"
  [ -r "${path}" ] || {
    echo '{}'
    return 0
  }
  jq -c '
    (.games // [])
    | map(select(.app_name != null and (.app_name | tostring | length) > 0))
    | map({(.app_name | tostring): (.title // .name // "")})
    | add // {}
    | with_entries(select((.value | type == "string") and (.value | length) > 0))
  ' "${path}" 2>/dev/null || echo '{}'
}

create_launcher() {
  local title="$1"
  local uri="$2"
  local launcher_name
  local launcher_path

  launcher_name="$(sanitize_filename "${title}")"
  launcher_path="${ROMS_DIR}/${launcher_name}.sh"

  cat >"${launcher_path}" <<EOF
#!/bin/bash
HEROIC_LAUNCHER_NAME=start_heroic_play.sh
for HEROIC_LAUNCHER_DIR in /usr/bin /storage/.config/heroic-launchers; do
  H="\${HEROIC_LAUNCHER_DIR}/\${HEROIC_LAUNCHER_NAME}"
  [ -x "\$H" ] || continue
  exec "\$H" $(printf '%q' "${uri}")
done
echo "Heroic: start_heroic_play.sh not found." >&2
exit 127
EOF
  chmod 0755 "${launcher_path}"
}

create_gog_launcher() {
  local title="$1"
  local game_id="$2"
  local launcher_name
  local launcher_path

  launcher_name="$(sanitize_filename "${title}")"
  launcher_path="${ROMS_DIR}/${launcher_name}.sh"

  cat >"${launcher_path}" <<EOF
#!/bin/bash
HEROIC_LAUNCHER_NAME=start_heroic_gog.sh
for HEROIC_LAUNCHER_DIR in /usr/bin /storage/.config/heroic-launchers; do
  H="\${HEROIC_LAUNCHER_DIR}/\${HEROIC_LAUNCHER_NAME}"
  [ -x "\$H" ] || continue
  exec "\$H" $(printf '%q' "${game_id}")
done
echo "Heroic: start_heroic_gog.sh not found." >&2
exit 127
EOF
  chmod 0755 "${launcher_path}"
}

if [ -f "${LEGENDARY_INSTALLED}" ]; then
  jq -r '
    to_entries[] |
    select(.value.is_installed == true or .value.install_path != null) |
    [(.value.title // .key), ("heroic://launch/legendary/" + .key)] |
    @tsv
  ' "${LEGENDARY_INSTALLED}" | while IFS=$'\t' read -r title uri; do
    [ -n "${title}" ] || continue
    create_gog_launcher "${title}" "${uri}"
  done
fi

GOG_LIB_CACHE="/storage/.config/heroic/store_cache/gog_library.json"
GOG_TITLE_LOOKUP="$(heroic_library_title_map_json "${GOG_LIB_CACHE}")"

if [ -f "${GOG_INSTALLED}" ]; then
  jq -r --argjson lookup "${GOG_TITLE_LOOKUP}" '
    (
      if type == "array" then .[]
      elif type == "object" and (.installed | type == "array") then .installed[]
      else to_entries[] | .value | if type == "array" then .[] else . end
      end
    ) |
    . as $g |
    ($g.appName // $g.app_name // $g.id // $g.gameId // empty) as $id |
    select($id != null and $id != "") |
    [
      (
        if (($g.title // "") | length) > 0 then $g.title
        elif (($g.name // "") | length) > 0 then $g.name
        elif (($g.gameTitle // "") | length) > 0 then $g.gameTitle
        elif (($lookup[($id | tostring)] // "") | length) > 0 then $lookup[($id | tostring)]
        elif (($g.install_path // "") | length) > 0 then ($g.install_path | split("/") | map(select(length > 0)) | .[-1])
        else ($id | tostring)
        end
      ),
      ($id|tostring)
    ] |
    @tsv
  ' "${GOG_INSTALLED}" | while IFS=$'\t' read -r title game_id; do
    [ -n "${title}" ] || continue
    create_launcher "${title}" "${game_id}"
  done
fi

NILE_LIB_CACHE="/storage/.config/heroic/store_cache/nile_library.json"
NILE_TITLE_LOOKUP="$(heroic_library_title_map_json "${NILE_LIB_CACHE}")"

if [ -f "${NILE_INSTALLED}" ]; then
  jq -r --argjson lookup "${NILE_TITLE_LOOKUP}" '
    (
      if type == "array" then .[]
      elif type == "object" and (.installed | type == "array") then .installed[]
      else to_entries[] | .value | if type == "array" then .[] else . end
      end
    ) |
    . as $g |
    ($g.app_name // $g.appName // $g.id // empty) as $id |
    select($id != null and $id != "") |
    [
      (
        if (($g.title // "") | length) > 0 then $g.title
        elif (($g.name // "") | length) > 0 then $g.name
        elif (($lookup[($id | tostring)] // "") | length) > 0 then $lookup[($id | tostring)]
        elif (($g.install_path // "") | length) > 0 then ($g.install_path | split("/") | map(select(length > 0)) | .[-1])
        else ($id | tostring)
        end
      ),
      ("heroic://launch/nile/" + ($id|tostring))
    ] |
    @tsv
  ' "${NILE_INSTALLED}" | while IFS=$'\t' read -r title uri; do
    [ -n "${title}" ] || continue
    create_launcher "${title}" "${uri}"
  done
fi

heroic_seed_rom_launchers

echo "Heroic scan complete: $(ls -1 "${ROMS_DIR}"/*.sh 2>/dev/null | wc -l) launchers in ${ROMS_DIR}"
