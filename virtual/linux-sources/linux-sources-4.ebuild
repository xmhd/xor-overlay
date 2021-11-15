# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for Linux kernel sources"

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sparc ~x86"

SLOT="0"

IUSE="build-kernel firmware"

RDEPEND="
	build-kernel? ( sys-kernel/gentoo-sources[build-kernel] )
	firmware? ( sys-kernel/linux-firmware )
	|| (
		sys-kernel/gentoo-sources
		sys-kernel/vanilla-sources
		sys-kernel/git-sources
		sys-kernel/hardened-sources
		sys-kernel/mips-sources
		sys-kernel/pf-sources
		sys-kernel/rt-sources
		sys-kernel/zen-sources
		sys-kernel/raspberrypi-sources
		sys-kernel/gentoo-kernel
		sys-kernel/gentoo-kernel-bin
		sys-kernel/vanilla-kernel
		sys-kernel/bliss-kernel-bin
	)
"
