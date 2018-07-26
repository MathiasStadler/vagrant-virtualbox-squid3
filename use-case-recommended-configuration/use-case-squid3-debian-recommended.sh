#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

readonly TEMP_DIR="/tmp"

# BUILD_DIR for tar extract, make ...
readonly BUILD_DIR=$TEMP_DIR

readonly LOG_FILE="${BUILD_DIR}/build_$$_$(date +%F_%H-%M-%S).log"

# CONSTANTS

readonly INSTALL_PACKAGE_FINAL_LIST="${BUILD_DIR}/install-final-package.list"
readonly INSTALL_DEFAULT_PACKAGE="${BUILD_DIR}/install-default-package.list"
readonly INSTALL_PACKAGE_USE_CASE="${BUILD_DIR}/install-package-use-case.list"
readonly SQUID_CONF="${BUILD_DIR}/squid.conf"

# import project variables
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; else
	echo "# OK WORK DIR => $PWD"
fi

# SETTINGS_DIR="${DIR}/settings"
SETTINGS_DIR="../../settings"
if [[ ! -d "$SETTINGS_DIR" ]]; then
	echo "# ERROR SETTINGS_DIRECTORY NOT found => $SETTINGS_DIR"
	# SETTINGS_DIR="${DIR}/settings"
	SETTINGS_DIR="$HOME/settings"
	if [[ ! -d "$SETTINGS_DIR" ]]; then
		echo "# ERROR SETTINGS_DIRECTORY NOT found => $SETTINGS_DIR"
		echo "# EXIT 1"
		SETTINGS_DIR="/home/vagrant/settings"
		if [[ ! -d "$SETTINGS_DIR" ]]; then
			echo "# ERROR SETTINGS_DIRECTORY NOT found => $SETTINGS_DIR"
			echo "# EXIT 1"
			exit 1

		else
			echo "# OK SETTINGS_DIRECTORY => $SETTINGS_DIR"
		fi

	else
		echo "# OK SETTINGS_DIRECTORY => $SETTINGS_DIR"
	fi

else
	echo "# OK settings dir $SETTINGS_DIR"
fi

# shellcheck disable=SC1090,SC1091
# source "$SETTINGS_DIR/ccache-handling-debian.sh"

# shellcheck disable=SC1090,SC1091
# source "$SETTINGS_DIR/squid_version.sh"

# shellcheck disable=SC1090,SC1091
# source "$SETTINGS_DIR/squid-handling-debian.sh"

# shellcheck disable=SC1090,SC1091
# source "$SETTINGS_DIR/compare_package_list.sh"

# shellcheck disable=SC1090,SC1091
source "$SETTINGS_DIR/use-case-squid3-debian-master.sh"

# squid configuration
# https://wiki.squid-cache.org/SquidFaq/ConfiguringSquid

# minimal 3.5 config
# https://wiki.squid-cache.org/SquidFaq/ConfiguringSquid#Squid-3.5_default_config

#######################################
# Modify for use case start############
#######################################
function squid-use-case-package-list() {

	cat <<EOF >${INSTALL_PACKAGE_USE_CASE}
	# empty
	# add only packages for the use case
	# entry package name without default bash comment sign

EOF

}

function squid-use-case-additional-autoconf-configure() {

	# add only autoconf config for this use case
	array_add_one_configure_options=()

}

function squid-use-case-additional-config-file() {

	# append cache_dir entry to ${SQUID_CONF}
	# echo "# ACTION Add use case config to ${SQUID_CONF}"
	echo "# START USE CASE CONFIG " | tee -a "${SQUID_CONF}"
	echo "# END USE CASE CONFIG" | tee -a "${SQUID_CONF}"

}

function squid-use-case-check() {
	# check use case

	squid-default-check
}
#######################################
# Modify for use case end  ############
#######################################

# call funtion action in use-case-squid3-debian-master.sh
action

echo "# Finished"
echo "# EXIT 0"
exit 0
