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

	echo "call download-and-extract"

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
