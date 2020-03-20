# Copyright 2012-2020 Xor Technologies
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for Java"
SLOT="${PV}"

RDEPEND="|| (
		dev-java/openjdk:${SLOT}
		dev-java/openjdk-bin:${SLOT}
	)"

if [[ ${PV} != 9999 ]]; then
	KEYWORDS="x86 amd64 arm arm64"
fi
