#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

function squid-download-and-extract() {

	echo "call squid-download-and-extract"

	if [ -z ${1+x} ]; then
		echo "DIRECTORY to extract NOT set"
		exit 1
	else
		echo "install to '$1'"

	fi

	curl "http://www.squid-cache.org/Versions/v3/3.5/${SQUID_TAR}" -o "/tmp/${SQUID_TAR}"

	tar xzf "/tmp/${SQUID_TAR}" -C $1

}
