#!/bin/bash

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

# check-name-server-avaible "127.0.0.1"

# check-name-server-avaible "127.0.0..1"

# echo "# ACTION  stop bind9"

# $SUDO service bind9 stop

# check-name-server-avaible "127.0.0.1"

# echo "# ACTION start bind9"
# $SUDO service bind9 start

SHELL_UNIT_2_PATH="$HOME/shunit2/shunit2"

if [ -e $SHELL_UNIT_2_PATH ]; then

	echo "# INFO run shellunit2 test"

	testEquality() {
		assertEquals 1 1
	}

	# testCheckNameServer() {

	# 	(check-name-server-avaible "127.0.0.1")
	# 	local rtrn=$?
	# 	assertTrue "unexpected error; ${rtrn}" ${rtrn}
	# }

	# Load shUnit2
	# shellcheck disable=SC1090
	. "$SHELL_UNIT_2_PATH"

else

	echo "# HINT no shellunit2 script found"

fi
