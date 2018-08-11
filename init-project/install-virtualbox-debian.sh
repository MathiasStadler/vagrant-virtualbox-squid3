#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

SETTINGS_DIR="../settings"

# shellcheck disable=SC1090
source "$SETTINGS_DIR"/utility-bash.sh

# call function
ensure-sudo

# load utility-method.sh from same directory
# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/utility-methods-debian.sh"

# package to install
# for command add-apt-repository
array_install_packages=(
	"software-properties-common"
)

# call function
install-packages "${array_install_packages[@]}"

# add repository
$SUDO add-apt-repository "deb http://download.virtualbox.org/virtualbox/debian stretch contrib"

# add key and install
$SUDO wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
$SUDO wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

# package to install
array_install_packages=(
	"virtualbox-5.2"
)

#call function
install-packages "${array_install_packages[@]}"
