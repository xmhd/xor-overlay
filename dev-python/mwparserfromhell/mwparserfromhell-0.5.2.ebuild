# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..10} )

inherit distutils-r1

DESCRIPTION="Python MediaWiki parser"
HOMEPAGE="https://github.com/earwig/mwparserfromhell/"
SRC_URI="https://github.com/earwig/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
KEYWORDS="amd64"

SLOT="0"

IUSE=""

DEPEND="
	dev-python/setuptools[$PYTHON_USEDEP]
"
