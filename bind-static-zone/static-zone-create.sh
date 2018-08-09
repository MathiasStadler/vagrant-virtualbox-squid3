#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# shellcheck disable=SC1091
source ../settings/utility-bash.sh

# call function
ensure-sudo

# shellcheck disable=SC1091
source ./static-zone-parameter.sh

# shellcheck disable=SC1091
source ../settings/utility-dns-debian.sh

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

	echo "# ACTION create key $DDNS_KEY_NAME"
	# create DDNS Key
	"$BIND_BINARY_DEFAULT_PATH"/ddns-confgen -z "$DDNS_TEST_ZONE" -k "$DDNS_KEY_NAME" | $SUDO tee "$ETC_BIND_DDNS_FILE"

	echo "# ACTION create $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"

	# parse key section
	# and  write key to $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE at first entry
	sed '/key.*".*".*{/{:1; /};/!{N; b1}; /.*/p}; d' "$ETC_BIND_DDNS_FILE" | $SUDO tee "$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"

	# 2nd write zone config
	# TODO old check delete $SUDO cat <<EOF >>"$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"
	$SUDO tee -a "$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE" <<EOF
zone "$DDNS_TEST_ZONE" IN {
     type master;
     file "$ETC_BIND_EXAMPLE_ZONE_FILE";
EOF

	# parse update-policy section and write to $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE
	sed '/update-policy.*{/{:1; /};/!{N; b1}; /.*/p}; d' "$ETC_BIND_DDNS_FILE" | $SUDO tee -a "$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"

	# close $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE
	# TODO old cat <<EOF >>"$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"
	$SUDO tee -a "$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE" <<EOF
};
EOF

	# parse key section
	# write to $ETC_BIND_DDNS_NSUPDATE_FILE for nsupdate command
	sed '/key.*".*".*{/{:1; /};/!{N; b1}; /.*/p}; d' "$ETC_BIND_DDNS_FILE" | $SUDO tee "$ETC_BIND_DDNS_NSUPDATE_FILE"

	echo "# ACTION create $ETC_BIND_EXAMPLE_ZONE_FILE"

	# create $ETC_BIND_EXAMPLE_ZONE_FILE file
	# old $SUDO cat <<EOF >"$ETC_BIND_EXAMPLE_ZONE_FILE"
	$SUDO tee -a "$ETC_BIND_EXAMPLE_ZONE_FILE" <<EOF
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

	NAMED_CONF_NEW_ZONE_INCLUDED="include \"$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE\";"

	# check first entry available already
	if (grep "$NAMED_CONF_NEW_ZONE_INCLUDED" "$ETC_BIND_NAMED_CONF"); then

		echo "# INFO include already inside $ETC_BIND_NAMED_CONF"
		echo "# INFO do nothing"

	else

		echo "# ACTION add  $NAMED_CONF_NEW_ZONE_INCLUDED to $ETC_BIND_NAMED_CONF"

		echo $NAMED_CONF_NEW_ZONE_INCLUDED | $SUDO tee -a "/etc/bind/named.conf"

	fi

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
