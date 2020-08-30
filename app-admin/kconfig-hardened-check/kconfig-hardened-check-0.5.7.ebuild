# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{5..7} )

inherit python-r1 git-r3

DESCRIPTION="A script to check the hardening options in the Linux kernel config"
HOMEPAGE="https://github.com/a13xp0p0v/kconfig-hardened-check"

LICENSE="GPL-3"
KEYWORDS="*"

SLOT="0"

SRC_URI="https://github.com/a13xp0p0v/kconfig-hardened-check/archive/v${PV}.tar.gz"

IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}"
DEPEND="${RDEPEND}"

src_install() {
	default
	dobin kconfig-hardened-check.py
}

