#!/bin/bash

echo "# ACTION run test"

# regex from here
# https://stackoverflow.com/questions/15268987/bash-based-regex-domain-name-validation
# last entry

function use-case-add-remove-static-zone() {

	# set variable for each use# generate a 12 char random string
	local DDNS_NAME_SERVER="127.0.0.1"
	local RANDOM_STRING=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
	local DDNS_ZONE="TEST-${RANDOM_STRING}.com"

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
	local DDNS_NAME_SERVER="127.0.0.1"
	local RANDOM_STRING_12=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
	local RANDOM_STRING_6=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
	local DDNS_ZONE="TEST-${RANDOM_STRING_12}.com"
	# from here
	# https://unix.stackexchange.com/questions/14666/how-to-generate-random-ip-addresses
	local ip_address=$(dd if=/dev/urandom bs=4 count=1 2>/dev/null |
		od -An -tu1 |
		sed -e 's/^ *//' -e 's/  */./g')

	if (echo "$DDNS_ZONE" | grep -P "^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$"); then
		echo "# INFO domain name $DDNS_ZONE valid"
	else
		echo "# ERROR domain name $DDNS_ZONE no valid "
		echo "# EXIT 1"
		exit 1
	fi

	echo "# ACTION create zone"

	bash -x ./static-zone-create.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE"

	echo "# ACTION create record"
	bash -x ./static-zone-rr-create.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE" "test-host-${RANDOM_STRING_6}" "$ip_address" "600"

	echo "# ACTION delete record"
	bash -x ./static-zone-rr-delete.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE" "test-host-${RANDOM_STRING_6}"

	echo " # ACTION delete zone"

	bash -x ./static-zone-delete.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE"

}

# call function
use-case-add-remove-static-zone

# call function
use-case-add-remove-static-zone-and-record
