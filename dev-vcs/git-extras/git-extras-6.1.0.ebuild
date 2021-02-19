# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="GIT utilities -- repo summary, repl, changelog population, author commit percentages and more"
HOMEPAGE="https://github.com/tj/git-extras"
SRC_URI="https://github.com/tj/git-extras/archive/${PV}.tar.gz"

KEYWORDS="~amd64 ~x86"
LICENSE="MIT"

SLOT="0"

IUSE="zsh-completion"

RDEPEND="
	dev-vcs/git
"

DEPEND="
	${RDEPEND}
	zsh-completion? ( app-shells/zsh )
"

src_compile() {
	# ebuild will attempt to run make without the install command
	# so just bypass this step.
	true
}

src_install() {
	emake DESTDIR="${D}" \
		PREFIX="${EPREFIX}"/usr \
		MANPREFIX="${EPREFIX}"/usr/share/man/man1 \
		SYSCONFDIR="${EPREFIX}"/etc \
		install

	if use zsh-completion; then
		insinto /usr/share/zsh/site-functions
		doins etc/git-extras-completion.zsh
	fi
}
