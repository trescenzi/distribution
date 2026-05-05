# SPDX-License-Identifier: MIT
# Copyright (C) 2025-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="tidy"
PKG_VERSION="5.8.0"  # Update to the latest version from https://github.com/htacg/tidy-html5/releases
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/htacg/tidy-html5"
PKG_URL="${PKG_SITE}/archive/refs/tags/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="HTML Tidy Library - a HTML syntax checker and reformatter"
PKG_TOOLCHAIN="cmake"

PKG_DEPENDS_TARGET="toolchain"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=ON \
                       -DBUILD_STATIC_LIBS=OFF \
											 -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
											 # only build libs and dont't build man pages
											 -DSUPPORT_CONSOLE_APP=0 \
                       -DCMAKE_INSTALL_PREFIX=/usr"
