#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# message
echo "# OK ${0##*/} loaded" | tee -a "${LOG_FILE}"
#echo "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
printf "# INFO script %s post load script %s\\n" "$0" "${BASH_SOURCE[@]}"

ZONE_MASTER_ZONE="master-template.com"
DYNAMIC_ADD_ZONE="dynamic-zone.com"
BIND_CHROOT="/var/lib/named"
ZONE_MASTER_TEMPLATE_DIRECTORY="/var/cache/bind/master"

echo "# INFO used parameter ZONE_MASTER_ZONE => $ZONE_MASTER_ZONE"
echo "# INFO used parameter DYNAMIC_ADD_ZONE => $DYNAMIC_ADD_ZONE"
echo "# INFO used parameter BIND_CHROOT => $BIND_CHROOT"
echo "# INFO used parameter ZONE_MASTER_TEMPLATE_DIRECTORY => $ZONE_MASTER_TEMPLATE_DIRECTORY"
