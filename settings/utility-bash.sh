#!/bin/bash

# message
echo "# OK ${0##*/} loaded"
#echo "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
printf " # INFO script %s post load script %s\\n" "$0" "${BASH_SOURCE[@]}"

# ensure_sudo
ensure-sudo() {
	if [ "$(id -u)" != "0" ]; then
		SUDO="sudo" # Modified as suggested below.
		echo "# INFO script start with user $(id), so  need sudo set to $SUDO"
	else

		echo "# INFO script run with user root => $(id)"
		echo "# INFO set SUDO to empty string"
		SUDO=""
	fi
}

# :usage
# $SUDO command
## call function
#ensure_sudo

function provide-dynamic-function-argument() {

	# get all arguments
	args=("$@")

	# loop over number of parameter
	echo "# INFO function has $# argument(s)"

	for ((i = 0; i < $#; i++)); do

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
		declare -a | grep "argument$i" >/dev/null 2>/dev/null
		echo "OK "

		# build array name for dynamic binding
		# shellcheck disable=SC1087
		n_argument="argument$i[@]"

		# n_arr for value array for the current parameter
		n_array=("${!n_argument}")

		ARGUMENT_ARRAY_LENGTH=4

		# array length valid
		echo "# CHECK argument array ${n_array[*]} has all data "
		[ "${#n_array[@]}" = "$ARGUMENT_ARRAY_LENGTH" ]
		echo "OK"

		echo "# DEBUG n_param '${n_argument}'"
		echo "# DEBUG complete array is '${n_array[*]}'"

		echo "# INFO set dynamic argument $i to variable ${n_array[0]} "

		# declare dynamic variable
		declare "${n_array[0]}"="${args[$i]}"

		echo "# DEBUG ${n_array[0]} => ${!n_array[0]}"
		echo "# DEBUG description of argument ${n_array[0]} => ${n_array[1]}"
		echo "# DEBUG is ${n_array[0]} nesseccary ${n_array[2]}"
		echo "# DEBUG default value ${n_array[0]} ${n_array[3]}"
	done

}
