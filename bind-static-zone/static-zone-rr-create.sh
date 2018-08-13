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

# shellcheck disable=SC1090,SC1091
source "$SETTINGS/utility-bash.sh"

# shellcheck disable=SC1090,SC1091
source "$SETTINGS/utility-dns-debian.sh"

# call function
ensure-sudo

function add-record() {

	echo "# INFO call add-record" | tee -a "${LOG_FILE}"

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
	argument3=("RR_IP_OF_HOST" "IP of host" "$TRUE" "$FALSE")
	# shellcheck disable=SC2034
	argument4=("TTL" "Time to live of RR " "$TRUE" "$FALSE")

	echo "DDNS_NAME_SERVER $DDNS_NAME_SERVER"

	if (
		echo "
server $DDNS_NAME_SERVER
zone $DDNS_ZONE
debug
update add $RR_HOST_ADDRESS $TTL A $RR_IP_OF_HOST
show
send"
		#| nsupdate -k "$ETC_BIND_DDNS_NSUPDATE_FILE"
	); then
		echo "# OK"
	else
		echo "# ERROR"
	fi

	echo "# ACTION reload zone $DDNS_ZONE"
	reload-dynamic-zone $DDNS_ZONE
}

add-record "127.0.0.1" "example.org" "test-host" "192.168.178.213" "600"
