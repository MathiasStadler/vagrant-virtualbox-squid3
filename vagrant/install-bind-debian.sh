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

# NAMED server in used before start own bind
NAME_SERVER_IN_USED="0.0.0.0"

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
	"ipcalc"
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
	"--with-randomdev=/dev/urandom"
	"--with-openssl=/usr/local"

)

#shellcheck disable=SC2034
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
# configure-package "$BUILD_DIR/$BIND_VERSION" "configure" "${array_configure_options[@]}"

# call function
configure-package-new-approach "$BUILD_DIR/$BIND_VERSION" "configure" "${array_configure_options[@]}"

# call function
run-ldconfig

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

function get-current-name-server() {

	echo "# ACTION find running name server"

	NAME_SERVER_IN_USED=$(dig google.com | grep ';; SERVER' | awk '{print $3}' | grep -Po '\(\K[^)]*')

	echo "# INFO get current name server $NAME_SERVER_IN_USED"

}

# call function
get-current-name-server

function get-current-network-wide() {

	VM_IP="$(cat /home/vagrant/vm.bridge.ip)"

	NETWORK_AND_WIDE="$(ipcalc "${VM_IP}" | grep Network: | awk '{print $2}')"

	echo "# ACTION get network and wide $NETWORK_AND_WIDE"

}

# call function
get-current-network-wide

function create-user-and-group() {

	echo "# INFO create user bind and group bind"

	# from here
	# https://sources.debian.org/src/bind9/1:9.11.4+dfsg-3/debian/bind9.postinst/
	getent group $BIND_GROUP >/dev/null 2>&1 || addgroup --system $BIND_GROUP
	getent passwd $BIND_USER >/dev/null 2>&1 || adduser --system --home /var/cache/$BIND_USER --no-create-home --disabled-password --ingroup $BIND_GROUP $BIND_USER

}

# call function
create-user-and-group

function create-home-directory() {

	BIND_USER_HOME_DIR=$(getent passwd bind | cut -f6 -d:)

	echo "# ACTION create $HOME_BIND home directory $BIND_USER_HOME_DIR"

	mkdir -p "$BIND_USER_HOME_DIR"
	chown "$BIND_USER":"$BIND_GROUP" "$BIND_USER_HOME_DIR"
	chmod 0755 "$BIND_USER_HOME_DIR"

}

# call function
create-home-directory

function create-chroot-dir() {

	echo "# ACTION create chroot dir for bind/named"

	if (
		mkdir -p /var/lib/named/{etc,dev,usr}
		mkdir -p /var/lib/named/var/{cache,run,log}
		mkdir -p /var/lib/named/var/cache/bind
		mkdir -p /var/lib/named/var/run/bind/run
		mkdir -p /var/lib/named/usr/share/dns

		mknod /var/lib/named/dev/null c 1 3
		mknod /var/lib/named/dev/urandom c 1 8

		mv /etc/bind /var/lib/named/etc
		ln -s /var/lib/named/etc/bind /etc/bind

		chmod 666 /var/lib/named/dev/{null,urandom}
		chown -R bind:bind /var/lib/named/var/*
		chown -R bind:bind /var/lib/named/etc/bind

	); then
		echo "# INFO chroot create"
	else
		echo "# ERROR chroot create raise a error"
		echo "# EXIT 1"
		exit 1
	fi

}

# call function
create-chroot-dir

function create-etc-default-bind() {

	ETC_DEFAULT_BIND="/etc/default/bind9"

	echo "# ACTION prepare $ETC_DEFAULT_BIND"
	cat <<EOF >"$ETC_DEFAULT_BIND"
# run resolvconf?
RESOLVCONF=yes

# startup options for the server
# with chroot
OPTIONS="-u bind -t /var/lib/named"

# without chroot
# OPTIONS="-u bind"

EOF

}

# call function
create-etc-default-bind

function create-zone-file() {

	ZONE_FILE_NAME="/etc/bind/named.conf"

	echo "# ACTION prepare file $ZONE_FILE_NAME"

	# from here
	# http://roberts.bplaced.net/index.php/linux-guides/centos-6-guides/proxy-server/squid-transparent-proxy-http-https

	cat <<EOF >"$ZONE_FILE_NAME"
//
// If you are just adding zones, please do that in /etc/bind/named.conf.local

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
EOF

	ZONE_FILE_NAME_OPTIONS="/etc/bind/named.conf.options"

	echo "# ACTION prepare file $ZONE_FILE_NAME_OPTIONS"

	cat <<EOF >"$ZONE_FILE_NAME_OPTIONS"
	options {
        directory "/var/cache/bind";


		#ACL settings

        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

        // If your ISP provided one or more IP addresses for stable
        // nameservers, you probably want to use them as forwarders.
        // Uncomment the following block, and insert the addresses replacing
        // the all-0's placeholder.

		// forward to default named server
        forwarders {
              $NAME_SERVER_IN_USED;
         };

        //========================================================================
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //========================================================================
        //dnssec-validation auto;

		# from here
		# https://superuser.com/questions/1099215/bind9-dns-server-not-resolving-a-single-domain
		# allow-query             {my-nets;};
        # allow-recursion         {my-nets;};
        # allow-query-cache       {my-nets;};
        # blackhole               {bogus-nets;};
        # allow-transfer          {none;};
        empty-zones-enable      yes;

		# dont provide version,host or system info
        version                 "Version Redacted";
		hostname 				none;
		server-id				none;


		// explain show here
		// http://www.zytrax.com/books/dns/info/dlv.html
		dnssec-enable yes;
    	dnssec-validation yes;
    	dnssec-lookaside no;

        # listen-on-v6 { any; };
};
EOF

	ZONE_FILE_NAME_LOCAL="/etc/bind/named.conf.local"

	echo "# ACTION prepare file $ZONE_FILE_NAME_LOCAL"

	cat <<EOF >"$ZONE_FILE_NAME_LOCAL"
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";
EOF

	ZONE_FILE_ROOT_HINTS="/etc/bind/root_hints"

	echo "# ACTION prepare file $ZONE_FILE_ROOT_HINTS"

	cat <<EOF >"$ZONE_FILE_ROOT_HINTS"
	;       This file holds the information on root name servers needed to
;       initialize cache of Internet domain name servers
;       (e.g. reference this file in the "cache  .  <file>"
;       configuration file of BIND domain name servers).
;
;       This file is made available by InterNIC
;       under anonymous FTP as
;           file                /domain/named.cache
;           on server           FTP.INTERNIC.NET
;       -OR-                    RS.INTERNIC.NET
;
;       last update:     July 09, 2018
;       related version of root zone:     2018070901
;
; FORMERLY NS.INTERNIC.NET
;
.                        3600000      NS    A.ROOT-SERVERS.NET.
A.ROOT-SERVERS.NET.      3600000      A     198.41.0.4
A.ROOT-SERVERS.NET.      3600000      AAAA  2001:503:ba3e::2:30
;
; FORMERLY NS1.ISI.EDU
;
.                        3600000      NS    B.ROOT-SERVERS.NET.
B.ROOT-SERVERS.NET.      3600000      A     199.9.14.201
B.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:200::b
;
; FORMERLY C.PSI.NET
;
.                        3600000      NS    C.ROOT-SERVERS.NET.
C.ROOT-SERVERS.NET.      3600000      A     192.33.4.12
C.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:2::c
;
; FORMERLY TERP.UMD.EDU
;
.                        3600000      NS    D.ROOT-SERVERS.NET.
D.ROOT-SERVERS.NET.      3600000      A     199.7.91.13
D.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:2d::d
;
; FORMERLY NS.NASA.GOV
;
.                        3600000      NS    E.ROOT-SERVERS.NET.
E.ROOT-SERVERS.NET.      3600000      A     192.203.230.10
E.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:a8::e
;
; FORMERLY NS.ISC.ORG
;
.                        3600000      NS    F.ROOT-SERVERS.NET.
F.ROOT-SERVERS.NET.      3600000      A     192.5.5.241
F.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:2f::f
;
; FORMERLY NS.NIC.DDN.MIL
;
.                        3600000      NS    G.ROOT-SERVERS.NET.
G.ROOT-SERVERS.NET.      3600000      A     192.112.36.4
G.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:12::d0d
;
; FORMERLY AOS.ARL.ARMY.MIL
;
.                        3600000      NS    H.ROOT-SERVERS.NET.
H.ROOT-SERVERS.NET.      3600000      A     198.97.190.53
H.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:1::53
;
; FORMERLY NIC.NORDU.NET
;
.                        3600000      NS    I.ROOT-SERVERS.NET.
I.ROOT-SERVERS.NET.      3600000      A     192.36.148.17
I.ROOT-SERVERS.NET.      3600000      AAAA  2001:7fe::53
;
; OPERATED BY VERISIGN, INC.
;
.                        3600000      NS    J.ROOT-SERVERS.NET.
J.ROOT-SERVERS.NET.      3600000      A     192.58.128.30
J.ROOT-SERVERS.NET.      3600000      AAAA  2001:503:c27::2:30
;
; OPERATED BY RIPE NCC
;
.                        3600000      NS    K.ROOT-SERVERS.NET.
K.ROOT-SERVERS.NET.      3600000      A     193.0.14.129
K.ROOT-SERVERS.NET.      3600000      AAAA  2001:7fd::1
;
; OPERATED BY ICANN
;
.                        3600000      NS    L.ROOT-SERVERS.NET.
L.ROOT-SERVERS.NET.      3600000      A     199.7.83.42
L.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:9f::42
;
; OPERATED BY WIDE
;
.                        3600000      NS    M.ROOT-SERVERS.NET.
M.ROOT-SERVERS.NET.      3600000      A     202.12.27.33
M.ROOT-SERVERS.NET.      3600000      AAAA  2001:dc3::35
; End of file

EOF

	ZONE_FILE_DB_LOCAL="/etc/bind/db.local"

	echo "# ACTION prepare file $ZONE_FILE_DB_LOCAL"

	cat <<EOF >"$ZONE_FILE_DB_LOCAL"
;
; BIND data file for local loopback interface
;
\$TTL	604800
@	IN	SOA	localhost. root.localhost. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	localhost.
@	IN	A	127.0.0.1
@	IN	AAAA	::1
EOF

	ZONE_FILE_DB_0="/etc/bind/db.0"

	echo "# ACTION prepare file $ZONE_FILE_DB_0"

	cat <<EOF >"$ZONE_FILE_DB_0"
;
; BIND reverse data file for broadcast zone
;
\$TTL    604800
@       IN      SOA     localhost. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      localhost.

EOF

	ZONE_FILE_DB_127="/etc/bind/db.127"

	echo "# ACTION prepare file $ZONE_FILE_DB_127"

	cat <<EOF >"$ZONE_FILE_DB_127"
\$TTL    604800
@       IN      SOA     localhost. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      localhost.
1.0.0   IN      PTR     localhost.

EOF

	ZONE_FILE_DB_255="/etc/bind/db.255"

	echo "# ACTION prepare file $ZONE_FILE_DB_255"

	cat <<EOF >"$ZONE_FILE_DB_255"
;
; BIND reverse data file for broadcast zone
;
\$TTL    604800
@       IN      SOA     localhost. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      localhost.
EOF

	ZONE_FILE_DB_EMPTY="/etc/bind/db.empty"

	echo "# ACTION prepare file $ZONE_FILE_DB_EMPTY"

	cat <<EOF >"$ZONE_FILE_DB_EMPTY"
; BIND reverse data file for empty rfc1918 zone
;
; DO NOT EDIT THIS FILE - it is used for multiple zones.
; Instead, copy it, edit named.conf, and use that copy.
;
\$TTL    86400
@       IN      SOA     localhost. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      localhost.
EOF

	ZONE_FILE_ZONES_RFC_1918="/etc/bind/zones.rfc1918"

	echo "# ACTION prepare file $ZONE_FILE_ZONES_RFC_1918"

	cat <<EOF >"$ZONE_FILE_ZONES_RFC_1918"
zone "10.in-addr.arpa"      { type master; file "/etc/bind/db.empty"; };

zone "16.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "17.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "18.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "19.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "20.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "21.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "22.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "23.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "24.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "25.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "26.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "27.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "28.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "29.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "30.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };
zone "31.172.in-addr.arpa"  { type master; file "/etc/bind/db.empty"; };

zone "168.192.in-addr.arpa" { type master; file "/etc/bind/db.empty"; };
EOF

	ZONE_FILE_NAME_DEFAULTS_ZONES="/etc/bind/named.conf.default-zones"

	echo "# ACTION prepare file $ZONE_FILE_NAME_DEFAULTS_ZONES"

	cat <<EOF >"$ZONE_FILE_NAME_DEFAULTS_ZONES"
// prime the server with knowledge of the root servers
zone "." {
        type hint;
        file "$ZONE_FILE_ROOT_HINTS";
};

// be authoritative for the localhost forward and reverse zones, and for
// broadcast zones as per RFC 1912

zone "localhost" {
        type master;
        file "/etc/bind/db.local";
};

zone "127.in-addr.arpa" {
        type master;
        file "/etc/bind/db.127";
};

zone "0.in-addr.arpa" {
        type master;
        file "/etc/bind/db.0";
};

zone "255.in-addr.arpa" {
        type master;
        file "/etc/bind/db.255";
};
EOF

}

# call function
create-zone-file

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

# call function
check-named-conf

function bind-prepare-home-zone() {

	echo "# ACTION prepare home zone"

	mkdir -p /var/named/home.lan

	touch /var/named/home.lan/db.home

	chown -R $BIND_USER:$BIND_GROUP /var/named/home.lan

}

function prepare-rndc-config-generation() {

	ETC_BIND_RNDC_CONF="/etc/bind/rndc.conf"

	RNDC_KEY_NAME="proxy-key"

	echo "# ACTION generate $ETC_BIND_RNDC_CONF"

	rndc-confgen -b "512" -k $RNDC_KEY_NAME >$ETC_BIND_RNDC_CONF

}

# call function
prepare-rndc-config-generation

function parse-and-copy-rndc-key-to-bind-named-conf() {

	ETC_BIND_NAMED_CONF_KEY="/etc/bind/named.conf.key"

	echo "# ACTION parse key and controls from $ETC_BIND_RNDC_CONF"
	echo "# INFO RNDC_KEY_NAME => $RNDC_KEY_NAME"

	# Version with key_name
	#sed '/#.*key.*"$RNDC_KEY_NAME".*{/{:1; /}/!{N; b1}; /.*/p}; d' $ETC_BIND_RNDC_CONF | sed 's/^# //g' | sudo tee $ETC_BIND_NAMED_CONF_KEY

	# parse key
	# version without key_name
	sed '/#.*key.*".*".*{/{:1; /#\W};/!{N; b1}; /.*/p}; d' $ETC_BIND_RNDC_CONF | sed 's/^# //g' | sudo tee $ETC_BIND_NAMED_CONF_KEY

	# parse controls
	sed '/#.*controls.*{/{:1; /#\W};/!{N; b1}; /.*/p}; d' $ETC_BIND_RNDC_CONF | sed 's/^# //g' | sudo tee -a $ETC_BIND_NAMED_CONF_KEY

	echo "include \"$ETC_BIND_NAMED_CONF_KEY\";" | sudo tee -a "/etc/bind/named.conf"

}

# call function
parse-and-copy-rndc-key-to-bind-named-conf

# call function
check-named-conf

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
	cp "/etc/$RESOLV_CONF" "/etc/${RESOLV_CONF}_before_install_bind"
	cat <<EOF >"/etc/$RESOLV_CONF"

search localdomain home.lan
nameserver 127.0.0.1
EOF
}

function prepare-zones-files() {

	echo "# INFO change to $TEMP_DIR"
	cd $TEMP_DIR

	ETC_BIND="/etc/bind"

	DEBIAN_BIND_SOURCE_REPO="https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/extras/etc/"

	# shellcheck disable=SC2034
	_DOWNLOAD_DNS_FILES=(
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

	DOWNLOAD_DNS_FILES=()

	for dnsFile in "${DOWNLOAD_DNS_FILES[@]}"; do #  <-- Note: Added "" quotes.
		echo "$dnsFile" # (i.e. do action / processing of $databaseName here...)
		file-download-from-url "${DEBIAN_BIND_SOURCE_REPO}${dnsFile}" "${dnsFile}" "$ETC_BIND"

	done

	mkdir -p /usr/share/dns/
	# https://www.internic.net/domain/named.root
	file-download-from-url "https://www.internic.net/domain/named.root" "root.hints" "/usr/share/dns/"

	# for chroot
	mkdir -p /var/lib/named/usr/share/dns
	# https://www.internic.net/domain/named.root
	file-download-from-url "https://www.internic.net/domain/named.root" "root.hints" "/var/lib/named/usr/share/dns"

}

# call function
# TODO obsolete prepare-zones-files

function prepare-init-and-services-file() {

	echo "# INFO change to $TEMP_DIR"
	cd $TEMP_DIR

	echo "# INFO DOWNLOAD /etc/init.d/bind file"

	file-download-from-url "https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/bind9.init" "bind9" "/etc/init.d"

	echo "# INFO Download bind9.services file"

	file-download-from-url "https://sources.debian.org/data/main/b/bind9/1:9.11.4+dfsg-3/debian/bind9.service" "bind9.service" "/etc/systemd/system"

}

prepare-init-and-services-file

function enable-logging() {

	# info here
	# https://kb.isc.org/article/AA-01526/0/BIND-Logging-some-basic-recommendations.html

	echo "# INFO enabling logging"

	echo "# ACTION append logging to "

	# for logging
	BIND_LOG="/var/log/bind.log"

	touch $BIND_LOG
	chown bind:bind $BIND_LOG
	chmod 0664 $BIND_LOG

	# for chroot logging
	BIND_LOG="/var/lib/named/var/log/bind.log"

	touch $BIND_LOG
	chown bind:bind $BIND_LOG
	chmod 0664 $BIND_LOG

	# append to file
	cat <<EOF >>"/etc/bind/named.conf.options"

	# https://adminwerk.com/bind9-im-gefangnis/
logging {
        channel simple_log {
                // 'file' relativ zu chroot()-Umgebung
                file "/var/log/bind.log" versions 3 size 5m;
                severity warning;
                print-time yes;
                print-severity yes;
                print-category yes;
        };
        category default {
                simple_log;
        };
};
EOF

	echo "# ACTION add bind9 logging to rsyslog"

	cat <<EOF >"/etc/rsyslog.d/bind9-chroot.conf"
$AddUnixListenSocket /var/lib/named/dev/log
EOF

	echo "# ACTION restart rsyslog"

	if (sudo service rsyslog restart); then
		echo "# INFO rsyslog restart"
	else
		echo "# ERROR rsyslog restart raise a error"
		echo "# INFO Look at cat /var/log/syslog for hits and errors"
		echo "# EXIT 1"
		exit 1
	fi

}

# call function
enable-logging

# call function
check-named-conf

function set-acl-for-network() {

	# from here
	# https://bloggenswertes.de/eigene-zone-dns-betreiben/#101einwenigsicherheit

	ETC_BIND_NAMES_ACL="/etc/bind/named.conf.acl"

	echo "# ACTION create $ETC_BIND_NAMES_ACL "

	# network for allow access the named server

	cat <<EOF >"$ETC_BIND_NAMES_ACL"
acl "trusted" {
       127.0.0.0/8;
       $NETWORK_AND_WIDE;
};
EOF

	echo "# ACTION add acl file to named.conf"

	echo "include \"$ETC_BIND_NAMES_ACL\";" | sudo tee -a "/etc/bind/named.conf"

	# allow-recursion { trusted; };
	echo "# ACTION append entry in $ZONE_FILE_NAME_OPTIONS "
	#sed -i '/#ACL settings/a allow-recursion { trusted; };' $ZONE_FILE_NAME_OPTIONS

	# options {
	sed -i '/options {/a allow-recursion { trusted; };' $ZONE_FILE_NAME_OPTIONS

}

# call function
set-acl-for-network

# call function
check-named-conf

function run-bind9() {

	echo "# ACTION start bind9 "

	if (sudo service bind9 start); then
		echo "# INFO bind9 started"
	else
		echo "# ERROR bind9 start raise a error"
		echo "# INFO Look at cat /var/log/syslog for hits and errors"
		echo "# EXIT 1"
		exit 1
	fi

}

# call function
run-bind9

function check-function-bind-server() {

	echo "# INFO BIND server check function"
	if (dig heise.de @127.0.0.1); then
		echo "# INFO server resolv address successful "
	else
		echo "# ERROR address lookup raise a error"
		echo "# INFO Look at cat /var/log/syslog for hits and errors"
		echo "# EXIT 1"
		exit 1
	fi

	echo "# ACTION stop server"

	if (sudo service bind9 stop); then
		echo "# INFO bind9 stop"
	else
		echo "# ERROR bind9 stop raise a error"
		echo "# INFO Look at cat /var/log/syslog for hits and errors"
		echo "# EXIT 1"
		exit 1
	fi

	echo "# INFO Fail test BIND server check function"
	if ! (dig heise.de @127.0.0.1); then
		echo "# INFO Ok server not resolv address successful "
		echo "# INFO server should down"
	else
		echo "# ERROR address lookup works without running a server that is a error"
		echo "# ERROR check which server resolv this address"
		echo "# EXIT 1"
		exit 1
	fi

	echo "# ACTION start bind9 "

	if (sudo service bind9 start); then
		echo "# INFO bind9 started"
	else
		echo "# ERROR bind9 start raise a error"
		echo "# INFO Look at cat /var/log/syslog for hits and errors"
		echo "# EXIT 1"
		exit 1
	fi

	echo "# INFO BIND server check function 2nd Pass"
	if (dig heise.de @127.0.0.1); then
		echo "# INFO server resolv address successful "
	else
		echo "# ERROR address lookup raise a error"
		echo "# INFO Look at cat /var/log/syslog for hits and errors"
		echo "# EXIT 1"
		exit 1
	fi

}

check-function-bind-server

# https://www.nowiasz.de/anleitungen/automatisierte-lets-encrypt-wildcardzertifikate-mit-lokalem-bind/

function add-record-to-bind() {

	echo "# INFO add record to bind"

	# curl -X DELETE -H 'Content-Type: application/json' -H 'X-Api-Key: secret' -d '{ "hostname": "host.example.com"}' http://localhost:9999/dns
	# curl -X POST -H 'Content-Type: application/json' -H 'X-Api-Key: secret' -d '{ "hostname": "host.example.com", "ip": "1.1.1.10" }' http://localhost:9999/dns
	# curl -X POST -H 'Content-Type: application/json' -H 'X-Api-Key: secret' -d '{ "hostname": "host.example.com", "ip": "1.1.1.10", "ptr": "yes", "ttl": 86400}' http://localhost:9999/dns

	# https://github.com/jvdiago/bind-restapi

}

function parse-rndc-key-to-named-conf() {

	# from here
	# https://stackoverflow.com/questions/32588469/how-do-i-get-multi-line-string-between-two-braces-containing-a-specific-search-s

	# sed '/{/{:1; /}/!{N; b1}; /event/p}; d' filepath

	# /{/                    if current line contains{then execute next block
	# {                       start block
	#     :1;                 label for code to jump to
	#     /}/!                if the line does not contain}then execute next block
	#     {                   start block
	#         N;              add next line to pattern space
	#         b1              jump to label 1
	#     };                  end block
	#     /event/p            if the pattern space contains the search string, print it
	#                         (at this point the pattern space contains a full block of lines
	#                         from{to})
	# };                      end block
	# d                       delete pattern space

	# 1st try
	# sed '/#.*key.*"rndc-key".*{/{:1; /}/!{N; b1}; /secret/p}; d' /etc/bind/rndc.conf

	# 2nd try
	sed '/#.*key.*"rndc-key".*{/{:1; /}/!{N; b1}; /.*/p}; d' /etc/bind/rndc.conf | sed 's/^# //g'

	sed '/#.*controls.*{/{:1; /#\W};/!{N; b1}; /.*/p}; d' /etc/bind/rndc.conf

}

# call function
# Move to documentation
# only for documentation parse-rndc-key-to-named-conf

function rndc-create-zone() {

	echo "# DOCUMENTATION"
	# from here
	# http://web.mit.edu/rhel-doc/4/RH-DOCS/rhel-rg-de-4/s1-bind-rndc.html

	# and

	# from here
	# https://github.com/int0x80/notes/wiki/Linux:-Dynamic-DNS-with-BIND-and-DNSSEC

	# and

	# http://jon.netdork.net/2008/08/21/bind-dynamic-zones-and-updates/

	# and

	# https://jpmens.net/2010/10/04/dynamically-add-zones-to-bind-with-rndc-addzone/

	# bind with couch
	# https://jpmens.net/2010/10/06/serving-dns-replies-from-a-couchdb-database-with-the-bind-name-server/

	# rndc addzone exampleb.xx in internal  '{type master; file "master/example.aa"; allow-update{ key "proxy-key";};};'

	nsupdate -y

	# https://unix.stackexchange.com/questions/132171/how-can-i-add-records-to-the-zone-file-without-restarting-the-named-service

	# ESDSA
	# https://www.cloudflare.com/dns/dnssec/ecdsa-and-dnssec/

	# view
	# view
	# view
	# see here
	# https://pupeno.com/2006/02/20/two-in-one-dns-server-with-bind9/

}

function check-compiling-and-linking-with-same-openssl-version() {

	echo "# ACTION check openssl compile and linking version"

	# /usr/sbin/named -V

	# openSSL FAQ
	# https://www.openssl.org/docs/faq.html

}

# call function
check-compiling-and-linking-with-same-openssl-version

function call-bind-version-via-dig() {

	BIND_VERSION=$(dig +short chaos txt version.bind @localhost)

	echo "# INfO Bind version $BIND_VERSION"
}

# call version
call-bind-version-via-dig

function test-nsupdate() {

	# mainly from here
	# https://unix.stackexchange.com/questions/132171/how-can-i-add-records-to-the-zone-file-without-restarting-the-named-service

	# https://ftp.isc.org/isc/dnssec-guide/dnssec-guide.pdf
	# https://hitco.at/blog/wp-content/uploads/Sicherer-E-Mail-Dienste-Anbieter-DNSSecDANE-HowTo-2016-04-28.pdf

	# create key for nsupdate

	# Attention from dnssec-keygen
	# In prior releases, HMAC algorithms could be generated for use as TSIG keys, but that feature has been removed as of
	# BIND 9.13.0. Use tsig-keygen to generate TSIG keys.
	# dnssec-keygen -a RSASHA1 -b 1024 test.me
	#

	TSIG_KEY_NAME="example.com."
	ETC_BIND_TSIG_FILE="/etc/bind/tsig.key"

	# create TSIG Key
	tsig-keygen $TSIG_KEY_NAME | sudo tee $ETC_BIND_TSIG_FILE

	ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE="/etc/bind/example.com.conf"
	ETC_BIND_EXAMPLE_ZONE_PATH="/etc/bind"
	ETC_BIND_EXAMPLE_ZONE_FILE="example.com.zone"

	# create zone file
	cat <<EOF >"$ETC_BIND_EXAMPLE_ZONE_PATH/$ETC_BIND_EXAMPLE_ZONE_FILE"
; example.com
\$TTL    604800
@       IN      SOA     ns1.example.com. root.example.com. (
                     2006020201 ; Serial
                         604800 ; Refresh
                          86400 ; Retry
                        2419200 ; Expire
                         604800); Negative Cache TTL
;
@       IN      NS      ns1
        IN      MX      10 mail
        IN      A       192.0.2.1
EOF

	# create ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE

	# 1st write key

	cat "$ETC_BIND_TSIG_FILE" | tee "$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"

	# 2nd write zone config
	cat <<EOF >>"$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"
zone "example.com" IN {
     type master;
     file "$ETC_BIND_EXAMPLE_ZONE_FILE";
     allow-update{ key "$TSIG_KEY_NAME"; };
};
EOF

	# call nsupdate

	NSUPDATE_ADD_HOST_SCRIPT="$HOME/nsupdate_add_hopst.sh"

	cat <<EOF >"$NSUPDATE_ADD_HOST_SCRIPT"
#!/bin/bash
#Defining Variables
DNS_SERVER="localhost"
DNS_ZONE="example.com."
USERNAME="dd2.example.com."
IP="192.168.1.7"
TTL="60"
RECORD=" $USER_NAME $TTL A $IP"
echo "
server $DNS_SERVER
zone $DNS_ZONE
debug
update add $RECORD
show
send" | nsupdate -k Kexample.com.+157+55566.key
EOF

	# execute script NSUPDATE_ADD_HOST_SCRIPT

	chown +x $HOME/nsupdate_add_hopst.sh
	#$HOME/nsupdate_add_hopst.sh

}

# call function
test-nsupdate

function check-dnssec-is-in-action() {

	# from here
	# https://hitco.at/blog/wp-content/uploads/Sicherer-E-Mail-Dienste-Anbieter-DNSSecDANE-HowTo-2016-04-28.pdf
	# kapitel 2.3.4

	dig @localhost www.isc.org. A +dnssec +multiline

}
