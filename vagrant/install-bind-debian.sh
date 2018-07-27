#!/bin/bash

# install bind 9.12

# Exit immediately if a command returns a non-zero status
set -e

# load utility-method.sh
# shellcheck disable=SC1090,SC1091
source "./utility-methods.sh"

# TEMP_DIR
readonly TEMP_DIR="/tmp"

# BUILD_DIR for tar extract, make ...
readonly BUILD_DIR=$TEMP_DIR

# message
echo "# OK ${0##*/} loaded"

# CONSTANTS
readonly BIND_DOWNLOAD_SITE="ftp://ftp.isc.org/isc/bind9/"

# VARIABLES
VERSION_NUMBER="0.0.0"
# check git

function detect-last-bind-version() {

	readonly TEMP_FILE="/tmp/bind-version.txt"

	curl -L $BIND_DOWNLOAD_SITE -o $TEMP_FILE

	VERSION_NUMBER=$(awk '{print $9}' $TEMP_FILE | sed 's/-.*$//g' | sed 's/[^0-9.]*//' | sed 's/[a-z].*$//g' | sort -u | sort -V | tail -1)

	echo "# INFO BIND last release is $VERSION_NUMBER"

}

# call function
detect-last-bind-version

echo "# INFO GLOBAL BIND last release is $VERSION_NUMBER"

# set global
BIND_TAR="bind-$VERSION_NUMBER.tar.gz"
BIND_VERSION=${BIND_TAR//.tar.gz/}
# shellcheck disable=SC2034
BIND_VERSION_STRING=${BIND_VERSION//-//}

# call function
download-and-extract "$BIND_DOWNLOAD_SITE$VERSION_NUMBER" "$BIND_TAR" "$BUILD_DIR"

# set prefix installation
PREFIX="/usr"

# from here
# http://www.linuxfromscratch.org/blfs/view/svn/server/bind.html
array_configure_options=(
	"--prefix=${PREFIX}"
	"--sysconfdir=/etc"
	"--localstatedir=/var"
	"--mandir=/usr/share/man"
	"--enable-threads"
	"--with-libtool"
	"--disable-static"
	"--disable-linux-caps"
)

# configure option
# "--enable-debug"
# "--enable-selftest"

# call function
configure-package "$BUILD_DIR/$BIND_VERSION" "configure" "${array_configure_options[@]}"

#call function
make-package "$BUILD_DIR/$BIND_VERSION"

function create-zone-file() {

	NAME_CONF_ZONE="named.conf"

	# from here
	# http://roberts.bplaced.net/index.php/linux-guides/centos-6-guides/proxy-server/squid-transparent-proxy-http-https

	cat <<EOF >"$ZONE_FILE_NAME"
EOF

}
