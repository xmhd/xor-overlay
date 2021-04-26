# Distributed under the terms of the GNU General Public License v2

EAPI=7

HOMEPAGE="https://kernel.org"
DESCRIPTION="Virtual for Linux kernel sources"

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sparc ~x86"
LICENSE="GPL-2"

SLOT="0"

IUSE="firmware"

RDEPEND="
	firmware? ( sys-kernel/linux-firmware )
	|| (
		sys-kernel/gentoo-sources
		sys-kernel/dummy-sources
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
