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

#
array_install_packages=(
	"libcap-dev"
)

#call function
install-packages "${array_install_packages[@]}"

# call function
download-and-extract "$BIND_DOWNLOAD_SITE$VERSION_NUMBER" "$BIND_TAR" "$BUILD_DIR"

# set prefix installation
PREFIX="/usr"

#https://sources.debian.org/src/bind9/1:9.11.4+dfsg-3/debian/

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
)

# configure option
# "--enable-debug"
# "--enable-selftest"

echo "# DEBUG count of parameter ${#array_configure_options[@]} "

# call function
configure-package "$BUILD_DIR/$BIND_VERSION" "configure" "${array_configure_options[@]}"

#call function
# deactivate for test  make-package "$BUILD_DIR/$BIND_VERSION"

# deactivate for test make-install-package "$BUILD_DIR/$BIND_VERSION" "install"

function check-installation() {

	cd "$BUILD_DIR/$BIND_VERSION"
	cd ./bin/test/system
	sudo sh ifconfig.sh up
	sudo ./runall.sh
	sudo sh ifconfig.sh down

}

# check-installation

function create-zone-file() {

	ZONE_FILE_NAME="named.conf"

	# from here
	# http://roberts.bplaced.net/index.php/linux-guides/centos-6-guides/proxy-server/squid-transparent-proxy-http-https

	cat <<EOF >"$ZONE_FILE_NAME"



//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//

acl mynet {
    192.168.201.0/24; # test network
    127.0.0.1; # localhost
    };

options {
    listen-on {
        mynet;
        };
    listen-on-v6 port 53 { ::1; };
    directory     "/var/named";
    dump-file     "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query     { mynet; };
    recursion yes;

    forward only;
    forwarders {
        8.8.8.8;
        };

    dnssec-enable yes;
    dnssec-validation yes;
    dnssec-lookaside auto;

    /* Path to ISC DLV key */
    bindkeys-file "/etc/named.iscdlv.key";

    managed-keys-directory "/var/named/dynamic";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

#############################################
#    home.lan
#############################################

zone "home.lan" IN {
    type master;
    file "/var/named/home.lan/db.home";
    allow-query {
    mynet;
    };
    };

EOF

}

# call function
create-zone-file

function bind_prepare_home_zine() {

	mkdir /var/named/home.lan

	touch /var/named/home.lan/db.home

	chown -R named.named /var/named/home.lan

}

function enable-bind-as-service() {

	echo "# INFO change to $TEMP_DIR"
	cd $TEMP_DIR

	echo "# INFO DOWNLOAD /etc/init.d/bind file"
	#curl https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/bind9.init -o $TEMP_DIR/bind9

	file-download "https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/bind9.init" "bind9" "/etc/init.d"

	echo "# INFO DOWNLOAD bind9.services file"
	# curl "https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/bind9.service" -o $TEMP_DIR/bind.service
	file-download "https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/bind9.service" "bind9.service" "/etc/systemd/system"
}

enable-bind-as-service
