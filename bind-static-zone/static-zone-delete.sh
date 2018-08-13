#!/bin/bash

# Exit immediately if a command returns a non-zero status

# with print command
set -Eeuxo pipefail

# without print command
# set -Eeuo pipefail

err_report() {
	echo "unexpected error on line $(caller) script exit" >&2
}

trap err_report ERR

SETTINGS="../settings"

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

function delete-static-zone() {

	echo "# INFO call add-record" | tee -a "${LOG_FILE}"

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

	# delzone via rndc
	if ("$RNDC_EXEC" delzone "$DDNS_ZONE"); then

		echo "# INFO zone $DDNS_ZONE successful delete (inactive)"

	else

		echo "# ERROR try to delete zone $DDNS_ZONE raise a error"
		echo "# HINT see /var/log/syslog or /var/log/bind.log"
		echo "# EXIT 1"
		exit 1

	fi

	# remove include from /etc/bind/named.conf

	NAMED_CONF_NEW_ZONE_INCLUDED="include \"$ETC_BIND_CONFIG_FILE\";"

	if ($SUDO sed -i "/include.*$DDNS_TEST_ZONE/d" "$ETC_BIND_NAMED_CONF"); then

		echo "# INFO deleted line $NAMED_CONF_NEW_ZONE_INCLUDED successful"

	else

		echo "# ERROR try to delete line $NAMED_CONF_NEW_ZONE_INCLUDED in $ETC_BIND_NAMED_CON file raise a error"
		echo "# HINT see /var/log/syslog or /var/log/bind.log"
		echo "# EXIT 1"
		exit 1

	fi

	# double check of successful remove
	# check first entry available already
	if (grep "$NAMED_CONF_NEW_ZONE_INCLUDED" "$ETC_BIND_NAMED_CONF"); then

		echo "# ERROR $NAMED_CONF_NEW_ZONE_INCLUDED should not contain in $ETC_BIND_NAMED_CONF"
		echo "# EXIT 1
        exit 1

	else

        echo " # OK line deleted"

	fi

	# delete all file of the zone protect thr named.conf
	if (find /etc/bind/ -type f -exec grep -l $DDNS_ZONE {} \; | grep -v $ETC_BIND_NAMED_CONF); then
		echo "# INFO deleted file of zone  $DDNS_ZONE successful"
	else
		echo "# ERROR delete zone files of zone  $DDNS_ZONE "
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

# call function
delete-static-zone "127.0.0.1" "example.org"
