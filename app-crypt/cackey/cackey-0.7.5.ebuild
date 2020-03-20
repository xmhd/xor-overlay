# Distributed under the terms of the GNU General Public License 2 

EAPI=6

DESCRIPTION="CACKey provides a standard interface (PKCS#11) for smartcards connected to a PC/SC compliant reader."
HOMEPAGE="http://cackey.rkeene.org/fossil/home"
SRC_URI="http://cackey.rkeene.org/download/0.7.5/${P}.tar.gz"

KEYWORDS="*"
SLOT="0"
LICENSE="GPL-2" # <-- is it?
IUSE=""

DEPEND="sys-apps/pcsc-lite"

src_prepare() {
	./autogen.sh
	default
}

src_install() {
	dosbin leakcheck/leakcheck
	default
}
