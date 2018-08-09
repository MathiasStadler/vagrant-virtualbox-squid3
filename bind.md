# bind

## sources

```bash
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

#  master zone template
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
```

## compile

```bash
function check-compiling-and-linking-with-same-openssl-version() {

echo "# ACTION check openssl compile and linking version"

# /usr/sbin/named -V

# openSSL FAQ
# https://www.openssl.org/docs/faq.html

}

# call function
check-compiling-and-linking-with-same-openssl-version
```
