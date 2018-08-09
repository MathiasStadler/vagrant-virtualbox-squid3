#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# shellcheck disable=SC1091
source ./static-zone-parameter.sh

function crete-static-test-zone() {

	echo "# INFO call create-static-test-zone"

	# mainly from here
	# https://unix.stackexchange.com/questions/132171/how-can-i-add-records-to-the-zone-file-without-restarting-the-named-service

	# https://ftp.isc.org/isc/dnssec-guide/dnssec-guide.pdf
	# https://hitco.at/blog/wp-content/uploads/Sicherer-E-Mail-Dienste-Anbieter-DNSSecDANE-HowTo-2016-04-28.pdf

	# create key for nsupdate

	# Attention from dnssec-keygen
	# In prior releases, HMAC algorithms could be generated for use as TSIG keys, but that feature has been removed as of
	# BIND 9.13.0. Use tsig-keygen to generate TSIG keys.
	# dnssec-keygen -a RSASHA1 -b 1024 test.me
	#

	# create DDNS Key
	ddns-confgen -z "$DDNS_TEST_ZONE" -k "$DDNS_KEY_NAME" | sudo tee "$ETC_BIND_DDNS_FILE"

	# parse key section
	# and  write key to $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE at first entry
	sed '/key.*".*".*{/{:1; /};/!{N; b1}; /.*/p}; d' "$ETC_BIND_DDNS_FILE" | sudo tee "$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"

	echo "# ACTION create $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"

	# 2nd write zone config
	cat <<EOF >>"$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"
zone "$DDNS_TEST_ZONE" IN {
     type master;
     file "$ETC_BIND_EXAMPLE_ZONE_FILE";
EOF

	# parse update-policy section and write to $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE
	sed '/update-policy.*{/{:1; /};/!{N; b1}; /.*/p}; d' "$ETC_BIND_DDNS_FILE" | sudo tee -a "$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"

	# close $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE
	cat <<EOF >>"$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"
};
EOF

	# parse key section
	# write to $ETC_BIND_DDNS_NSUPDATE_FILE for nsupdate command
	sed '/key.*".*".*{/{:1; /};/!{N; b1}; /.*/p}; d' "$ETC_BIND_DDNS_FILE" | sudo tee "$ETC_BIND_DDNS_NSUPDATE_FILE"

	echo "# ACTION create $ETC_BIND_EXAMPLE_ZONE_FILE"

	# create $ETC_BIND_EXAMPLE_ZONE_FILE file
	cat <<EOF >"$ETC_BIND_EXAMPLE_ZONE_FILE"
; $DDNS_TEST_ZONE
\$TTL    604800
@       IN      SOA     ns1.$DDNS_TEST_ZONE. root.$DDNS_TEST_ZONE. (
                     2006020201 ; Serial
                         604800 ; Refresh
                          86400 ; Retry
                        2419200 ; Expire
                         604800); Negative Cache TTL
;
@				NS	ns.$DDNS_TEST_ZONE.
ns                     A       127.0.0.1
;END OF ZONE FILE
EOF

	# include $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE to /etc/bind/named.conf
	echo "# ACTION include $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE in /etc/named.conf"
	echo "include \"$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE\";" | sudo tee -a "/etc/bind/named.conf"

	# reload zone
	# call function
	clean-and-sync-all-zone-journals

	echo "# ACTION reload all zones"
	$RNDC_EXEC reload

	# call function
	reload-dynamic-zone "$DDNS_TEST_ZONE"

}

# call function
crete-static-test-zone