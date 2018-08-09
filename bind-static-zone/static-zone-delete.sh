#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# Exit immediately if a command returns a non-zero status
set -e

# shellcheck disable=SC1091
source ../settings/utility-bash.sh

# call function
ensure-sudo

# shellcheck disable=SC1091
source ./static-zone-parameter.sh

# shellcheck disable=SC1091
source ../settings/utility-dns-debian.sh

function delete-static-test-zone() {

	# delzone via rndc
	if ($BIND_BINARY_DEFAULT_PATH/rndc delzone "$DDNS_TEST_ZONE"); then

		echo "# INFO zone $DDNS_TEST_ZONE successfuled delete (inactive)"

	else

		echo "# ERROR try to delete zone $DDNS_TEST_ZONE raise a error"
		echo "# HINT see /var/log/syslog or /var/log/bind.log"
		echo "# EXIT 1"
		exit 1

	fi

	# remove include from /etc/bind/named.conf

	NAMED_CONF_NEW_ZONE_INCLUDED="include \"$ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE\";"

	if ($SUDO sed -i "/$NAMED_CONF_NEW_ZONE_INCLUDED/d" "$ETC_BIND_NAMED_CONF"); then

		echo "# INFO deleted line $NAMED_CONF_NEW_ZONE_INCLUDED successful"

	else

		echo "# ERROR try to delete line $NAMED_CONF_NEW_ZONE_INCLUDED in $ETC_BIND_NAMED_CON file raise a error"
		echo "# HINT see /var/log/syslog or /var/log/bind.log"
		echo "# EXIT 1"
		exit 1

	fi

	# delete conf file

	$SUDO rm -rf $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE

	# delete zone file

	$SUDO rm -rf $ETC_BIND_EXAMPLE_ZONE_FILE

}

# call function
delete-static-test-zone
