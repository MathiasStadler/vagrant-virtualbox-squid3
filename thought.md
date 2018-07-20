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

## HTTP Strict Transport Security (HSTS)

## display cache object

```txt
# from here
# https://lists.debian.org/debian-user/1997/05/msg00663.html
#!/usr/bin/perl
     $L1= 16;   # Level 1 directories
     $L2= 256;  # Level 2 directories

     while (<>) {
       $f= hex($_);
       $path= sprintf("%02X/%02X/%08X", $f % $L1, ($f / $L1) % $L2, $f);
       print $path ;
     }
```

## squid configure

```txt
http://www.tonmann.com/2015/04/compile-squid-3-5-x-under-debian-jessie/
```
