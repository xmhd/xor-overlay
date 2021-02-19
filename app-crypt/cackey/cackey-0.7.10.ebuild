# Distributed under the terms of the GNU General Public License 2 

EAPI=7

DESCRIPTION="CACKey provides a standard interface (PKCS#11) for smartcards connected to a PC/SC compliant reader."
HOMEPAGE="https://cackey.rkeene.org/fossil/home"
SRC_URI="https://cackey.rkeene.org/download/${PV}/${P}.tar.gz"

KEYWORDS="*"
LICENSE="MIT"

SLOT="0"

IUSE=""

DEPEND="sys-apps/pcsc-lite"

src_prepare() {
	./autogen.sh
	default
}

src_configure() {
	econf \
	--libdir="/usr/$(get_libdir)/pkcs11"
}
