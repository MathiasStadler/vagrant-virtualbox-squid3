#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# message
echo "# OK ${0##*/} loaded"
#echo "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
printf "# INFO script %s post load script %s\\n" "$0" "$BASH_SOURCE"

function download-and-extract() {

	# ARG1 = DOWNLOAD_URL
	# ARG2 = DOWNLOAD_FILE
	# ARG3 = TARGET_DIR

	DOWNLOAD_URL=""

	echo "# INFO call download-and-extract"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 DOWNLOAD_URL NOT set"
		echo "# EXIT 1"
		exit 1
	else
		DOWNLOAD_URL="$1"
		echo "# INFO DOWNLOAD_URL set to '$DOWNLOAD_URL'"

	fi

	if [ -z ${2+x} ]; then
		echo "# ERROR ARG2 DOWNLOAD_FILE NOT set"
		echo "# EXIT 1"
		exit 1
	else
		DOWNLOAD_FILE="$2"
		echo "# INFO DOWNLOAD_FILE set to '$DOWNLOAD_FILE'"

	fi

	if [ -z ${3+x} ]; then
		echo "# ERROR ARG3 TARGET_DIR NOT set"
		echo "# EXIT 1"
		exit 1
	else
		TARGET_DIR="$3"
		echo "# INFO TARGET_DIR set to '$TARGET_DIR'"

	fi

	curl "$DOWNLOAD_URL/${DOWNLOAD_FILE}" -o "$TARGET_DIR/${DOWNLOAD_FILE}"

	tar xzf "$TARGET_DIR/${DOWNLOAD_FILE}" -C "${TARGET_DIR}"

}

function configure-package() {

	# ARG1 = TARGET_DIR
	# ARG2 = ARRAY of AUTOCONF option
	# ARG3 = name of config script e.g. configure, config

	echo "# INFO call configure-package"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 TARGET_DIR NOT set"
		echo "# EXIT 1"
		exit 1
	else
		TARGET_DIR="$1"
		echo "# INFO TARGET_DIR set to '$TARGET_DIR'"

	fi

	if [ -z ${2+x} ]; then
		echo "# ERROR ARG2 ARRAY of AUTOCONF option NOT set"
		echo "# EXIT 1"
		exit 1
	else
		ARRAY_OF_AUTOCONF_OPTION="$2"
		echo "# INFO ARRAY of AUTOCONF option set to '$DOWNLOAD_FILE'"

	fi

	if [ -z ${3+x} ]; then
		echo "# ERROR ARG3 = name of config script e.g. configure, config NOT set"
		# echo "# EXIT 1"
		# exit 1
		# not set
		echo "# INFO name of config script not set"
		echo "# ACTION set to default configure"
		NAME_OF_CONFIG_SCRIPT="configure"
		echo "# INFo name of config script set to '$NAME_OF_CONFIG_SCRIPT'"

	else

		NAME_OF_CONFIG_SCRIPT="$3"
		echo "# INFO ARG3 = name of config script  set to '$NAME_OF_CONFIG_SCRIPT'"

	fi

	# run configure
	if ($TARGET_DIR/$NAME_OF_CONFIG_SCRIPT "${ARRAY_OF_AUTOCONF_OPTION[@]}" | tee -a "${LOG_FILE}" >/dev/null); then
		echo "# OK ./configure ${ARRAY_OF_AUTOCONF_OPTION} run without error"

		# print config.status -config
		"$TARGET_DIR"/config.status --config

	else
		echo "# ERROR ./configure ${ARRAY_OF_AUTOCONF_OPTION} raise ERROR"
		echo "# EXIT 1"
		exit 1
	fi

}
