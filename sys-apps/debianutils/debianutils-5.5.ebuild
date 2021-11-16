# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools flag-o-matic

DESCRIPTION="A selection of tools from Debian"
HOMEPAGE="https://packages.qa.debian.org/d/debianutils.html"
SRC_URI="mirror://debian/pool/main/d/${PN}/${PN}_${PV}.orig.tar.xz"

LICENSE="BSD GPL-2 SMAIL"
KEYWORDS="amd64 arm arm64 x86"

SLOT="0"

IUSE="+installkernel static"

DEPEND="
	installkernel? (
		!sys-kernel/installkernel-gentoo
		!sys-kernel/installkernel-systemd-boot
	)
"

PATCHES=(
	"${FILESDIR}"/${PN}-3.4.2-no-bs-namespace.patch
)

src_prepare() {

	# Avoid adding po4a dependency, upstream refreshes manpages.
	sed -i -e '/SUBDIRS/s|po4a||' Makefile.am || die

	# apply any user patches
	eapply_user

	eautoreconf
}

src_configure() {
	use static && append-ldflags -static
	default
}

src_install() {

	into /
	dobin run-parts
	use installkernel && dosbin installkernel

	into /usr
	dobin ischroot
	dosbin savelog

	doman ischroot.1 run-parts.8 savelog.8
	use installkernel && doman installkernel.8

	dodoc CHANGELOG
	keepdir /etc/kernel/postinst.d
}
