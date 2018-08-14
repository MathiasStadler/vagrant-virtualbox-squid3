#!/bin/bash

# Exit immediately if a command returns a non-zero status

# with print command
# set -Eeuxo pipefail

# without print command
set -Eeuo pipefail

err_report() {
	echo "unexpected error on line $(caller) script exit" >&2
}

trap err_report ERR

SETTINGS="../settings"

function create-static-zone() {

	# shellcheck disable=SC1090,SC1091
	source "$SETTINGS/bind-parameter.sh"

	# shellcheck disable=SC1090,SC1091
	source "$SETTINGS/utility-bash.sh"

	# shellcheck disable=SC1090,SC1091
	source "$SETTINGS/utility-dns-debian.sh"

	# call function
	ensure-sudo

	# shellcheck disable=SC1090,SC1091
	source ./static-zone-parameter.sh

	# shellcheck disable=SC1090,SC1091
	source "$SETTINGS/utility-dns-debian.sh"

	echo "# INFO call create-static-zone" | tee -a "${LOG_FILE}"
	# ARG1 = DDNS_NAME_SERVER"
	# ARG2 = DDNS_ZONE

	TRUE=0
	FALSE=1

	# Attention parameter count start at 0
	# varName varMessage varNesseccary varDefaultValue
	# bound dynamic
	# shellcheck disable=SC2034
	argument0=("DDNS_NAME_SERVER" "DNS NAME SERVER" "$TRUE" "$FALSE")
	# shellcheck disable=SC2034
	argument1=("DDNS_ZONE" "DNS ZONE for resource record " "$TRUE" "$FALSE")

	# dynamic parameter start couldn't bound
	set +u

	# call function
	provide-dynamic-function-argument "$@"

	# mainly from here
	# https://unix.stackexchange.com/questions/132171/how-can-i-add-records-to-the-zone-file-without-restarting-the-named-service

	# https://ftp.isc.org/isc/dnssec-guide/dnssec-guide.pdf
	# https://hitco.at/blog/wp-content/uploads/Sicherer-E-Mail-Dienste-Anbieter-DNSSecDANE-HowTo-2016-04-28.pdf

	# create key for nsupdate

	# Attention from dnssec-keygen
	# In prior releases, HMAC algorithms could be generated for use as TSIG keys, but that feature has been removed as of
	# BIND 9.13.0. Use tsig-keygen to generate TSIG keys.
	# dnssec-keygen -a RSASHA1 -b 1024 test.me

	DDNS_ZONE_KEY_NAME="$DDNS_ZONE"_KEY
	echo "# ACTION create key $DDNS_ZONE_KEY_NAME"

	ETC_BIND_DDNS_KEY_FILE="$BIND_CONFIG_PATH/${DDNS_ZONE}_DDNS.key"
	echo "# ACTION key file $ETC_BIND_DDNS_KEY_FILE"

	ETC_BIND_DDNS_ZONE_FILE="$BIND_CONFIG_PATH/${DDNS_ZONE}_DDNS.zone"
	echo "# ACTION zone file $ETC_BIND_DDNS_ZONE_FILE"

	ETC_BIND_DDNS_ZONE_CONFIG_FILE="$BIND_CONFIG_PATH/${DDNS_ZONE}_DDNS.conf"
	echo "# ACTION  zone config file $ETC_BIND_DDNS_ZONE_CONFIG_FILE"

	# Step 1st create DDNS Key
	"$BIND_BINARY_DEFAULT_PATH"/ddns-confgen -z "$DDNS_ZONE" -k "$DDNS_KEY_NAME" | $SUDO tee "$ETC_BIND_DDNS_KEY_FILE"

	echo "# ACTION create $ETC_BIND_DDNS_ZONE_CONFIG_FILE"

	# Ste 2nd parse key section
	# and  write key to $ETC_BIND_DDNS_ZONE_CONFIG_FILE at first entry
	sed '/key.*".*".*{/{:1; /};/!{N; b1}; /.*/p}; d' "$ETC_BIND_DDNS_KEY_FILE" | $SUDO tee "$ETC_BIND_DDNS_ZONE_CONFIG_FILE"

	# step 3rd  write zone config
	$SUDO tee "$ETC_BIND_DDNS_ZONE_CONFIG_FILE" <<EOF
zone "$DDNS_TEST_ZONE" IN {
     type master;
     file "$ETC_BIND_DDNS_ZONE_FILE";
EOF

	# step 4 parse update-policy section and write to $ETC_BIND_DDNS_ZONE_CONFIG_FILE
	sed '/update-policy.*{/{:1; /};/!{N; b1}; /.*/p}; d' "$ETC_BIND_DDNS_KEY_FILE" | $SUDO tee -a "$ETC_BIND_DDNS_ZONE_CONFIG_FILE"

	# step 5 close $ETC_BIND_DDNS_ZONE_CONFIG_FILE
	$SUDO tee -a "$ETC_BIND_DDNS_ZONE_CONFIG_FILE" <<EOF
};
EOF

	# create $ETC_BIND_DDNS_NSUPDATE_FILE for rndc and nsupdate
	# parse key section and
	# write to $ETC_BIND_DDNS_NSUPDATE_FILE for nsupdate command
	echo "# ACTION create $ETC_BIND_DDNS_NSUPDATE_FILE"
	sed '/key.*".*".*{/{:1; /};/!{N; b1}; /.*/p}; d' "$ETC_BIND_DDNS_KEY_FILE" | $SUDO tee "$ETC_BIND_DDNS_NSUPDATE_FILE"

	# create file
	echo "# ACTION create $ETC_BIND_DDNS_ZONE_FILE"
	$SUDO tee "$ETC_BIND_DDNS_ZONE_FILE" <<EOF
; $DDNS_ZONE
\$TTL    604800
@       IN      SOA     ns1.$DDNS_ZONE. root.$DDNS_ZONE. (
                     2006020201 ; Serial
                         604800 ; Refresh
                          86400 ; Retry
                        2419200 ; Expire
                         604800); Negative Cache TTL
;
@				NS	ns.$DDNS_ZONE.
ns                     A       $DDNS_NAME_SERVER
;END OF ZONE FILE
EOF

	# include $ETC_BIND_DDNS_ZONE_CONFIG_FILE to /etc/bind/named.conf
	echo "# ACTION include $ETC_BIND_DDNS_ZONE_CONFIG_FILE in $ETC_BIND_NAMED_CONF"

	# prepare include
	NAMED_CONF_NEW_ZONE_INCLUDED=("include" "\"$ETC_BIND_DDNS_ZONE_CONFIG_FILE\"" ";")

	# check first entry available already
	# ATTENTION we grep here for the name of include file
	if (grep "${NAMED_CONF_NEW_ZONE_INCLUDED[1]}" "$ETC_BIND_NAMED_CONF"); then
		echo "# INFO include ${NAMED_CONF_NEW_ZONE_INCLUDED[*]} already inside $ETC_BIND_NAMED_CONF"
		echo "# INFO nothing to do in this case"
	else
		echo "# INFO include not found in $ETC_BIND_NAMED_CONF"
		echo "# ACTION add  ${NAMED_CONF_NEW_ZONE_INCLUDED[*]} to $ETC_BIND_NAMED_CONF"
		echo "${NAMED_CONF_NEW_ZONE_INCLUDED[*]}" | $SUDO tee -a "/etc/bind/named.conf"
	fi

	# call function
	check-named-conf

	# call function
	clean-and-sync-all-zone-journals

	echo "# ACTION reload bind with all zones"
	$RNDC_EXEC reload

	# call function
	reload-dynamic-zone "$DDNS_TEST_ZONE"
}

function usages() {
	echo "# Usages: ${0##*/} ddns-name-server ddns-domain"
	echo "# "
}

# main task
if [ "$#" -lt "2" ]; then
	echo "# ERROR less parameter"
	usages
	exit 1
fi
if [ "$#" -gt "2" ]; then
	echo "# ERROR to many parameter"
	usages
	exit 1
fi
if [ "$#" -eq "2" ]; then
	create-static-zone "$@"
	exit 0
fi

# call function
# crete-static-zone "127.0.0.1" "example.com"
