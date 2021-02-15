# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit linux-info eutils linux-mod git-r3

DESCRIPTION="Linux ASUS WMI Sensor driver for Ryzen motherboards."
HOMEPAGE="https://github.com/electrified/asus-wmi-sensors"
EGIT_REPO_URI="https://github.com/electrified/asus-wmi-sensors.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="virtual/linux-sources"
RDEPEND=""

BUILD_TARGETS="all"
BUILD_TARGET_ARCH="${ARCH}"
MODULE_NAMES="asus-wmi-sensors(drivers/hwmon:${S})"

S="${WORKDIR}"

pkg_setup()
{
    CONFIG_CHECK="ACPI_WMI"
    ERROR_ACPI_WMI="ACPI_WMI: Please enable it. If you can't find it, look at 'Device Drivers -> X86 Platform Specific Device Drivers'."

    linux-mod_pkg_setup
}

src_install()
{
    linux-mod_src_install
    insinto /etc/modules-load.d/
    doins "${FILESDIR}/asus-wmi-sensors.conf"
}

pkg_postinst()
{
    linux-mod_pkg_postinst
}
