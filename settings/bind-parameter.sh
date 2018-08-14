#!/bin/bash

# message
echo "# OK ${0##*/} loaded"
#echo "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
printf "# INFO script %s post load script %s\\n" "$0" "${BASH_SOURCE[@]}"

LOG_FILE="$0_$$_$(date +%F_%H-%M-%S).log"

BIND_BINARY_DEFAULT_PATH="/usr/sbin"
BIND_CONFIG_PATH="/etc/bind"

ETC_BIND_NAMED_CONF="/etc/bind/named.conf"

# default path
RNDC_EXEC="/usr/sbin/rndc"

echo "# INFO used parameter LOG_FILE => $LOG_FILE"
echo "# INFO used parameter BIND_BINARY_DEFAULT_PATH => $BIND_BINARY_DEFAULT_PATH"
echo "# INFO used parameter ETC_BIND_NAMED_CONF => $ETC_BIND_NAMED_CONF"
echo "# INFO used parameter RNDC_EXEC => $RNDC_EXEC"
