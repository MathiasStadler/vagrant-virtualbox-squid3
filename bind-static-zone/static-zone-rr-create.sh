#!/bin/bash
# script create rr in static zone
# https://de.wikipedia.org/wiki/Resource_Record

# Exit immediately if a command returns a non-zero status
# set -e
# from here https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
# set -Eeuxo pipefail
set -Eeuo pipefail

err_report() {
  echo "unexpected error on line $(caller) script exit" >&2
}

trap err_report ERR


# shellcheck disable=SC1091
source ../settings/utility-bash.sh

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
argument0=("DDNS_NAME_SERVER" "DNS NAME SERVER" "$TRUE" "$FALSE")
argumant1=("DDNS_ZONE" "DNS ZONE for resource record " "$TRUE" "$FALSE")
argumant2=("RR_HOST_ADDRESS" "Name of host" "$TRUE" "$FALSE")
argumant3=("RR_IP_OF_HOST" "IP of host" "$TRUE" "$FALSE")
argumant4=("TTL" "Time to live of RR " "$TRUE" "$FALSE")

# ARG_NUMBER,VARIABLE_NAME,NEEDED_FOR

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

# n for current argumant
n_argument="argument$i[@]"

# n_arr for value array for the current parameter
n_array=("${!n_argument}")

# array length valid
echo "# CHECK argument array $n_array has all data "
[ "${#n_array[@]}" = "$ARGUMENT_ARRAY_LENGTH" ]
echo "OK"


echo " DEBUG n_param '${n_argument}'"
echo " DEBUG complete array is '${argument0[*]}'"
echo " DEBUG complete array is '${n_array[*]}'"

#${${1}[@]}

# declare variable
declare ${n_array[0]}=${args[$i]}

echo "# INFO set ${n_array[0]} "
echo "# DEBUG DDNS_NAME_SERVER => $DDNS_NAME_SERVER"
echo "# DEBUG DDNS_NAME_SERVER => ${!n_array[0]}"
echo zweite ${n_array[1]}
echo dritte ${n_array[2]}

break

}




exit 1

	echo "#ACTION check and create execute directory $EXECUTE_FOLDER"
	mkdir -p "$EXECUTE_FOLDER"

	# set name NSUPDATE_ADD_HOST_SCRIPT
	EXECUTE_SCRIPT="$EXECUTE_FOLDER/static-zone-add-rr.sh"

	echo "# ACTION write script $EXECUTE_SCRIPT to $EXECUTE_FOLDER"

	#!/bin/bash
	#Defining Variables
	DNS_SERVER="$DDNS_NAME_SERVER"
	DNS_ZONE="$DDNS_ZONE."
	HOST="$DDNS_HOST"
	IP="$DDNS_IP"
	TTL="$TTL"
	RECORD=" \$HOST \$TTL A \$IP"

	if (
		echo "
server \$DNS_SERVER
zone \$DNS_ZONE
debug
update add \$RECORD
show
send" | nsupdate -k $ETC_BIND_DDNS_NSUPDATE_FILE
	); then
		echo "# OK"
	else
		echo "# ERROR"
	fi

	echo "# ACTION set execute for $EXECUTE_SCRIPT"
	# execute script NSUPDATE_ADD_HOST_SCRIPT
	$SUDO chmod +x "$EXECUTE_SCRIPT"

	echo "# ACTION reload zone $DDNS_TEST_ZONE"

	# exec script
	echo "# ACTION execute nsupdate of zone $DDNS_TEST_ZONE"
	if ("$SUDO" "$EXECUTE_SCRIPT"); then
		echo "# OK nsupdate of zone "
	else
		echo "# ERROR nsupdate of zone"
		echo "# EXIT 1"
		exit 1
	fi

}


add-record "127.0.0.1" "example.org" "test-host" "192.168.178.213" "600"