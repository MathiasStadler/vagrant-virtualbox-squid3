# thought

company <--> department <--> team/project/CI/CD pipeline

project <--> team <--> developer

company <--> mass cache <--> hot cache <--> session cache

## plain stretch image

without pre install vbox driver

debian/contrib-stretch64

## save

export DEBIAN_FRONTEND=noninteractive &&
TERM=linux &&
apt-get update &&
apt-get upgrade -y &&
apt-get autoremove -y &&
apt-get install -y openssl \
 build-essential \
 libssl-dev \
 curl \
 build-essential \
 libfile-fcntllock-perl

## libfile-fcntllock-perl required for

## dpkg-gencontrol: warning: File::FcntlLock not available; using flock which is not NFS-safe

./configure \
 --prefix=${PREFIX} \
 --localstatedir=/var \
 --libexecdir=${PREFIX}/lib/squid \
 --datadir=${PREFIX}/share/squid \
 --sysconfdir=/etc/squid \
 --with-default-user=proxy \
 --with-logdir=/var/log/squid \
 --with-pidfile=/var/run/squid.pid \
 --enable-linux-netfilter
