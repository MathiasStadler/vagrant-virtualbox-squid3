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

ensure_sudo

set +e

$SUDO rndc delzone dynamic-zone.com

set -e

$SUDO service bind9 stop

$SUDO rm -rf /etc/init/bind9

$SUDO rm -rf /etc/systemd/system/bind9

$SUDO rm -rf /etc/bind/*

$SUDO ./install-bind-debian.sh
