#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# import project variables
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; else
	echo "dir found => $PWD"
fi

# TODO ${DIR} = tmp WHY
# SETTINGS_DIR="${DIR}/settings"
SETTINGS_DIR="/home/vagrant/settings"
if [[ ! -d "$SETTINGS_DIR" ]]; then
	echo "SETTINGS directory NOT found => $SETTINGS_DIR"
	exit 1
else
	echo "settings dir found $SETTINGS_DIR"
fi

# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/squid_version.sh"

# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/squid_download.sh"

# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/compare_package_list.sh"

# squid configuration
# https://wiki.squid-cache.org/SquidFaq/ConfiguringSquid

# minimal 3.5 config
# https://wiki.squid-cache.org/SquidFaq/ConfiguringSquid#Squid-3.5_default_config

SQUID_CONF="/home/vagrant/squid.conf"

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

INSTALL_PACKAGE_ADD_ON="install_package_add_on.list"

cat <<EOF >${INSTALL_PACKAGE_ADD_ON}
build-essential
curl
# test not need wget
g++
EOF

# TODO old remove

# AUTOCONF_CONFIGURE="autoconf_configure.sh"

# cat <<EOF >${AUTOCONF_CONFIGURE}
# ./configure \
# 	--prefix=${PREFIX} \
# 	--localstatedir=/var \
# 	--libexecdir=${PREFIX}/lib/squid \
# 	--datadir=${PREFIX}/share/squid \
# 	--sysconfdir=/etc/squid \
# 	--with-default-user=proxy \
# 	--with-logdir=/var/log/squid \
# 	--with-pidfile=/var/run/squid.pid
# EOF

# set prefix
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

array_add_one_configure_options=("--enable-storeio=aufs,ufs"
	"--enable-debug-cbdata")

echo "Number of items in original array_configure_options: ${#array_configure_options[*]}"
for ix in ${!array_configure_options[*]}; do
	printf "   %s\:\n" "${array_configure_options[$ix]}"
done

# join arrays array_configure_options + array_add_one_configure_options
# TODO old only sample UnixShell=("${Unix[@]}" "${Shell[@]}")
array_final_configure_options=("${array_configure_options[@]}" "${array_add_one_configure_options[@]}")

echo "array_final_configure_options => ${array_final_configure_options[@]}"
echo " array_final_configure_options size => ${#array_final_configure_options[@]}"

# from here
# https://stackoverflow.com/questions/1527049/join-elements-of-an-array
separator=" " # e.g. constructing FINAL_AUTOCONF_OPTIONS, pray it does not contain %s
FINAL_AUTOCONF_OPTIONS="$(printf "${separator}%s" "${array_final_configure_options[@]}")"
FINAL_AUTOCONF_OPTIONS="${FINAL_AUTOCONF_OPTIONS:${#separator}}" # remove leading separator
echo "${FINAL_AUTOCONF_OPTIONS}"

# check squid.conf is wrote
if [ -e "${SQUID_CONF}" ]; then
	echo "ok file ${SQUID_CONF} there"
else
	echo " file NOT ‚${SQUID_CONF} there"
	exit 1
fi

exit 0

# from here
# http://www.tonmann.com/2015/04/compile-squid-3-5-x-under-debian-jessie/

echo "${SQUID_VERSION}"
echo "${SQUID_VERSION_STRING}"

save_package_list_for_compare "package_list_before_install"

export DEBIAN_FRONTEND=noninteractive &&
	TERM=linux &&
	sudo apt-get update &&
	sudo apt-get upgrade -y &&
	sudo apt-get autoremove -y
# apt-get install -y --no-install-recommends "$(grep -vE "^\s*#" ${INSTALL_PACKAGE_ADD_ON} | tr "\n" " ")"
# sudo apt-get install -y --no-install-recommends "$(awk '{print $1}' ${INSTALL_PACKAGE_ADD_ON})"
# sudo apt-get install -y --no-install-recommends "$(awk '!/^ *#/ && NF' ${INSTALL_PACKAGE_ADD_ON})"

# shellcheck disable=1072,2046
# sudo apt-get install -y --no-install-recommends $(awk '!/^ *#/ && NF' ${INSTALL_PACKAGE_ADD_ON})
sudo apt-get install -y --no-install-recommends $(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#/d' ${INSTALL_PACKAGE_ADD_ON})

# sudo apt-get install -y --no-install-recommends &&
# build-essential &&
# curl &&
# g++

save_package_list_for_compare "package_list_after_install"

# import from ../settings/squid_download
squid_download_and_extract

cd "/tmp/${SQUID_VERSION}"

# explain a lot of ./configure flags
# http://etutorials.org/Server+Administration/Squid.+The+definitive+guide/Chapter+3.+Compiling+and+Installing/3.4+The+configure+Script/

# standard configure from here
# https://wiki.squid-cache.org/SquidFaq/CompilingSquid#Debian.2C_Ubuntu

# old extends to AUTOCONF_CONFIGURE
# ./configure \
# 	--prefix=${PREFIX} \
# 	--localstatedir=/var \
# 	--libexecdir=${PREFIX}/lib/squid \
# 	--datadir=${PREFIX}/share/squid \
# 	--sysconfdir=/etc/squid \
# 	--with-default-user=proxy \
# 	--with-logdir=/var/log/squid \
# 	--with-pidfile=/var/run/squid.pid

# swapoff it is virtual box
sudo swapoff -a

NB_CORES=$(grep -c '^processor' /proc/cpuinfo)
make -j$((NB_CORES + 2)) -l"${NB_CORES}"
sudo make install

# set rights to /var/log/squid
sudo chown -R proxy:proxy /var/log/squid

# start squid as daemon
# from here
# http://etutorials.org/Server+Administration/Squid.+The+definitive+guide/Chapter+5.+Running+Squid/5.5+Running+Squid+as+a+Daemon+Process/

# print version
sudo /usr/sbin/squid -v -f "${SQUID_CONF}"

# check/parse  config
sudo /usr/sbin/squid -k parse -f "${SQUID_CONF}"

# start
sudo /usr/sbin/squid -f "${SQUID_CONF}"

# wait for squid
sleep 10

# check squid is working (weak test)
let count_match=$(curl -vs -vvv -x 127.0.0.1:3128 google.com 2>&1 | grep -c -i "${SQUID_VERSION_STRING}")
echo $count_match
if [ "$count_match" -gt "0" ]; then

	echo "squid works"
else

	echo "squid NOT works"
	exit 1
fi

# stop
sudo /usr/sbin/squid -k shutdown -f "${SQUID_CONF}"

# wait until squid is really stop

## find pid of squid
# SC2009
# SQUID_PID=$(ps auxww | grep "$*" | grep -v grep | grep /usr/sbin/squid | awk '{print $2}')
# improved
SQUID_PID="$(pgrep -a squid | grep /usr/sbin/squid | awk '{print $1}')"

## print process for debug
pgrep "$SQUID_PID"

## wait until the thread is finish
while ps -p "$SQUID_PID" >/dev/null; do
	echo "# Wait for finish stop squid PID=${SQUID_PID} "
	sleep 1
done

# set cache_dir

# set permission to cache dir
sudo chown proxy:proxy /cache0
sudo chown proxy:proxy /cache1

# append cache_dir entry to squid.conf
echo "cache_dir ufs /cache0 7000 16 256" | sudo tee -a ./squid.conf
echo "cache_dir ufs /cache1 7000 16 256" | sudo tee -a ./squid.conf

# create cache_dir structure
sudo /usr/sbin/squid -z -f ./squid.conf

# start squid again
# start
sudo /usr/sbin/squid -f "${SQUID_CONF}"

# wait for squid
sleep 10

# check squid is working (weak test)
let count_match=$(curl -vs -vvv -x 127.0.0.1:3128 google.com 2>&1 | grep -c -i "${SQUID_VERSION_STRING}")
echo $count_match
if [ "$count_match" -gt "0" ]; then

	echo "squid works with cache_dir"
else

	echo "squid NOT works with cache_dir"
	exit 1
fi
