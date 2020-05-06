# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Gentoo automatic kernel building scripts"
HOMEPAGE="http://www.gentoo.org"
LICENSE="GPL-2"

SLOT="0"

IUSE="ibm firmware selinux"

DEPEND="
	sys-kernel/dracut
        selinux? ( sys-libs/libselinux )
	firmware? ( sys-kernel/linux-firmware )
"

RESTRICT=""

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://bitbucket.org/_x0r/genkernel.git"
	EGIT_BRANCH="master"
	inherit git-r3 bash-completion-r1 eutils
	KEYWORDS="*"
fi

src_unpack() {
	if [[ ${PV} == 9999* ]] ; then
		git-r3_src_unpack
	else
		unpack ${P}.tar.bz2
	fi
	# TODO: move below to src_prepare
	use selinux && sed -i 's/###//g' "${S}"/gen_compile.sh
}

src_compile() {
	if [[ ${PV} == 9999* ]]; then
		emake || die
	fi
}

src_install() {

	doman genkernel.8 || die "doman"
	dodoc AUTHORS ChangeLog README TODO || die "dodoc"

	dobin genkernel || die "dobin genkernel"
	insinto /etc
	doins genkernel.conf || die "doins genkernel.conf"

	rm -f genkernel genkernel.8 AUTHORS ChangeLog README TODO genkernel.conf

	insinto /usr/share/genkernel
	doins -r "${S}"/* || die "doins"
	use ibm && cp "${S}"/ppc64/kernel-2.6-pSeries "${S}"/ppc64/kernel-2.6 || \
		cp "${S}"/arch/ppc64/kernel-2.6.g5 "${S}"/arch/ppc64/kernel-2.6

	dobashcompletion "${FILESDIR}"/genkernel.bash
}

pkg_preinst() {
	use selinux && dosed 's/###//' usr/share/genkernel/gen_compile.sh
}

pkg_postinst() {
	echo
	elog 'Documentation is available in the genkernel manual page'
	elog 'as well as the following URL:'
	echo
	elog 'http://www.gentoo.org/doc/en/genkernel.xml'
	echo
	ewarn "Kernel command line arguments have changed. Genkernel uses Dracut"
	ewarn "to generate initramfs. See man 7 dracut.kernel for help on kernel"
	ewarn "cmdline arguments."
	echo
	ewarn "Don't use internal initramfs generation tool as it's beining removed"
	ewarn "at the moment."
	echo

	bash-completion_pkg_postinst
}
