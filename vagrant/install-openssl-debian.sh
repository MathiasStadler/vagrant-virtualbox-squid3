#!/bin/bash

# install bind 9.12

# Exit immediately if a command returns a non-zero status
set -e

# import project variables
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; else
	echo "# OK WORK DIR => $PWD"
fi

# SETTINGS_DIR="${DIR}/settings"
SETTINGS_DIR="../settings"
if [[ ! -d "$SETTINGS_DIR" ]]; then
	echo "# ERROR SETTINGS_DIRECTORY NOT found => $SETTINGS_DIR"
	# SETTINGS_DIR="${DIR}/settings"
	SETTINGS_DIR="$HOME/settings"
	if [[ ! -d "$SETTINGS_DIR" ]]; then
		echo "# ERROR SETTINGS_DIRECTORY NOT found => $SETTINGS_DIR"
		echo "# EXIT 1"
		SETTINGS_DIR="/home/vagrant/settings"
		if [[ ! -d "$SETTINGS_DIR" ]]; then
			echo "# ERROR SETTINGS_DIRECTORY NOT found => $SETTINGS_DIR"
			echo "# EXIT 1"
			exit 1
		else
			echo "# OK SETTINGS_DIRECTORY => $SETTINGS_DIR"
		fi
	else
		echo "# OK SETTINGS_DIRECTORY => $SETTINGS_DIR"
	fi
else
	echo "# OK settings dir $SETTINGS_DIR"
fi

# load utility-method.sh from same directory
# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/utility-methods-debian.sh"

# TEMP_DIR
readonly TEMP_DIR="/tmp"

# BUILD_DIR for tar extract, make ...
readonly BUILD_DIR=$TEMP_DIR

# message
echo "# OK ${0##*/} loaded"

# CONSTANTS
readonly OPENSSL_DOWNLOAD_SITE="https://ftp.openssl.org/source/"

function delete-avaible-openssl() {

	if (dpkg-query -l openssl); then
		# installed remove it

		if (export DEBIAN_FRONTEND=noninteractive && sudo apt-get purge -y openssl); then
			echo "# INFO delete openssl"
		else
			echo "# ERROR delete openssl package raise a error"
			echo "# EXIT 1"
			exit 1
		fi
	else
		echo "# INFO no openssl packages installed"
	fi

}

function detect-last-openssl-version() {

	readonly TEMP_FILE="/tmp/openssl-version.txt"

	curl -L $OPENSSL_DOWNLOAD_SITE -o $TEMP_FILE

	OPENSSL_TAR=$(grep -o '<a href=['"'"'"][^"'"'"']*['"'"'"]' $TEMP_FILE | sed -e 's/^<a href=["'"'"']//' -e 's/["'"'"']$//' | grep tar.gz$ | grep -v fips | sort -V | tail -1)
	echo "# INFO openssl tar last release is $OPENSSL_TAR"

}

# call function
detect-last-openssl-version

echo "# INFO GLOBAL openssl tar last release is $OPENSSL_TAR"

# set global

OPENSSL_VERSION=${OPENSSL_TAR//.tar.gz/}
# shellcheck disable=SC2034
OPENSSL_VERSION_STRING=${OPENSSL_VERSION//-//}

#
array_install_packages=(
	"libz-dev"
)

#call function
install-packages "${array_install_packages[@]}"

# call function
download-and-extract "$OPENSSL_DOWNLOAD_SITE" "$OPENSSL_TAR" "$BUILD_DIR"

# call function
# delete first if you had all packages downloaded
# deactivate delete-avaible-openssl

# set prefix installation
# PREFIX="/usr"
# parallel openssl installation
PREFIX="/usr/local"

# from here
# http://www.linuxfromscratch.org/blfs/view/svn/server/bind.html
#shellcheck disable=SC2034
_array_configure_options=(
	"--prefix=${PREFIX}"
	"--openssldir=/etc/ssl"
	"--libdir=lib/openssl-1.0"
	" shared"
	" zlib-dynamic"
)

array_configure_options=(
	"--prefix=/usr"
	"--openssldir=/etc/ssl"
	"--libdir=lib"
	"shared"
	"zlib-dynamic"
	"-Wl,-R,'\$(LIBRPATH)'"
	"-Wl,--enable-new-dtags"
)

#./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic -Wl,-R,'$(LIBRPATH)' -Wl,--enable-new-dtags

# CFLAGS=-fPIC from here
# https://stackoverflow.com/questions/28234300/usr-local-ssl-lib-libcrypto-a-could-not-read-symbols-bad-value

# call function
configure-package "$BUILD_DIR/$OPENSSL_VERSION" "config" "${array_configure_options[@]}"

## cd "$BUILD_DIR/$OPENSSL_VERSION"
## ./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic -Wl,-R,'$(LIBRPATH)' -Wl,--enable-new-dtags

#call function
make-package "$BUILD_DIR/$OPENSSL_VERSION"

make-install-package "$BUILD_DIR/$OPENSSL_VERSION" "install_sw"

## make -j 6 -l 4

## sudo make install_sw
