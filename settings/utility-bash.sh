#!/bin/bash

# message
echo "# OK ${0##*/} loaded" | tee -a "${LOG_FILE}"
#echo "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
printf "# INFO script %s post load script %s\\n" "$0" "${BASH_SOURCE[@]}"

echop $dirname
# shellcheck disable=SC1091
source ./bind-parameter.sh

# ensure_sudo
ensure-sudo() {
	if [ "$(id -u)" != "0" ]; then
		SUDO="sudo" # Modified as suggested below.

	fi
}

echo "# INFO sudo set to $SUDO"

# :usage
# $SUDO command
## call function
#ensure_sudo
