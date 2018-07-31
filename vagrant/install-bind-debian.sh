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

#
BIND_USER="bind"
BIND_GROUP="bind"

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
	"--sysconfdir=/etc/bind"
	"--localstatedir=/var"
	"--mandir=/usr/share/man"
	"--enable-threads"
	"--with-libtool"
	"--disable-static"
)

_array_configure_options=(
	"--sysconfdir=/etc/bind"
	"--with-python=python3"
	"--localstatedir=/"
	"--enable-threads"
	"--enable-largefile"
	"--with-libtool"
	"--enable-shared"
	"--enable-static"
	"--with-gost=no"
	"--with-openssl=/usr"
	"--with-gssapi=/usr"
	"--with-libidn2"
	"--with-libjson=/usr"
	"--with-lmdb=/usr"
	"--with-gnu-ld"
	"--with-geoip=/usr"
	"--with-atf=no"
	"--enable-ipv6"
	"--enable-rrl"
	"--enable-filter-aaaa"
	"--with-randomdev=/dev/urandom"
	"--enable-dnstap"

)

# configure option
# "--enable-debug"
# "--enable-selftest"

echo "# DEBUG count of parameter ${#array_configure_options[@]} "

# call function
configure-package "$BUILD_DIR/$BIND_VERSION" "configure" "${array_configure_options[@]}"

# call function
make-package "$BUILD_DIR/$BIND_VERSION"
# call function
make-install-package "$BUILD_DIR/$BIND_VERSION" "install"

function check-installation() {

	cd "$BUILD_DIR/$BIND_VERSION"
	cd ./bin/test/system
	sudo sh ifconfig.sh up
	sudo ./runall.sh
	sudo sh ifconfig.sh down

}

# deactivate check-installation

function create-user-and-group() {

	echo "#INFO create user bind and group bind"

	# from here
	# https://sources.debian.org/src/bind9/1:9.11.4+dfsg-3/debian/bind9.postinst/
	getent group $BIND_GROUP >/dev/null 2>&1 || addgroup --system $BIND_GROUP
	getent passwd $BIND_USER >/dev/null 2>&1 || adduser --system --home /var/cache/$BIND_USER --no-create-home --disabled-password --ingroup $BIND_GROUP $BIND_USER

}

create-user-and-group

function create-home-directory() {

	BIND_USER_HOME_DIR=$(getent passwd bind | cut -f6 -d:)

	echo "# ACTION create $HOME_BIND home directory $BIND_USER_HOME_DIR"

	mkdir -p "$BIND_USER_HOME_DIR"
	chown "$BIND_USER":"$BIND_GROUP" "$BIND_USER_HOME_DIR"
	chmod 0755 "$BIND_USER_HOME_DIR"

}

create-home-directory

function create-etc-default-bind() {

	ETC_DEFAULT_BIND="/etc/default/bind9"

	echo "# ACTION prepare $ETC_DEFAULT_BIND"
	cat <<EOF >"$ETC_DEFAULT_BIND"
# run resolvconf?
RESOLVCONF=yes

# startup options for the server
OPTIONS="-u bind"

EOF

}

create-etc-default-bind

function create-zone-file() {

	ZONE_FILE_NAME="/etc/bind/named.conf"

	echo "# ACTION prepare file $ZONE_FILE_NAME"

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
# deactivate create-zone-file

function bind-prepare-home-zone() {

	echo "# ACTION prepare home zone"

	mkdir -p /var/named/home.lan

	touch /var/named/home.lan/db.home

	chown -R $BIND_USER:$BIND_GROUP /var/named/home.lan

}

function prepare-rndc-config-generation() {

	ETC_BIND_RNDC_CONF="/etc/bind/rndc.conf"

	echo "# ACTION generate $ETC_BIND_RNDC_CONF"

	rndc-confgen >$ETC_BIND_RNDC_CONF

}

prepare-rndc-config-generation

function prepare-db-home-zone() {

	VAR_NAMED_HOME_LAN_DB_HOME="/var/named/home.lan/db.home"

	echo "# ACTION create file $VAR_NAMED_HOME_LAN_DB_HOME"

	cat <<EOF >"$VAR_NAMED_HOME_LAN_DB_HOME"
	# check is wrote
$ORIGIN home.lan.
$TTL 86400
@    IN    SOA    proxy.home.lan.    proxy.home.lan. (
    2014032801 ; Serial
    28800 ; Refresh
    7200 ; Retry
    604800 ; Expire
    86400 ; Negative Cache TTL
    )
@    IN    NS    proxy.home.lan.
proxy    IN    A    192.168.201.250
EOF

}

bind-prepare-home-zone

function prepare-resolv-conf() {

	RESOLV_CONF="resolv.conf"

	echo "# ACTION config $RESOLV_CONF"

	echo"# ACTION save old /etc/resolv.conf"
	cp /etc/$RESOLV_CONF /etc/$RESOLV_CONF_before_install_bind
	cat <<EOF >"/etc/$RESOLV_CONF"

search localdomain home.lan
nameserver 127.0.0.1
EOF
}

function enable-bind-as-service() {

	echo "# INFO change to $TEMP_DIR"
	cd $TEMP_DIR

	echo "# INFO DOWNLOAD /etc/init.d/bind file"
	#curl https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/bind9.init -o $TEMP_DIR/bind9

	file-download-from-url "https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/bind9.init" "bind9" "/etc/init.d"

	echo "# INFO Download bind9.services file"
	# curl "https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/bind9.service" -o $TEMP_DIR/bind.service
	file-download-from-url "https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/bind9.service" "bind9.service" "/etc/systemd/system"

	ETC_BIND="/etc/bind"

	DEBIAN_BIND_SOURCE_REPO="https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/extras/etc/"

	DOWNLOAD_DNS_FILES=(
		"db.0"
		"db.127"
		"db.255"
		"db.empty"
		"db.local"
		"named.conf"
		"named.conf.default-zones"
		"named.conf.local"
		"named.conf.options"
		"zones.rfc1918"

	)

	for dnsFile in "${DOWNLOAD_DNS_FILES[@]}"; do #  <-- Note: Added "" quotes.
		echo "$dnsFile" # (i.e. do action / processing of $databaseName here...)
		file-download-from-url "${DEBIAN_BIND_SOURCE_REPO}${dnsFile}" "${dnsFile}" "$ETC_BIND"

	done

	mkdir -p /usr/share/dns/
	# https://www.internic.net/domain/named.root
	file-download-from-url "https://www.internic.net/domain/named.root" "root.hints" "/usr/share/dns/"

	# /etc/bind/named.conf
	#file-download-from-url "${DEBIAN_BIND_SOURCE_REPO}named.conf" "named.conf" "$ETC_BIND"

	# /etc/bind/named.conf.options
	#file-download-from-url "${DEBIAN_BIND_SOURCE_REPO}named.conf.options" "named.conf.options" "$ETC_BIND"

	# named.conf.local
	#file-download-from-url "${DEBIAN_BIND_SOURCE_REPO}named.conf.local" "named.conf.local" "$ETC_BIND"

	# named.conf.default-zones
	#file-download-from-url "${DEBIAN_BIND_SOURCE_REPO}named.conf.default-zones" "named.conf.default-zones" "$ETC_BIND"

	# zones.rfc1918
	#file-download-from-url "${DEBIAN_BIND_SOURCE_REPO}zones.rfc1918" "zones.rfc1918" "$ETC_BIND"

}

enable-bind-as-service

function check-named-conf() {

	echo "# ACTION check /etc/bind/named.conf"

	if (/usr/sbin/named-checkconf /etc/bind/named.conf); then
		echo "# INFO /etc/named.conf valid"
	else
		echo "# ERROR /etc/named.conf raise a error"
		echo "# EXIT 1"
		exit 1
	fi
}

check-named-conf
