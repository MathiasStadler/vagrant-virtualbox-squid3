#!/bin/bash
# script create rr in static zone
# https://de.wikipedia.org/wiki/Resource_Record

# Exit immediately if a command returns a non-zero status
# set -e
# from here https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

# with print command
# set -Eeuxo pipefail

# without print command

set -Eeuo pipefail

err_report() {
  echo "unexpected error on line $(caller) script exit" >&2
}

trap err_report ERR

SETTINGS="../settings"

# shellcheck disable=SC1091
source "$SETTINGS/utility-bash.sh"

# shellcheck disable=SC1091
source "$SETTINGS/utility-dns-debian.sh"

# call function
ensure-sudo

function add-record() {

echo "# INFO call add-record" | tee -a "${LOG_FILE}"

# ARG1 = DDNS_NAME_SERVER"
# ARG2 = DDNS_ZONE
# ARG3 = RR_HOST_ADDRESS
# ARG4 = RR_IP_OF_HOST
# ARG5 = TTL

TRUE=0
FALSE=1
ARGUMENT_ARRAY_LENGTH=4
# Attention parameter count start at 0
# varName varMessage varNesseccary varDefaultValue
# bound dynamic
# shellcheck disable=SC2034
argument0=("DDNS_NAME_SERVER" "DNS NAME SERVER" "$TRUE" "$FALSE")
# shellcheck disable=SC2034
argument1=("DDNS_ZONE" "DNS ZONE for resource record " "$TRUE" "$FALSE")
# shellcheck disable=SC2034
argument2=("RR_HOST_ADDRESS" "Name of host" "$TRUE" "$FALSE")
# shellcheck disable=SC2034
argument3=("RR_IP_OF_HOST" "IP of host" "$TRUE" "$FALSE")
# shellcheck disable=SC2034
argument4=("TTL" "Time to live of RR " "$TRUE" "$FALSE")



# get all arguments
args=("$@")

# loop over number of parameter
echo "# INFO function has $# argument(s)"
for ((i=0; i < $#; i++))
{

# from here declare dynamic array name
# https://unix.stackexchange.com/questions/60584/how-to-use-a-variable-as-part-of-an-array-name
# string substitution
# and
# http://www.ludvikjerabek.com/2015/08/24/getting-bashed-by-dynamic-arrays/
# and final from here
# https://stackoverflow.com/questions/17890919/bash-iterate-through-multiple-arrays

# check is argument array define

# check array is declare
echo "# CHECK array for argument$i is defined (used set-e)"
declare -a |grep "argument$i" >/dev/null 2>/dev/null
echo "OK "

# build array name for dynamic binding
# shellcheck disable=SC1087
n_argument="argument$i[@]"

# n_arr for value array for the current parameter
n_array=("${!n_argument}")

# array length valid
echo "# CHECK argument array ${n_array[*]} has all data "
[ "${#n_array[@]}" = "$ARGUMENT_ARRAY_LENGTH" ]
echo "OK"

echo "# DEBUG n_param '${n_argument}'"
echo "# DEBUG complete array is '${n_array[*]}'"

echo "# INFO set dynamic argument $i to variable ${n_array[0]} "

# declare dynamic variable
declare ${n_array[0]}=${args[$i]}


echo "# DEBUG ${n_array[0]} => ${!n_array[0]}"
echo "# DEBUG description of argumant ${n_array[0]} => ${n_array[1]}"
echo "# DEBUG is ${n_array[0]} nesseccary ${n_array[2]}"
echo "# DEBUG default value ${n_array[0]} ${n_array[3]}"
}

echo "# ACTION create record $DDNS_NAME_SERVER to $DDNS_ZONE"

	if (
		echo "
server $NAME_SERVER
zone $DNS_ZONE
debug
update add $HOST $TTL A $IP
show
send" | nsupdate -k $ETC_BIND_DDNS_NSUPDATE_FILE
	); then
		echo "# OK"
	else
		echo "# ERROR"
	fi


	echo "# ACTION reload zone $DDNS_ZONE"
	reload-dynamic-zone $DDNS_ZONE
}


add-record "127.0.0.1" "example.org" "test-host" "192.168.178.213" "600"