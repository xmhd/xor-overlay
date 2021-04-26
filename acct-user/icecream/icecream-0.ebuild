# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86"

DESCRIPTION="User for sys-devel/icecream"
ACCT_USER_ID=-1
ACCT_USER_GROUPS=( ${PN} )

acct-user_add_deps
