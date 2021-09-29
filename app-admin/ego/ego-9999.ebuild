# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..10} )

inherit python-r1

DESCRIPTION="Funtoo's configuration tool: ego, epro, edoc, boot-update"
HOMEPAGE="http://www.funtoo.org/Package:Ego"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	SRC_URI=""
	EGIT_REPO_URI="https://github.com/cairnlinux/ego.git"
	KEYWORDS=""
else
	SRC_URI="https://www.github.com/funtoo/ego/tarball/${PVR} -> ego-${PVR}.tar.gz"
	KEYWORDS="~amd64"
fi


LICENSE="GPL-2"

SLOT="0"

IUSE="zsh-completion"

DEPEND="
	$PYTHON_DEPS
	!sys-boot/boot-update
"

RDEPEND="
	${RDEPEND}
"

PDEPEND="
	>=dev-python/appi-0.2[${PYTHON_USEDEP}]
	dev-python/mwparserfromhell[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
"

src_unpack() {

	if [[ ${PV} == 9999* ]]; then
		git-r3_src_unpack
	else
		unpack ${A}
		mv "${WORKDIR}/funtoo-${PN}"-??????? "${S}" || die
	fi
}

src_install() {
	exeinto /usr/share/ego/modules
	doexe $S/modules/*.ego
	rm $D/usr/share/ego/modules/upgrade*
	insinto /usr/share/ego/modules-info
	doins $S/modules-info/*
	rm $D/usr/share/ego/modules-info/upgrade*
	insinto /usr/share/ego/python
	doins -r $S/python/*
	rm -rf $D/usr/share/ego/python/test
	dobin $S/ego
	dosym ego /usr/bin/epro
	dosym ego /usr/bin/edoc
	dosym /usr/bin/ego /sbin/boot-update
	doman doc/*.[1-8]
	dodoc doc/*.rst
	insinto /etc
	doins $S/etc/*.conf*

	if use zsh-completion; then
		insinto /usr/share/zsh/site-functions
		doins contrib/completion/zsh/_ego
	fi
}
