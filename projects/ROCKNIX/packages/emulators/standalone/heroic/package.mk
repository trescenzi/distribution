# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="heroic"
PKG_LICENSE="GPLv2"
PKG_SITE="https://heroicgameslauncher.com"
PKG_LONGDESC="Heroic Games Launcher scripts for ROCKNIX"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  mkdir -p ${INSTALL}/usr/share/heroic
  mkdir -p ${INSTALL}/usr/config/heroic
  cp -f ${PKG_DIR}/scripts/heroic_common.sh ${INSTALL}/usr/share/heroic/
  chmod 0644 ${INSTALL}/usr/share/heroic/heroic_common.sh
  for hscript in ${PKG_DIR}/scripts/*.sh; do
    [ "$(basename "${hscript}")" != "heroic_common.sh" ] || continue
    cp -f "${hscript}" ${INSTALL}/usr/bin/
  done
  chmod 0755 ${INSTALL}/usr/bin/*.sh
}
