#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# from here
# https://serverfault.com/questions/328642/compute-a-list-of-difference-between-packages-installed-on-two-hosts

# message
echo "# OK ${0##*/} loaded"

function save_package_list_for_compare() {
	if [ -z ${1+x} ]; then
		echo "LIST is unset"
		exit 1
	else
		echo "# INFO list is set to '$1'"

	fi

	local LIST=$1
	dpkg -l | sort >"$BUILD_DIR/$LIST"

}

# test
