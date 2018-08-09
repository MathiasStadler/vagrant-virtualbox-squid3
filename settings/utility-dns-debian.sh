#!/bin/bash

# Exit immediately if a command returns a non-zero status
# set -e

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
	# ARG2 = NAME_SERVER

	echo "# INFO call get-ip-of-url" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 URL to resolve NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1"
		exit 1
	else
		URL_RESOLVE="$1"
		echo "# INFO URL to resolve set to '$URL_RESOLVE'" | tee -a "${LOG_FILE}"
	fi

	if [ -z ${2+x} ]; then
		echo "# HINT ARG2 NAME_SERVER NOT set" | tee -a "${LOG_FILE}"
		# detect current-name-server
		get-current-name-server

		echo "# INFO we will use the system wide nameserver $CURRENT_NAME_SERVER_IN_USED"
		NAME_SERVER=$CURRENT_NAME_SERVER_IN_USED
	else
		NAME_SERVER="$2"
		echo "# INFO URL to NAME_SERVER set to '$NAME_SERVER'" | tee -a "${LOG_FILE}"
	fi

	echo "# INFO we used NAME_SERVER => '$NAME_SERVER'" | tee -a "${LOG_FILE}"

	# we will only one not all
	if IP_OF_SERVER_OUTPUT=$(dig +short "$1" @$NAME_SERVER | head -1); then

		# array to string
		IP_SERVER=${IP_OF_SERVER_OUTPUT[*]}
		echo "# INFO ip address for $URL_RESOLVE is e.g. (first match) ${IP_SERVER}"
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

function set-resolv-conf() {

	# ARG1 = NAMESERVER_IP for resolv

	echo "# INFO call set-resolv-conf" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1  NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1"
		exit 1
	else
		NAMESERVER_IP="$1"
		echo "# INFO NAMESERVER_IP set to '$NAMESERVER_IP'" | tee -a "${LOG_FILE}"
	fi

	ETC_RESOLV_CONF="/etc/resolv.conf"
	ETC_RESOLV_CONF_SAVE="/etc/resolv.conf_SAVE"

	if [ -e $ETC_RESOLV_CONF ]; then
		echo "# ACTION save current to $ETC_RESOLV_CONF_SAVE"
		mv ETC_RESOLV_CONF ETC_RESOLV_CONF_SAVE
	fi

	cat <<EOF >"$ETC_RESOLV_CONF"
nameserver $NAMESERVER_IP
search fritz.box
EOF

}

function get-current-name-server() {

	echo "# ACTION find running name server"

	CURRENT_NAME_SERVER_IN_USED=$(dig | grep ';; SERVER' | awk '{print $3}' | grep -Po '\(\K[^)]*')

	echo "# INFO get current name server $CURRENT_NAME_SERVER_IN_USED"

}

function check-name-server-avaible() {

	# ARG1 = NAMESERVER_IP for resolv

	echo "# INFO call check-name-server-avaible" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1  NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1"
		exit 1
	else
		NAMESERVER_IP="$1"
		echo "# INFO NAMESERVER_IP set to '$NAMESERVER_IP'" | tee -a "${LOG_FILE}"
	fi

	# from man page
	# Dig return codes are:

	#     0: Everything went well, including things like NXDOMAIN
	#     1: Usage error
	#     8: Couldn't open batch file
	#     9: No reply from server
	#     10: Internal error

	# from here
	# https://stackoverflow.com/questions/1494178/how-to-define-hash-tables-in-bash
	# Just use directory

	# hash table creation
	hash_table=$(mktemp -d)

	# Add an elements

	echo "# INFO OK Everything went well, including things like NXDOMAIN" >$hash_table/0
	echo "# ERROR Usage error" >$hash_table/1
	echo "# ERROR Couldn't open batch file" >$hash_table/8
	echo "# ERROR No reply from server " >$hash_table/9
	echo "# ERROR Internal error" >$hash_table/10

	# read an element
	value=$(<$hash_table/1)

	# disable catch error we will catch them self
	set +e
	# call sub shell
	(dig @"$NAMESERVER_IP" +time=5 +tries=1 1>/dev/null 2>/dev/null)
	# catch return value
	DIG_RETURN_CODE=$?
	# enable catch errors
	set -e

	# echo "# DEBUG DIG_RETURN_CODE => $DIG_RETURN_CODE "

	if [ -e $hash_table/$DIG_RETURN_CODE ]; then
		echo "$(<$hash_table/$DIG_RETURN_CODE)"
	else

		echo "# ERROR return code unknown"
		echo "# PLEASE give info to developer"
	fi

	# delete key/value directory
	rm -rf "$hash_table"

	if [ "$DIG_RETURN_CODE" -eq "0" ]; then
		echo "# INFO DIG_RETURN_CODE => $DIG_RETURN_CODE"
		return 0
	else
		echo "# ERROR DIG_RETURN_CODE => $DIG_RETURN_CODE"
		return $DIG_RETURN_CODE
	fi

}
