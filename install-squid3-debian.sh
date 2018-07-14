#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# from here
# http://www.tonmann.com/2015/04/compile-squid-3-5-x-under-debian-jessie/

SQUID_TAR="squid-3.5.27.tar.gz"
SQUID_VERSION=${SQUID_TAR//.tar.gz/}
echo ${SQUID_VERSION}

export DEBIAN_FRONTEND=noninteractive TERM=linux &&
	apt-get update && apt-get upgrade -y && apt-get autoremove -y &&
	apt-get install -y openssl \
		build-essential \
		libssl-dev \
		curl \
		build-essential \
		libfile-fcntllock-perl
# libfile-fcntllock-perl required for
#dpkg-gencontrol: warning: File::FcntlLock not available; using flock which is not NFS-safe

curl http://www.squid-cache.org/Versions/v3/3.5/${SQUID_TAR} -o /tmp/${SQUID_TAR}

tar xzf /tmp/${SQUID_TAR} -C /tmp

cd /tmp/${SQUID_VERSION}

# explain a lot of ./configure flags
# http://etutorials.org/Server+Administration/Squid.+The+definitive+guide/Chapter+3.+Compiling+and+Installing/3.4+The+configure+Script/

# standard configure from here
# https://wiki.squid-cache.org/SquidFaq/CompilingSquid#Debian.2C_Ubuntu
./configure \
	--prefix=/usr \
	--localstatedir=/var \
	--libexecdir=${prefix}/lib/squid \
	--datadir=${prefix}/share/squid \
	--sysconfdir=/etc/squid \
	--with-default-user=proxy \
	--with-logdir=/var/log/squid \
	--with-pidfile=/var/run/squid.pid \
	--enable-linux-netfilter

NB_CORES=$(grep -c '^processor' /proc/cpuinfo)
make -j$((NB_CORES + 2)) -l${NB_CORES}

make install

# squid configuration
# https://wiki.squid-cache.org/SquidFaq/ConfiguringSquid

# minimal 3.5 config
# https://wiki.squid-cache.org/SquidFaq/ConfiguringSquid#Squid-3.5_default_config

cat <<EOF >"squid.conf"
http_port 3128

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
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl Safe_ports port 1025-65535  # unregistered ports

acl CONNECT method CONNECT

http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager

#
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
#

http_access allow localnet
http_access allow localhost
http_access deny all

coredump_dir /squid/var/cache/squid

refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
EOF

# start squid as daemon
# from here
# http://etutorials.org/Server+Administration/Squid.+The+definitive+guide/Chapter+5.+Running+Squid/5.5+Running+Squid+as+a+Daemon+Process/

/usr/local/squid/sbin/squid -sD -f ./squid.conf
