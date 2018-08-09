#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# log file
LOG_FILE="$0_$$_$(date +%F_%H-%M-%S).log"

SETTINGS_DIR="."

# load utility-dns-debian
# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/utility-dns-debian.sh"

# git check update
# from here
# https://stackoverflow.com/questions/3258243/check-if-pull-needed-in-git
if [ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} |
	sed 's/\// /g') | cut -f1) ]; then
	echo "# INFO git is  up to date"
else
	echo "# HINT git not up to date"
	read -r -p "You want make git pull? [Y/n]" response
	response=${response,,} # convert answer to lower letter
	if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
		git pull
		echo "# RESTART SCRIPT"

		exit 0
	fi

fi

COMMAND="check-name-server-avaible 127.0.0.1"
echo "# ACTION test command => $COMMAND"

"${COMMAND[@]}"
COMMAND_RETURN_CODE=$?

echo "# INFO command result of command => $COMMAND " | tee -a "${LOG_FILE}"
echo "# START OUTPUT ########## " | tee -a "${LOG_FILE}"
echo "${COMMAND_RESULT[*]} " | tee -a "${LOG_FILE}"
echo "# FINISHED OUTPUT ########## " | tee -a "${LOG_FILE}"

RETURN_OK=0

COMMAND_EXPECT_CODE=$RETURN_OK

if [ "$COMMAND_RETURN_CODE" -eq "$COMMAND_EXPECT_CODE" ]; then

	echo "# OK"
else
	echo "# ERROR "
fi

#check-name-server-avaible "127.0.0..1"

# echo "# ACTION  stop bind9"

#$SUDO service bind9 stop

# check-name-server-avaible "127.0.0.1"

# echo "# ACTION start bind9"

# $SUDO service bind9 start
