# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KDE_ORG_COMMIT=7c6c0030cf80ef7b9ace42996b0e0c3a72f76860
QT5_MODULE="qtbase"
inherit qt5-build

DESCRIPTION="Network abstraction library for the Qt5 framework"

if [[ ${QT5_BUILD_TYPE} == release ]]; then
	KEYWORDS="amd64 arm arm64 ~hppa ppc ppc64 ~riscv ~sparc x86"
fi

IUSE="connman dtls gssapi libproxy networkmanager sctp +ssl"
REQUIRED_USE="!dtls"

DEPEND="
	=dev-qt/qtcore-${QT5_PV}*:5=
	sys-libs/zlib:=
	connman? ( =dev-qt/qtdbus-${QT5_PV}* )
	gssapi? ( virtual/krb5 )
	libproxy? ( net-libs/libproxy )
	networkmanager? ( =dev-qt/qtdbus-${QT5_PV}* )
	sctp? ( kernel_linux? ( net-misc/lksctp-tools ) )
	ssl? ( >=dev-libs/openssl-1.1.1:0= )
"
RDEPEND="${DEPEND}
	connman? ( net-misc/connman )
	networkmanager? ( net-misc/networkmanager )
"

QT5_TARGET_SUBDIRS=(
	src/network
	src/plugins/bearer/generic
)

QT5_GENTOO_CONFIG=(
	libproxy:libproxy:
	ssl::SSL
	ssl::OPENSSL
	ssl:openssl-linked:LINKED_OPENSSL
)

QT5_GENTOO_PRIVATE_CONFIG=(
	:network
)

PATCHES=(
	"${FILESDIR}"/${PN}-5.15.2-r11-libressl.patch # Bug 562050, not upstreamable
)

pkg_setup() {
	use connman && QT5_TARGET_SUBDIRS+=(src/plugins/bearer/connman)
	use networkmanager && QT5_TARGET_SUBDIRS+=(src/plugins/bearer/networkmanager)
}

src_configure() {
	local myconf=(
		$(usev connman -dbus-linked)
		$(qt_use gssapi feature-gssapi)
		$(qt_use libproxy)
		$(usev networkmanager -dbus-linked)
		$(qt_use sctp)
		$(qt_use dtls)
		$(usev ssl -openssl-linked)
	)
	qt5-build_src_configure
}

src_install() {
	qt5-build_src_install

	# workaround for bug 652650
	if use ssl; then
		sed -e "/^#define QT_LINKED_OPENSSL/s/$/ true/" \
			-i "${D}${QT5_HEADERDIR}"/Gentoo/${PN}-qconfig.h || die
	fi
}