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

	# delzone via rndc
	if ("$BIND_BINARY_DEFAULT_PATH"/rndc delzone "$DDNS_TEST_ZONE"); then

		echo "# INFO zone $DDNS_TEST_ZONE successful delete (inactive)"

	else

		echo "# ERROR try to delete zone $DDNS_TEST_ZONE raise a error"
		echo "# HINT see /var/log/syslog or /var/log/bind.log"
		echo "# EXIT 1"
		exit 1

	fi

	# remove include from /etc/bind/named.conf

	NAMED_CONF_NEW_ZONE_INCLUDED="include \"$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE\";"

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

	# delete conf file

	$SUDO rm -rf "$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"

	# delete zone file

	$SUDO rm -rf "$ETC_BIND_EXAMPLE_ZONE_FILE"

	# reload bind

	# delzone via rndc
	if ("$BIND_BINARY_DEFAULT_PATH"/rndc reload); then

		echo "# INFO bind reload successfully "

	else

		echo "# ERROR try to reload bind raise an error"
		echo "# HINT see at /var/log/syslog or /var/log/bind.log"
		echo "# EXIT 1"
		exit 1

	fi

}

# call function
delete-static-test-zone
