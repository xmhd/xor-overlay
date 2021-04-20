# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic

DESCRIPTION="A selection of tools from Debian"
HOMEPAGE="https://packages.qa.debian.org/d/debianutils.html"
LICENSE="BSD GPL-2 SMAIL"

SLOT="0"

IUSE="+installkernel static"

if [[ ${PV} != 9999 ]]; then
	SRC_URI="mirror://debian/pool/main/d/${PN}/${PN}_${PV}.tar.xz"
	KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k mips ppc ppc64 riscv s390 sparc x86"
fi

DEPEND="
	installkernel? (
		!sys-kernel/installkernel-gentoo
		!sys-kernel/installkernel-systemd-boot
	)
"

PATCHES=(
	"${FILESDIR}"/${PN}-3.4.2-no-bs-namespace.patch
)

src_unpack() {
        unpack ${PN}_${PV}.tar.xz
        mv ${PN} ${PN}-${PV}
}

src_configure() {
	use static && append-ldflags -static
	default
}

src_install() {
	into /
	dobin tempfile run-parts

	if use installkernel ; then
		dosbin installkernel
	fi

	into /usr
        dobin ischroot
	dosbin savelog

	doman ischroot.1 tempfile.1 run-parts.8 savelog.8
	use installkernel && doman installkernel.8
	cd debian || die
	dodoc changelog control
	keepdir /etc/kernel/postinst.d
}
