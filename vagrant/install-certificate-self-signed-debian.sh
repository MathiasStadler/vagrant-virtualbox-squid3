#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

function create-path-and-file() {

	mkdir -p /etc/squid/ssl_cert

	chown -R squid:squid /etc/squid/ssl_cert

	# TODO not needed
	# cd /etc/squid/ssl_cert

}

# call function
create-path-and-file

function prepare-openssl-conf() {

	OPENSSL_CONF="/etc/pki/tls/openssl.conf"

	cat <<EOF >"$OPENSSL_CONF"


default_days    = 1365           # How long to certify for
...

[ req_distinguished_name ]
countryName                     = Country Name (code)
countryName_default             = DE
countryName_min                 = 2
countryName_max                 = 2

stateOrProvinceName             = State or Province Name (full name)
stateOrProvinceName_default     = NRW

localityName                    = Locality Name (eg, city)
localityName_default            = Paderborn

0.organizationName              = Organization Name (eg, company)
0.organizationName_default      = Home.LAN

# we can do this but it is not needed normally :-)
#1.organizationName             = Second Organization Name (eg, company)
#1.organizationName_default     = World Wide Web Pty Ltd

organizationalUnitName          = Organizational Unit Name (eg, section)
organizationalUnitName_default  = Proxy Server

commonName                      = Common Name (eg, your name or your server's hostname)
# (Very Important, in order to keep mail clients and other user agents from complaining, this name must
# match exactly the name that the user will be entering into their client settings.  Whether that be
# domain.extension or mail.domain.extension or what.  It must be a valid DNS name pointing at your
# server.
commonName_default              = proxy.home.lan   # this line you need to add
commonName_max                  = 64

emailAddress                    = Email Address
emailAddress_default            = admin@proxy.home.lan  # this line you need to add
emailAddress_max                = 64

EOF

}

# call function
prepare-openssl-conf

function create-certificate-self-signed() {

	echo "# INFO create certificate"

	openssl req -new -newkey rsa:1024 -days 1365 -nodes -x509 -keyout myca.pem -out myca.pem

}

# call function
create-certificate-self-signed
