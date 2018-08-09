#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# CONSTANTS for static zone
BIND_BINARY_DEFAULT_PATH="/usr/sbin"

DDNS_KEY_NAME="example.com."
DDNS_TEST_ZONE="example.com"

ETC_BIND_DDNS_FILE="/etc/bind/ddns_${DDNS_TEST_ZONE}.key"
ETC_BIND_DDNS_NSUPDATE_FILE="/etc/bind/ddns_${DDNS_TEST_ZONE}_nsupdate.key"
ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE="/etc/bind/example.com.conf"
ETC_BIND_EXAMPLE_ZONE_FILE="/etc/bind/example.com.zone"

echo "# INFO used parameter BIND_BINARY_DEFAULT_PATH => $BIND_BINARY_DEFAULT_PATH"

echo "# INFO used parameter DDNS_KEY_NAME => $DDNS_KEY_NAME"
echo "# INFO used parameter DDNS_TEST_ZONE => $DDNS_TEST_ZONE"

echo "# INFO used parameter ETC_BIND_DDNS_FILE => $ETC_BIND_DDNS_FILE"
echo "# INFO used parameter ETC_BIND_DDNS_NSUPDATE_FILE => $ETC_BIND_DDNS_NSUPDATE_FILE"
echo "# INFO used parameter ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE => $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"
echo "# INFO used parameter ETC_BIND_EXAMPLE_ZONE_FILE => $ETC_BIND_EXAMPLE_ZONE_FILE"
