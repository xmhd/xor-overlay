# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..10} )

inherit distutils-r1

APPI_VERSION=${PV%.*}
APPI_RELEASE=${PV##*.}

SRC_URI="https://github.com/funtoo/appi/archive/v${PV}.tar.gz -> ${P}.tar.gz"

DESCRIPTION="Another Portage Python Interface"
HOMEPAGE="https://gitlab.com/apinsard/appi/"

LICENSE="GPL-2"
KEYWORDS="amd64"

SLOT="0"

RDEPEND="
	sys-apps/portage
"

DEPEND="
	${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
"
