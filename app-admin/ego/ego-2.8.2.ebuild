# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..10} )

inherit python-r1

DESCRIPTION="Funtoo's configuration tool: ego, epro, edoc, boot-update"
HOMEPAGE="http://www.funtoo.org/Package:Ego"
SRC_URI="https://www.github.com/funtoo/ego/tarball/${PVR} -> ego-${PVR}.tar.gz"

LICENSE="GPL-2"
KEYWORDS="~amd64"

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

PATCHES=(
	"${FILESDIR}"/0001-python-ego-profile.py-fix-per-arch-mix-ins.patch
	"${FILESDIR}"/0002-modules-sync.ego-fix-for-update_repos_conf.patch
	"${FILESDIR}"/0003-remove-special-python-kit-logic-it-is-just-another-k.patch
)

src_unpack() {
	unpack ${A}
	mv "${WORKDIR}/funtoo-${PN}"-??????? "${S}" || die
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
