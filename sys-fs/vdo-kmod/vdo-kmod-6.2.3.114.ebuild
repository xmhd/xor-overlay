# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic linux-mod toolchain-funcs

DESCRIPTION="Virtual Data Optimizer (VDO) is a device mapper target that delivers block-level deduplication, compression and thin provisioning."
HOMEPAGE="https://github.com/dm-vdo/kvdo"

LICENSE="GPL-2"
KEYWORDS="amd64"

SRC_URI="https://github.com/dm-vdo/kvdo/archive/${PV}.tar.gz"

SLOT="0"

IUSE="custom-cflags"

S="${WORKDIR}/vdo-${PV}"

pkg_setup() {
    linux-mod_pkg_setup
}

src_unpack() {
    default
}

src_prepare() {
    default
}

src_configure() {

    if ! use custom-cflags; then
        strip-flags
    fi

    filter-ldflags -Wl,*
}

src_compile() {

    myemakeargs=(
        V=1
    )

    emake "${myemakeargs[@]}"
}

src_install() {
	linux-mod_src_install

    myemakeargs+=(
        DEPMOD="/bin/true"
        DESTDIR="${D}"
        INSTALL_MOD_PATH="${INSTALL_MOD_PATH:-$EROOT}"
    )

    emake "${myemakeargs[@]}" install

    einstalldocs
}

pkg_postinst() {
    linux-mod_pkg_postinst
}
