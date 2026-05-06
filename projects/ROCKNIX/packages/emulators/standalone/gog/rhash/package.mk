# SPDX-License-Identifier: MIT
# Copyright (C) 2025-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="rhash"
PKG_VERSION="1.4.6"  # Check for the latest version at https://github.com/rhash/RHash/releases
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/rhash/RHash"
PKG_URL="${PKG_SITE}/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_LONGDESC="RHash is a utility for computing and verifying hash sums of files."
PKG_TOOLCHAIN="manual"
PKG_DEPENDS_TARGET="toolchain"

makeinstall_target() {
  cd ${PKG_BUILD}
  ./configure --prefix=/usr \
              --sysconfdir=/etc \
              --exec-prefix=/usr

  make
  make DESTDIR=${SYSROOT_PREFIX} install  # Install directly to the sysroot
  make DESTDIR=${INSTALL} install  # Install directly to the sysroot

  # Create the unversioned symlink in the sysroot
  mkdir -p ${SYSROOT_PREFIX}/usr/lib
  ln -sf librhash.so.1 ${SYSROOT_PREFIX}/usr/lib/librhash.so
}
