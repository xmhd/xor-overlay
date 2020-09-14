# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Userspace tools for managing block-level storage compression and deduplication."
HOMEPAGE="https://github.com/dm-vdo/vdo"

LICENSE="GPL-2"
KEYWORDS="amd64"

SRC_URI="https://github.com/dm-vdo/${PN}/archive/${PV}.tar.gz"

SLOT="0"

IUSE=""

DEPEND="
    sys-fs/lvm2
    dev-python/pyyaml
    sys-fs/vdo-kmod
"

src_unpack() {
    default
}