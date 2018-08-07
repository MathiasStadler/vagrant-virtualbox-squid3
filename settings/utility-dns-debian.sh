#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

LOG_FILE="$0_$$_$(date +%F_%H-%M-%S).log"

# message
echo "# OK ${0##*/} loaded" | tee -a "${LOG_FILE}"
#echo "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
printf "# INFO script %s post load script %s\\n" "$0" "${BASH_SOURCE[@]}"

function get-nameserver-of-url() {

	# ARG1 = URL to resolve

	echo "# INFO call get-nameserver-of-url" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 URL to resolve NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1"
		exit 1
	else
		URL_RESOLVE="$1"
		echo "# INFO URL to resolve set to '$URL_RESOLVE'" | tee -a "${LOG_FILE}"
	fi

	# we will only one not all
	if NAME_SERVER_OUTPUT=$(dig +short NS "$1" | head -1); then

		# array to string
		NAME_SERVER=${NAME_SERVER_OUTPUT[*]}
		echo "# INFO name server  for $URL_RESOLVE is e.g. ${NAME_SERVER}"
		return 0
	else

		echo "# ERROR no nameserver found"
		return 1
	fi
}

function get-ip-of-url() {

	# ARG1 = URL to resolve

	echo "# INFO call get-ip-of-url" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 URL to resolve NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1"
		exit 1
	else
		URL_RESOLVE="$1"
		echo "# INFO URL to resolve set to '$URL_RESOLVE'" | tee -a "${LOG_FILE}"
	fi

	# we will only one not all
	if IP_OF_SERVER_OUTPUT=$(dig +short "$1" | head -1); then

		# array to string
		IP_SERVER=${IP_OF_SERVER_OUTPUT[*]}
		echo "# INFO ip address for $URL_RESOLVE is e.g. (first one) ${IP_SERVER}"
		return 0
	else

		echo "# ERROR no ip  found"
		return 1
	fi
}

function get-serial-number-of-zone() {

	# ARG1 = ZONE_URL to resolve

	echo "# INFO call get-ip-of-url" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 URL to resolve NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1"
		exit 1
	else
		ZONE_URL="$1"
		echo "# INFO URL to resolve set to '$ZONE_URL'" | tee -a "${LOG_FILE}"
	fi

	# we will only one not all
	if ZONE_SERIAL_NUMBER_OUTPUT=$(dig SOA "$1" | grep SOA | awk '{print $7 }'); then
		# array to string
		ZONE_SERIAL_NUMBER=${ZONE_SERIAL_NUMBER_OUTPUT[*]}

		MAGIC_DNS_ZONE_NUMBER=4294967296
		# from here
		# https://www.networkworld.com/article/2767441/it-management/serial-numbers-in-zone-files--yours-and-named-s.html

		# -gt greater than
		if [ "$ZONE_SERIAL_NUMBER" -gt "$MAGIC_DNS_ZONE_NUMBER" ]; then

			echo "# INFO $ZONE_SERIAL_NUMBER >  $MAGIC_DNS_ZONE_NUMBER"
			echo "# ACTION calculating zone serial number divide by Magic number"
			ZONE_SERIAL_NUMBER="$(expr $ZONE_SERIAL_NUMBER % $MAGIC_DNS_ZONE_NUMBER)"
		else
			echo "# INFO $ZONE_SERIAL_NUMBER < $MAGIC_DNS_ZONE_NUMBER"
			echo "# INFO OK the serial number is not over $MAGIC_DNS_ZONE_NUMBER"

		fi

		echo "# INFO serial number for $ZONE_SERIAL is ${ZONE_SERIAL_NUMBER}"
		return 0
	else
		echo "# ERROR no ip  found"
		return 1
	fi
}

get-nameserver-of-url "heise.de"

get-ip-of-url "heise.de"

get-serial-number-of-zone "heise.de"
