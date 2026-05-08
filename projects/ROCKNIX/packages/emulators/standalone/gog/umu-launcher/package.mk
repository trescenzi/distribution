# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present [Your Org/Name]

PKG_NAME="umu-launcher"
PKG_VERSION="1.4.0"  # Update to latest release tag
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/Open-Wine-Components/umu-launcher"
PKG_URL="${PKG_SITE}/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain python3 python3-build python3-installer python3-hatchling cargo scdoc"
PKG_LONGDESC="UMU-Launcher: Standardized Wine/Proton wrapper for Linux gaming"
PKG_TOOLCHAIN="make"
PKG_PATCH_DIRS="patches"

pre_configure_target() {
  # Configure installation prefix for packaging
  ./configure.sh --prefix=${INSTALL}/usr
}

makeinstall_target() {
  # Build and install using DESTDIR (standard for package managers)
  make DESTDIR=${INSTALL} install
}
