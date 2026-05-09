# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="gog"
PKG_VERSION="3.18"
PKG_LICENSE="DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE"
PKG_SITE="https://github.com/Sude-/lgogdownloader"
PKG_URL=""https://github.com/Sude-/lgogdownloader/archive/refs/tags/v${PKG_VERSION}.tar.gz
PKG_LONGDESC="Unofficial open source downloader for GOG.com, using the GOG Galaxy API."
PKG_TOOLCHAIN="cmake"
PKG_DEPENDS_TARGET="rhash tidy toolchain tinyxml2"


makeinstall_target() {
  cmake -B ${PKG_BUILD} -S .. -GNinja \
    -DCMAKE_INSTALL_PREFIX=${INSTALL}/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_QT_GUI=OFF  # Set to ON if you want Qt GUI

  ninja -C ${PKG_BUILD} install

  # If the binary is not installed to /usr/bin by default, manually copy it
  if [ ! -f "${INSTALL}/usr/bin/lgogdownloader" ]; then
    mkdir -p ${INSTALL}/usr/bin
    cp -f ${PKG_BUILD}/lgogdownloader ${INSTALL}/usr/bin/
    chmod 0755 ${INSTALL}/usr/bin/lgogdownloader
  fi

  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
}
