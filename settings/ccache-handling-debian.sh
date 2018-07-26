#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# message
echo "# OK ${0##*/} loaded"

function ccache-is-in-place() {
	# check if ccache is in place
	if (ls -lh /usr/local/bin/gcc | grep ccache); then

		echo "OK found ccache"

	else

		echo "NOT OK CCache NOT found"
		exit 1
	fi

}
