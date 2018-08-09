#!/bin/bash

# ensure_sudo
ensure-sudo() {
	if [ "$(id -u)" != "0" ]; then
		SUDO="sudo" # Modified as suggested below.

	fi
}

$SUDO -h

# :usage
# $SUDO command
## call function
#ensure_sudo
