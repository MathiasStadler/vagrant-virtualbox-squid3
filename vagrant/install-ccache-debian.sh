#!/bin/bash

CCACHE_TAR="ccache-3.4.2.tar.gz"
CCACHE_VERSION=${CCACHE_TAR//.tar.gz/}
# shellcheck disable=SC2034
CCACHE_VERSION_STRING=${SQUID_VERSION//-//}

curl https://www.samba.org/ftp/ccache/${CCACHE_TAR} -o /tmp/${CCACHE_TAR}

# un compress:

tar -zxvf /tmp/${CCACHE_TAR}

# Enter folder:

cd ${CCACHE_VERSION} || exit 1

# To compile and install ccache, run these commands:

./configure

NB_CORES=$(grep -c '^processor' /proc/cpuinfo)
make -j$((NB_CORES + 2)) -l"${NB_CORES}"
make install

# change permission for pre load via scp
chown -R vagrant:vagrant /root/.ccache
chmod 0660 /root/.cache

# Create symbol link for ccache

cp ccache /usr/local/bin/
cd /usr/local/bin/ || exit 1
ln -s ccache /usr/local/bin/gcc
ln -s ccache /usr/local/bin/g++
ln -s ccache /usr/local/bin/cc
ln -s ccache /usr/local/bin/c++
