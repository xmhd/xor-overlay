# Distributed under the terms of the GNU General Public License v2

EAPI=7

HOMEPAGE="https://kernel.org"
DESCRIPTION="Virtual for Linux kernel sources"

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
LICENSE="GPL-2"

SLOT="0"

IUSE="dtrace firmware"

RDEPEND="
	dtrace? (
	    || (
	        sys-kernel/cairn-sources[dtrace]
	        sys-kernel/dummy-sources
	    )
	)
	firmware? ( sys-kernel/linux-firmware )
	|| (
	    sys-kernel/cairn-sources
	    sys-kernel/debian-sources
		sys-kernel/gentoo-sources
		sys-kernel/dummy-sources
		sys-kernel/vanilla-sources
		sys-kernel/ck-sources
		sys-kernel/git-sources
		sys-kernel/hardened-sources
		sys-kernel/mips-sources
		sys-kernel/pf-sources
		sys-kernel/rt-sources
		sys-kernel/xbox-sources
		sys-kernel/zen-sources
		sys-kernel/aufs-sources
		sys-kernel/raspberrypi-sources
		sys-kernel/vanilla-kernel
		sys-kernel/vanilla-kernel-bin
	)
"
