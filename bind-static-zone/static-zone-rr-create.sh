#!/bin/bash
# script create rr in static zone
# https://de.wikipedia.org/wiki/Resource_Record

# Exit immediately if a command returns a non-zero status
set -e

# shellcheck disable=SC1091
source ../settings/utility-bash.sh

# call function
ensure-sudo

function add-record() {

echo "# INFO call add-record" | tee -a "${LOG_FILE}"

# ARG1 = DDNS_NAME_SERVER"
# ARG2 = DDNS_ZONE
# ARG3 = DDNS_HOST
# ARG4 = DDNS_IP
# ARG5 = TTL

ARG_NUMBER,VARIABLE_NAME,NEEDED_FOR

args=("$@")
for ((i=0; i < $#; i++))
{
    echo "argument $((i+1)): ${args[$i]}"
}

	echo "#ACTION check and create execute directory $EXECUTE_FOLDER"
	mkdir -p "$EXECUTE_FOLDER"

	# set name NSUPDATE_ADD_HOST_SCRIPT
	EXECUTE_SCRIPT="$EXECUTE_FOLDER/static-zone-add-rr.sh"

	echo "# ACTION write script $EXECUTE_SCRIPT to $EXECUTE_FOLDER"

	#!/bin/bash
	#Defining Variables
	DNS_SERVER="$DDNS_NAME_SERVER"
	DNS_ZONE="$DDNS_ZONE."
	HOST="$DDNS_HOST"
	IP="$DDNS_IP"
	TTL="$TTL"
	RECORD=" \$HOST \$TTL A \$IP"

	if (
		echo "
server \$DNS_SERVER
zone \$DNS_ZONE
debug
update add \$RECORD
show
send" | nsupdate -k $ETC_BIND_DDNS_NSUPDATE_FILE
	); then
		echo "# OK"
	else
		echo "# ERROR"
	fi

	echo "# ACTION set execute for $EXECUTE_SCRIPT"
	# execute script NSUPDATE_ADD_HOST_SCRIPT
	$SUDO chmod +x "$EXECUTE_SCRIPT"

	echo "# ACTION reload zone $DDNS_TEST_ZONE"

	# exec script
	echo "# ACTION execute nsupdate of zone $DDNS_TEST_ZONE"
	if ("$SUDO" "$EXECUTE_SCRIPT"); then
		echo "# OK nsupdate of zone "
	else
		echo "# ERROR nsupdate of zone"
		echo "# EXIT 1"
		exit 1
	fi

}
