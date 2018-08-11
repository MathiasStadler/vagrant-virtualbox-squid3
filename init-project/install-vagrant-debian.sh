#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# shellcheck disable=SC1091
source ../settings/utility-bash.sh

# call function
ensure-sudo

# load utility-method.sh from same directory
# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/utility-methods-debian.sh"

TEMP_DIR="/tmp"

# DOCUMENTATION curl https://releases.hashicorp.com/vagrant/2.1.2/vagrant_2.1.2_x86_64.deb -O

file-download-from-url https://releases.hashicorp.com/vagrant/2.1.2/ vagrant_2.1.2_x86_64.deb $TEMP_DIR

$SUDO dpkg -i $TEMP_DIR/vagrant_2.1.2_x86_64.deb

# install vagrant plugins
vagrant plugin install vagrant-vbguest
