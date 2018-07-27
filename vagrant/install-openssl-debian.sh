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
readonly OPENSSL_DOWNLOAD_SITE="https://ftp.openssl.org/source/"

# VARIABLES
VERSION_NUMBER="0.0.0"
# check git

function detect-last-bind-version() {

	readonly TEMP_FILE="/tmp/openssl-version.txt"

	curl -L $OPENSSL_DOWNLOAD_SITE -o $TEMP_FILE

	OPENSSL_TAR=$(cat $TEMP_FILE | grep -o '<a href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^<a href=["'"'"']//' -e 's/["'"'"']$//' | grep tar.gz$ | grep -v fips | sort -V | tail -1)
	echo "# INFO openssl tar last release is $OPENSSL_TAR"

}

# call function
detect-last-bind-version

echo "# INFO GLOBAL openssl tar last release is $OPENSSL_TAR"

# set global

OPENSSL_VERSION=${OPENSSL_TAR//.tar.gz/}
# shellcheck disable=SC2034
OPENSSL_VERSION_STRING=${OPENSSL_VERSION//-//}

# call function
download-and-extract "$OPENSSL_DOWNLOAD_SITE" "$OPENSSL_TAR" "$BUILD_DIR"

# set prefix installation
PREFIX="/usr"

# from here
# http://www.linuxfromscratch.org/blfs/view/svn/server/bind.html
array_configure_options=(
	"--prefix=${PREFIX}"
	" --openssldir=/etc/ssl"
	" --libdir=lib/openssl-1.0"
	" shared"
	" zlib-dynamic"
)

# call function
configure-package "$BUILD_DIR/$OPENSSL_VERSION" "config" "${array_configure_options[@]}"
