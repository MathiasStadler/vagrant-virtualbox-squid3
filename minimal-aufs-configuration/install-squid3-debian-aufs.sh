#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# import project variables
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; else
	echo "# OK WORK DIR => $PWD"
fi

# SETTINGS_DIR="${DIR}/settings"
SETTINGS_DIR="../../settings"
if [[ ! -d "$SETTINGS_DIR" ]]; then
	echo "# ERROR SETTINGS_DIRECTORY NOT found => $SETTINGS_DIR"

else
	echo "# OK settings dir $SETTINGS_DIR"
fi

# SETTINGS_DIR="${DIR}/settings"
SETTINGS_DIR="$HOME/settings"
if [[ ! -d "$SETTINGS_DIR" ]]; then
	echo "# ERROR SETTINGS_DIRECTORY NOT found => $SETTINGS_DIR"
	echo "# EXIT 1"
	exit 1

else
	echo "# OK SETTINGS_DIRECTORY => $SETTINGS_DIR"
fi

# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/ccache-handling-debian.sh"

# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/squid_version.sh"

# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/squid-handling-debian.sh"

# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/compare_package_list.sh"

# squid configuration
# https://wiki.squid-cache.org/SquidFaq/ConfiguringSquid

# minimal 3.5 config
# https://wiki.squid-cache.org/SquidFaq/ConfiguringSquid#Squid-3.5_default_config
SQUID_CONF="/home/vagrant/squid.conf"

function squid-create-conf() {

	cat <<EOF >"${SQUID_CONF}"
#
# Recommended minimum configuration:
#

# Example rule allowing access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
acl localnet src 10.0.0.0/8     # RFC1918 possible internal network
acl localnet src 172.16.0.0/12  # RFC1918 possible internal network
acl localnet src 192.168.0.0/16 # RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

#
# Recommended minimum Access Permission configuration:
#
# Deny requests to certain unsafe ports
http_access deny !Safe_ports

# Deny CONNECT to other than secure SSL ports
http_access deny CONNECT !SSL_ports

# Only allow cachemgr access from localhost
http_access allow localhost manager
http_access deny manager

# We strongly recommend the following be un commented to protect innocent
# web applications running on the proxy server who think the only
# one who can access services on "localhost" is a local user
#http_access deny to_localhost

#
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
#

# Example rule allowing access from your local networks.
# Adapt localnet in the ACL section to list your (internal) IP networks
# from where browsing should be allowed
http_access allow localnet
http_access allow localhost

# And finally deny all other access to this proxy
http_access deny all

# Squid normally listens to port 3128
http_port 3128

# Un comment and adjust the following to add a disk cache directory.
#cache_dir ufs /var/cache/squid 100 16 256

# Leave coredumps in the first cache dir
coredump_dir /var/cache/squid

#
# Add any of your own refresh_pattern entries above these.
#
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
EOF

	# check ${SQUID_CONF} is wrote
	if [ -e "${SQUID_CONF}" ]; then
		echo "ok file ${SQUID_CONF} wrote"
	else
		echo " file NOT ‚${SQUID_CONF} avaible"
		exit 1
	fi

}

function squid-prepare-package-list() {
	INSTALL_PACKAGE_ADD_ON="install-package-add-on.list"

	cat <<EOF >${INSTALL_PACKAGE_ADD_ON}
build-essential
curl
# test not need wget
g++
EOF

}

function squid-prepare-default-config() {

	# set prefix squid installation
	PREFIX="/usr"

	# from here
	# https://www.linuxjournal.com/content/bash-arrays
	array_configure_options=(
		"--prefix=${PREFIX}"
		"--localstatedir=/var"
		"--libexecdir=${PREFIX}/lib/squid"
		"--datadir=${PREFIX}/share/squid"
		"--sysconfdir=/etc/squid"
		"--with-default-user=proxy"
		"--with-logdir=/var/log/squid"
		"--with-pidfile=/var/run/squid.pid"
	)
}

function squid-add-one-config() {
	# only autoconf config for this use case
	array_add_one_configure_options=("--enable-storeio=aufs,ufs")

}

function squid-install-packages() {

	save_package_list_for_compare "package_list_before_install"

	export DEBIAN_FRONTEND=noninteractive &&
		TERM=linux &&
		sudo apt-get update &&
		sudo apt-get upgrade -y &&
		sudo apt-get autoremove -y

	# shellcheck disable=1072,2046
	sudo apt-get install -y --no-install-recommends $(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#/d' ${INSTALL_PACKAGE_ADD_ON})

	# save list
	save_package_list_for_compare "package_list_after_install"

}

# import from ../settings/squid_download
# squid_download_and_extract

function swap_off() {
	# swapoff it is virtual box
	# swapoff all swap area
	sudo swapoff -a
}

function squid-configure() {

	# join arrays array_configure_options + array_add_one_configure_options
	# TODO old only sample UnixShell=("${Unix[@]}" "${Shell[@]}")
	array_final_configure_options=("${array_configure_options[@]}" "${array_add_one_configure_options[@]}")

	cd "/tmp/${SQUID_VERSION}"

	# explain a lot of ./configure flags
	# http://etutorials.org/Server+Administration/Squid.+The+definitive+guide/Chapter+3.+Compiling+and+Installing/3.4+The+configure+Script/

	# standard configure from here
	# https://wiki.squid-cache.org/SquidFaq/CompilingSquid#Debian.2C_Ubuntu
	if (./configure "${array_final_configure_options[@]}"); then

		echo "./configure ${FINAL_AUTOCONF_OPTIONS} run without error"
		# print config.status -config
		echo "config.status --config"
		/tmp/squid-3.5.27/config.status --config

	else

		echo "./configure ${FINAL_AUTOCONF_OPTIONS} raise ERROR"
		exit 1
	fi

}

function squid-make() {

	# calculate cpu count
	NB_CORES=$(grep -c '^processor' /proc/cpuinfo)

	# make
	make -j$((NB_CORES + 2)) -l"${NB_CORES}"

}

function squid-install() {

	# set cache_dir
	# set permission to cache dir
	echo "# Action change permission for cache directory"
	sudo chown proxy:proxy /cache0
	sudo chown proxy:proxy /cache1

	# set rights to /var/log/squid
	sudo chown -R proxy:proxy /var/log/squid

	sudo make install
}

# start squid as daemon
# from here
# http://etutorials.org/Server+Administration/Squid.+The+definitive+guide/Chapter+5.+Running+Squid/5.5+Running+Squid+as+a+Daemon+Process/

function squid-get-version() {
	# print version
	echo "# Info Version of squid"
	sudo /usr/sbin/squid -v -f "${SQUID_CONF}"
}

function squid-parse-config() {
	# check/parse  config
	echo " parse config ${SQUID_CONF}"
	sudo /usr/sbin/squid -k parse -f "${SQUID_CONF}"

}

function squid-start() {
	# start
	echo "start squid"
	sudo /usr/sbin/squid -f "${SQUID_CONF}"
}

# wait for squid
# echo "wait until squid is started"
# sleep 10

function squid-check() {
	# check squid is working (weak test)
	echo "#Action check squid with weak request"
	let count_match=$(curl -vs -vvv -x 127.0.0.1:3128 google.com 2>&1 | grep -c -i "${SQUID_VERSION_STRING}")
	echo $count_match
	if [ "$count_match" -gt "0" ]; then

		echo "# Ok squid works"
	else

		echo "# ERROR squid NOT works"
		echo "# Exit 1"
		exit 1
	fi

}

function squid-stop() {
	# stop
	echo "# Action stop squid"
	sudo /usr/sbin/squid -k shutdown -f "${SQUID_CONF}"

	# wait until squid is really stop

	## find pid of squid
	# SC2009
	# SQUID_PID=$(ps auxww | grep "$*" | grep -v grep | grep /usr/sbin/squid | awk '{print $2}')
	# improved
	# TODO old echo "# Info  PID of squid process"
	SQUID_PID="$(pgrep -a squid | grep /usr/sbin/squid | awk '{print $1}')"

	# TODO old echo "the pid of squid is => ${SQUID_PID}"

	echo "# INFO PID of squid is => ${SQUID_PID}"

	# TODO old
	## print process for debug
	# pgrep "$SQUID_PID"

	## wait until the thread is finish
	# TODO old echo "#WAIT until squid stop"
	while ps -p "$SQUID_PID" >/dev/null; do
		echo "# WAIT for stop squid PID=${SQUID_PID} "
		sleep 1
	done

}

function squid-add-use-case-config() {

	# append cache_dir entry to ${SQUID_CONF}
	echo "# ACTION Add use case config to ${SQUID_CONF}"
	echo "cache_dir aufs /cache0 7000 16 256" | sudo tee -a "${SQUID_CONF}"
	echo "cache_dir aufs /cache1 7000 16 256" | sudo tee -a "${SQUID_CONF}"

}

function squid-create-cache-structure() {
	# create cache_dir structure
	echo "# ACTION create cache structure"
	sudo /usr/sbin/squid -z -f "${SQUID_CONF}"
}

# start squid again
# start
# echo "start squid again"
# sudo /usr/sbin/squid -f "${SQUID_CONF}"

# wait for squid
# echo "wait for squid"
# sleep 10

# check squid is working (weak test)
# echo "check squid is working via request (weak test)"
# let count_match=$(curl -vs -vvv -x 127.0.0.1:3128 google.com 2>&1 | grep -c -i "${SQUID_VERSION_STRING}")
# echo $count_match
# if [ "$count_match" -gt "0" ]; then

#	echo "squid works with cache_dir"
#else

#	echo "squid NOT works with cache_dir"
#	exit 1
# fi

# finish
# echo "works"
# exit 0

# check ccache
ccache-is-in-place

# main loop squid

squid-create-conf
squid-prepare-package-list
squid-prepare-default-config
squid-add-one-config
squid-install-packages
squid-download-and-extract "/tmp"
squid-make
squid-install
squid-get-version
squid-parse-config
squid-start
squid-check
squid-stop
squid-add-use-case-config
squid-create-cache-structure
