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

make && make install

# squid configuration
# https://wiki.squid-cache.org/SquidFaq/ConfiguringSquid

# minimal 3.5 config
# https://wiki.squid-cache.org/SquidFaq/ConfiguringSquid#Squid-3.5_default_config
