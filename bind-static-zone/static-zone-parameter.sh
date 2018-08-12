#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# message
echo "# OK ${0##*/} loaded" | tee -a "${LOG_FILE}"
#echo "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
printf "# INFO script %s post load script %s\\n" "$0" "${BASH_SOURCE[@]}"

# shellcheck disable=SC1091
source ../settings/bind-parameter.sh

# CONSTANTS for static zone
TEMP_FOLDER="/tmp"
TEST_FOLDER="$TEMP_FOLDER/nsupdate_tests"

DDNS_KEY_NAME="example.com."
DDNS_TEST_ZONE="example.com"
DDNS_TEST_HOST="test.$DDNS_TEST_ZONE"
DDNS_TEST_IP="192.168.178.100"
DDNS_TEST_NAME_SERVER="127.0.0.1"

ETC_BIND_DDNS_FILE="/etc/bind/ddns_${DDNS_TEST_ZONE}.key"
ETC_BIND_DDNS_NSUPDATE_FILE="/etc/bind/ddns_${DDNS_TEST_ZONE}_nsupdate.key"
ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE="/etc/bind/example.com.conf"
ETC_BIND_EXAMPLE_ZONE_FILE="/etc/bind/example.com.zone"

echo "# INFO used parameter TEMP_FOLDER => $TEMP_FOLDER"
echo "# INFO used parameter TEST_FOLDER => $TEST_FOLDER"

echo "# INFO used parameter BIND_BINARY_DEFAULT_PATH => $BIND_BINARY_DEFAULT_PATH"

echo "# INFO used parameter DDNS_KEY_NAME => $DDNS_KEY_NAME"
echo "# INFO used parameter DDNS_TEST_ZONE => $DDNS_TEST_ZONE"
echo "# INFO used parameter DDNS_TEST_HOST => $DDNS_TEST_HOST"
echo "# INFO used parameter DDNS_TEST_IP => $DDNS_TEST_IP"
echo "# INFO used parameter DDNS_TEST_NAME_SERVER => $DDNS_TEST_NAME_SERVER"

echo "# INFO used parameter ETC_BIND_DDNS_FILE => $ETC_BIND_DDNS_FILE"
echo "# INFO used parameter ETC_BIND_DDNS_NSUPDATE_FILE => $ETC_BIND_DDNS_NSUPDATE_FILE"
echo "# INFO used parameter ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE => $ETC_BIND_EXAMPLE_ZONE_CONFIG_FILE"
echo "# INFO used parameter ETC_BIND_EXAMPLE_ZONE_FILE => $ETC_BIND_EXAMPLE_ZONE_FILE"
