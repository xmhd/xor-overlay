# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit prefix

DESCRIPTION="Utility to change the binutils version being used"
HOMEPAGE="https://wiki.gentoo.org/wiki/Project:Toolchain"
SRC_URI="https://dev.gentoo.org/~slyfox/distfiles/${P}.tar.xz"

LICENSE="GPL-2"
KEYWORDS="amd64 arm arm64 x86"

SLOT="0"

IUSE="+native-symlinks"

# We also RDEPEND on sys-apps/findutils which is in base @system
RDEPEND="sys-apps/gentoo-functions"

src_prepare() {

	eapply "${FILESDIR}/0001-add-bpf-target.patch"

	eapply_user
}

src_compile() {
	emake PV="${PV}" USE_NATIVE_LINKS="$(usex native-symlinks)"
}

src_install() {
	emake DESTDIR="${D}" PV="${PV}" install

	use prefix && eprefixify "${ED}"/usr/bin/${PN}
}

pkg_postinst() {
	# Re-register all targets. USE flags or new versions can change
	# installed symlinks.
	local x
	for x in $(binutils-config -C -l 2>/dev/null | awk '$NF == "*" { print $2 }') ; do
		binutils-config ${x}
	done
}
