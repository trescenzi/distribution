mkdir -p /roms/gog/games
mkdir -p /roms/gog/xml

echo $0

lgogdownloader --directory /roms/gog/games --xml-directory /roms/gog/xml --save-logo --save-icon --save-product-json --save-game-details-json --galaxy-install
