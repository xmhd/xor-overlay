# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit distutils-r1

DESCRIPTION="Funtoo's franken-chroot tool."
HOMEPAGE="https://pypi.org/project/fchroot/"
SRC_URI="https://files.pythonhosted.org/packages/f2/04/4db5e98e93207dbb9bb71725767a8d016f9aa1e70c9c7892a5c270c3eac6/fchroot-0.1.2.tar.gz -> fchroot-0.1.2.tar.gz"

LICENSE="Apache-2.0"
KEYWORDS="~amd64"

SLOT="0"

IUSE=""

# TODO: make qemu targets configurable via USE
RDEPEND="
	app-emulation/qemu[static-user,qemu_user_targets_aarch64,qemu_user_targets_arm]
	sys-apps/attr[static-libs]
	dev-libs/glib[static-libs]
	sys-libs/zlib[static-libs]
	dev-libs/libpcre[static-libs]
"
