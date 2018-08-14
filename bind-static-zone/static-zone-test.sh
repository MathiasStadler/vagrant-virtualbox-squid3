#!/bin/bash

# Exit immediately if a command returns a non-zero status
# set -e
# from here https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

# with print command
# set -Eeuxo pipefail

# without print command
set -Eeuo pipefail

err_report() {
	echo "unexpected error on line $(caller) script exit" >&2
}

trap err_report ERR

SETTINGS="../settings"

# shellcheck disable=SC1090,SC1091
source "$SETTINGS/utility-dns-debian.sh"

echo "# ACTION run test"

# regex from here
# https://stackoverflow.com/questions/15268987/bash-based-regex-domain-name-validation
# last entry

function use-case-add-remove-static-zone() {

	# set variable for each use# generate a 12 char random string
	local DDNS_NAME_SERVER="127.0.0.1"
	# raise pipfail
	#RANDOM_STRING_12=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 12 | head -n 1)
	RANDOM_STRING_12="$(openssl rand -hex 12)"
	local DDNS_ZONE="TEST-${RANDOM_STRING_12}.com"

	if (echo "$DDNS_ZONE" | grep -P "^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\\.[a-zA-Z]{2,})+$"); then
		echo "# INFO domain name $DDNS_ZONE valid"
	else
		echo "# ERROR domain name $DDNS_ZONE no valid "
		echo "# EXIT 1"
		exit 1
	fi

	echo "# ACTION create zone"

	bash -x ./static-zone-create.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE"

	echo "# ACTION delete zone"

	bash -x ./static-zone-delete.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE"

}

function use-case-add-remove-static-zone-and-record() {

	# set variable for each use# generate a 12 char random string
	DDNS_NAME_SERVER="127.0.0.1"
	# RANDOM_STRING_12=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 12 | head -n 1)
	RANDOM_STRING_12="$(openssl rand -hex 12)"
	# RANDOM_STRING_6=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 6 | head -n 1)
	RANDOM_STRING_6="$(openssl rand -hex 6)"
	DDNS_ZONE="TEST-${RANDOM_STRING_12}.com"
	# from here
	# https://unix.stackexchange.com/questions/14666/how-to-generate-random-ip-addresses
	ip_address=$(dd if=/dev/urandom bs=4 count=1 2>/dev/null |
		od -An -tu1 |
		sed -e 's/^ *//' -e 's/  */./g')

	if (echo "$DDNS_ZONE" | grep -P "^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\\.[a-zA-Z]{2,})+$"); then
		echo "# INFO domain name $DDNS_ZONE valid"
	else
		echo "# ERROR domain name $DDNS_ZONE no valid "
		echo "# EXIT 1"
		exit 1
	fi

	echo "# ACTION create zone"
	./static-zone-create.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE"

	echo "# ACTION create record"
	./static-zone-rr-create.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE" "test-host-${RANDOM_STRING_6}" # "$ip_address" "600" "${DDNS_ZONE}_NSUPDATE.key"

	echo "# ACTION delete record"
	./static-zone-rr-delete.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE" "test-host-${RANDOM_STRING_6}" "${DDNS_ZONE}_NSUPDATE.key"

	echo " # ACTION delete zone"
	./static-zone-delete.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE"

}

# call function
use-case-add-remove-static-zone

# call function
use-case-add-remove-static-zone-and-record
