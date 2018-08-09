#!/bin/bash

# Exit immediately if a command returns a non-zero status
# set -e

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

function test_function() {

	# ARG1 = COMMAND for test
	# ARG2 = EXPECTED_RESULT as integer value

	echo "# INFO call test-function" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1  COMMAND NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1"
		exit 1
	else
		COMMAND="$1"
		echo "# INFO COMMAND set to '$COMMAND'" | tee -a "${LOG_FILE}"
	fi

	if [ -z ${2+x} ]; then
		echo "# ERROR ARG1  EXPECTED_RESULT NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1"
		exit 1
	else
		EXPECTED_RESULT="$2"
		echo "# INFO EXPECTED_RESULT set to '$EXPECTED_RESULT'" | tee -a "${LOG_FILE}"
	fi

	echo "# ACTION test command => $COMMAND with EXPECTED_RESULT => $EXPECTED_RESULT"

	# call function
	# set +e
	# shellcheck disable=SC2068
	${COMMAND[@]}
	COMMAND_RETURN_CODE=$FUNCTION_RESULT
	# set -e

	# echo "# INFO command result of command => $COMMAND " | tee -a "${LOG_FILE}"
	# echo "# START OUTPUT ########## " | tee -a "${LOG_FILE}"
	# echo "${COMMAND_RESULT[*]} " | tee -a "${LOG_FILE}"
	# echo "# FINISHED OUTPUT ########## " | tee -a "${LOG_FILE}"

	if [ "$COMMAND_RETURN_CODE" -eq "$EXPECTED_RESULT" ]; then

		echo "# OK COMMAND_RETURN_CODE = EXPECTED_RESULT ($COMMAND_RETURN_CODE = $EXPECTED_RESULT )"
	else
		echo "# ERROR "
		echo "# EXIT 1"
		exit 1
	fi

}

EXPECTED_RESULT_OK=0

COMMAND="check-name-server-avaible 127.0.0.1"
EXPECTED_RESULT=$EXPECTED_RESULT_OK
# call function
test_function "$COMMAND" "$EXPECTED_RESULT"

#check-name-server-avaible "127.0.0..1"

# echo "# ACTION  stop bind9"

#$SUDO service bind9 stop

# check-name-server-avaible "127.0.0.1"

# echo "# ACTION start bind9"

# $SUDO service bind9 start
