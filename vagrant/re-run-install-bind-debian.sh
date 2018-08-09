#!/bin/bash

# re run install install-bind-debian
# without create a new vm
# more for test ans time saving

# Exit immediately if a command returns a non-zero status
set -e

# ensure_sudo
ensure_sudo() {
	if [ "$(id -u)" != "0" ]; then
		SUDO="sudo" # Modified as suggested below.

	fi
}

# call function
ensure_sudo

# git check update
# from here
# https://stackoverflow.com/questions/3258243/check-if-pull-needed-in-git

LOCAL_GIT_REV="$(git rev-parse HEAD)"
REMOTE_GIT_REV="$(git ls-remote "$(git rev-parse --abbrev-ref @\{u\} |
	sed 's/\// /g')" | cut -f1)"
if [ "$LOCAL_GIT_REV" = "$REMOTE_GIT_REV" ]; then
	echo "# INFO git is  up to date"
else
	echo "# HINT git not up to date"
	read -r -p "You want make git pull? [Y/n]" response
	response=${response,,} # convert answer to lower letter
	if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
		git pull
		echo "# PLEASE restart script"
		exit 0
	fi
fi

set +e

$SUDO rndc delzone dynamic-zone.com

set -e

$SUDO service bind9 stop

$SUDO rm -rf /etc/init/bind9

$SUDO rm -rf /etc/systemd/system/bind9

$SUDO rm -rf /etc/bind/*

$SUDO ./install-bind-debian.sh
