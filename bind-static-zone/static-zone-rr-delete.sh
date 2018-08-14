#!/bin/bash

#!/bin/bash
# script create rr in static zone
# https://de.wikipedia.org/wiki/Resource_Record

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

function delete-record() {

	# shellcheck disable=SC1090,SC1091
	source "$SETTINGS/utility-bash.sh"

	# shellcheck disable=SC1090,SC1091
	source "$SETTINGS/utility-dns-debian.sh"

	# call function
	ensure-sudo

	echo "# INFO call delete-record" | tee -a "${LOG_FILE}"

	# ARG1 = DDNS_NAME_SERVER"
	# ARG2 = DDNS_ZONE
	# ARG3 = RR_HOST_ADDRESS
	# ARG4 = RR_IP_OF_HOST
	# ARG5 = TTL

	TRUE=0
	FALSE=1

	# Attention parameter count start at 0
	# varName varMessage varNesseccary varDefaultValue
	# bound dynamic
	# shellcheck disable=SC2034
	argument0=("DDNS_NAME_SERVER" "DNS NAME SERVER" "$TRUE" "$FALSE")
	# shellcheck disable=SC2034
	argument1=("DDNS_ZONE" "DNS ZONE for resource record " "$TRUE" "$FALSE")
	# shellcheck disable=SC2034
	argument2=("RR_HOST_ADDRESS" "Name of host" "$TRUE" "$FALSE")
	# shellcheck disable=SC2034
	argument3=("DDNS_ZONE_KEY_FILE" "Key file tzo access the zone" "$TRUE" "$FALSE")

	# dynamic parameter start couldn't bound
	set +u

	# call function
	provide-dynamic-function-argument "$@"

	# check record is available
	if (dig "$RR_HOST_ADDRESS.$DDNS_ZONE" @"$DDNS_NAME_SERVER" | grep "ANSWER SECTION"); then
		echo "# OK zone $RR_HOST_ADDRESS in zone $DDNS_ZONE available"
		echo "# ACTION try to delete"
	else
		echo "# HOPPLA zone $RR_HOST_ADDRESS in zone $DDNS_ZONE not available"
		echo "# EXIT 0 "
		exit 1
	fi

	echo "# INFO DDNS_NAME_SERVER $DDNS_NAME_SERVER"

	if (
		echo "
server $DDNS_NAME_SERVER
zone $DDNS_ZONE
debug
update delete $RR_HOST_ADDRESS.$DDNS_ZONE A
show
send" | nsupdate -k "$DDNS_ZONE_KEY_FILE"
	); then
		echo "# OK"
	else
		echo "# ERROR"
	fi

	echo "# ACTION reload zone $DDNS_ZONE"
	reload-dynamic-zone "$DDNS_ZONE"

	# dynamic parameter end
	set -u

}

function usages() {
	echo "# Usages: ${0##*/} ddns-name-server ddns-domain host"
	echo "# "
}

# main task
if [ "$#" -lt "3" ]; then
	echo "# ERROR less parameter"
	usages
	exit 1
fi
if [ "$#" -gt "3" ]; then
	echo "# ERROR to many parameter"
	usages
	exit 1
fi
if [ "$#" -eq "3" ]; then
	delete-record "$@"
	exit 0
fi

# e.g.
# add-delete "127.0.0.1" "example.org" "test-host"
