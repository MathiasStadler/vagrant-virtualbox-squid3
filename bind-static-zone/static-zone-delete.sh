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

function delete-static-zone() {

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

	echo "# INFO call delete-static-zone" | tee -a "${LOG_FILE}"

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

	if (dig ns "$DDNS_ZONE" @"$DDNS_NAME_SERVER" | grep "ANSWER SECTION"); then
		echo "# INFO zone $DDNS_ZONE on name server $DDNS_NAME_SERVER available"
		echo "# ACTION to try deleted it"
	else
		echo "# INFO zone $DDNS_ZONE no available on name server $DDNS_NAME_SERVER"
		echo "# EXIT 0 "
		exit 1

	fi

	# call function
	clean-and-sync-all-zone-journals

	# call function
	reload-dynamic-zone "$DDNS_ZONE"

	# delzone via rndc
	echo "# ACTION delete zone $DDNS_ZONE"
	if ("$RNDC_EXEC" delzone "$DDNS_ZONE"); then
		echo "# INFO zone $DDNS_ZONE successful delete (inactive)"
	else
		echo "# ERROR try to delete zone $DDNS_ZONE raise a error"
		echo "# HINT see /var/log/syslog or /var/log/bind.log"
		echo "# EXIT 1"
		exit 1
	fi

	# remove include from /etc/bind/named.conf
	if ($SUDO sed -i "/include.*$DDNS_ZONE/d" "$ETC_BIND_NAMED_CONF"); then
		echo "# INFO deleted line $NAMED_CONF_NEW_ZONE_INCLUDED successful"
	else
		echo "# ERROR try to delete line $NAMED_CONF_NEW_ZONE_INCLUDED in $ETC_BIND_NAMED_CON file raise a error"
		echo "# HINT see /var/log/syslog or /var/log/bind.log"
		echo "# EXIT 1"
		exit 1
	fi

	# double check of successful remove
	# check first entry available already
	if (grep "$DDNS_ZONE" "$ETC_BIND_NAMED_CONF"); then

		echo "# ERROR entry with $DDNS_ZONE should not contain in $ETC_BIND_NAMED_CONF"
		echo "# PLEASE fix by hand"
		echo "# EXIT 1
        exit 1
	else
        echo " # OK entry $DDNS_ZONE deleted"
	fi

	# delete all file of the zone protect thr named.conf
	if (find /etc/bind/ -type f -exec grep -l "$DDNS_ZONE" {} \; | grep -v "$ETC_BIND_NAMED_CONF" | xargs "$SUDO" rm); then
		echo "# INFO deleted file of zone  $DDNS_ZONE successful"
	else
		echo "# ERROR delete zone files of zone  $DDNS_ZONE"
		echo "# EXIT 1"
		exit 1
	fi

	# reload bind
	if ("$RNDC_EXEC" reload); then
		echo " # INFO bind reload successfully "
	else
		echo "# ERROR try to reload bind raise an error"
		echo "# HINT see at /var/log/syslog or /var/log/bind.log"
		echo "# EXIT 1"
		exit 1
	fi

	# dynamic parameter end
	set -u

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
	delete-static-zone "$@"
	exit 0
fi
