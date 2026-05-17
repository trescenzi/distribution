#! /bin/bash

echo "[GOG]: loading game info"
mkdir -p /roms/gog
if [[ ! -f /roms/gog/gog_games.json ]]; then
  echo "[GOG]: loading game list"
  echo "[GOG]: this can be slow"
  lgogdownloader --list json > /roms/gog/gog_games.json
  echo "[GOG]: done loading game list"
fi

jq -r '.[] | [.title, .product_id, .gamename] | @tsv' /roms/gog/gog_games.json | while IFS=$'\t' read -r title id name; do
    cat > "/roms/gog/${title}.sh" <<EOF
#!/bin/bash
CORE=""
EMULATOR=""
PLATFORM=""

# Parse all arguments
while [[ "\$#" -gt 0 ]]; do
    case \$1 in
        --core=*) CORE="\${1#*=}" ;;
        --core)   CORE="\$2"; shift ;;
        --emulator=*) EMULATOr="\${1#*=}" ;;
        --emulator) EMULATOR="\$2"; shift ;;
        -P) PLATFORM="\$2"; shift ;;
        -P*) PLATFORM="\${1#-P}" ;;
        *) ;;
    esac
    shift
done


CORE="\${CORE}" run_or_install_gog_game ${id} ${name}
EOF
    chmod +x "/roms/gog/${title}.sh"
done

