#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# shellcheck disable=SC1091
dynamic-zone-parameter.sh

function add-record-inside-dynamic-zone() {

	echo "# INFO call add-record-inside-dynamic-zone"

	NSUPDATE_ADD_HOST_DYNAMIC_ZONE_SCRIPT="$HOME$TEST_FOLDER/nsupdate_add_host_dynamic_zone.sh"

	echo "# ACTION write $NSUPDATE_ADD_HOST_DYNAMIC_ZONE_SCRIPT to $HOME$TEST_FOLDER"

	cat <<EOF >"$NSUPDATE_ADD_HOST_DYNAMIC_ZONE_SCRIPT"
#!/bin/bash
#Defining Variables
DNS_SERVER="localhost"
DNS_ZONE="$DYNAMIC_ADD_ZONE."
HOST="test.$DYNAMIC_ADD_ZONE"
IP="192.168.178.123"
TTL="60"
RECORD=" \$HOST \$TTL A \$IP"
echo "
server \$DNS_SERVER
zone \$DNS_ZONE
debug
update add \$RECORD
show
send" | nsupdate -k $ETC_BIND_DDNS_NSUPDATE_FILE
EOF

	echo "# ACTION set execute for $NSUPDATE_ADD_HOST_DYNAMIC_ZONE_SCRIPT"
	# execute script NSUPDATE_ADD_HOST_SCRIPT
	chmod +x "$NSUPDATE_ADD_HOST_DYNAMIC_ZONE_SCRIPT"

	echo "# ACTION reload zone $DYNAMIC_ADD_ZONE"
	# activate changes

	# call function
	clean-and-sync-all-zone-journals

	# call function
	reload-dynamic-zone "$DYNAMIC_ADD_ZONE"

	echo "# ACTION execute nsupdate of zone $DYNAMIC_ADD_ZONE"
	if ($NSUPDATE_ADD_HOST_DYNAMIC_ZONE_SCRIPT); then
		echo "# OK nsupdate of zone $DYNAMIC_ADD_ZONE "
	else
		echo "# ERROR nsupdate of zone $DYNAMIC_ADD_ZONE"
		echo "# EXIT 1"
		exit 1
	fi

	# call function
	clean-and-sync-all-zone-journals

	if (get-ip-of-url test."$DYNAMIC_ADD_ZONE" "127.0.0.1"); then

		echo "# OK"
	else
		echo "# ERROR"
	fi

}

# call function
add-record-inside-dynamic-zone
