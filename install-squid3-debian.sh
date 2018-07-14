#!/bin/bash

# from here
# http://www.tonmann.com/2015/04/compile-squid-3-5-x-under-debian-jessie/

SQUID_TAR="squid-3.5.27.tar.gz"
SQUID_VERSION=$(${SQUID_TAR} | sed 's/.tar.gz//g')

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

./configure --build=x86_64-linux-gnu \
	--prefix=/usr \
	--includedir=${prefix}/include \
	--mandir=${prefix}/share/man \
	--infodir=${prefix}/share/info \
	--sysconfdir=/etc \
	--localstatedir=/var \
	--libexecdir=${prefix}/lib/squid3 \
	--srcdir=. \
	--disable-maintainer-mode \
	--disable-dependency-tracking \
	--disable-silent-rules \
	--datadir=/usr/share/squid3 \
	--sysconfdir=/etc/squid3 \
	--mandir=/usr/share/man \
	--enable-inline \
	--disable-arch-native \
	--enable-async-io=8 \
	--enable-storeio=ufs,aufs,diskd,rock \
	--enable-removal-policies=lru,heap \
	--enable-delay-pools \
	--enable-cache-digests \
	--enable-icap-client \
	--enable-follow-x-forwarded-for \
	--enable-auth-basic=DB,fake,getpwnam,LDAP,NCSA,NIS,PAM,POP3,RADIUS,SASL,SMB \
	--enable-auth-digest=file,LDAP \
	--enable-auth-negotiate=kerberos,wrapper \
	--enable-auth-ntlm=fake,smb_lm \
	--enable-external-acl-helpers=file_userip,kerberos_ldap_group,LDAP_group,session,SQL_session,unix_group,wbinfo_group \
	--enable-url-rewrite-helpers=fake \
	--enable-eui \
	--enable-esi \
	--enable-icmp \
	--enable-zph-qos \
	--enable-ecap \
	--disable-translation \
	--with-swapdir=/var/spool/squid3 \
	--with-logdir=/var/log/squid3 \
	--with-pidfile=/var/run/squid3.pid \
	--with-filedescriptors=65536 \
	--with-large-files \
	--with-default-user=proxy \
	--enable-ssl \
	–with-openssl \
	--enable-ssl-crtd \
	--enable-linux-netfilter \
	'CFLAGS=-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wall' \
	'LDFLAGS=-fPIE -pie -Wl,-z,relro -Wl,-z,now' \
	'CPPFLAGS=-D_FORTIFY_SOURCE=2' \
	'CXXFLAGS=-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security'

make && make install
