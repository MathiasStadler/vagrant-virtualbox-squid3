#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

#DRY_RUN=
DRY_RUN=echo

LOG_FILE="$0_$$_$(date +%F_%H-%M-%S).log"

# message
echo "# OK ${0##*/} loaded" | tee -a "${LOG_FILE}"
#echo "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
printf "# INFO script %s post load script %s\\n" "$0" "${BASH_SOURCE[@]}"

function download-and-extract() {

	# ARG1 = DOWNLOAD_URL
	# ARG2 = DOWNLOAD_FILE
	# ARG3 = TARGET_DIR

	DOWNLOAD_URL=""

	echo "# INFO call download-and-extract" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 DOWNLOAD_URL NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1"
		exit 1
	else
		DOWNLOAD_URL="$1"
		echo "# INFO DOWNLOAD_URL set to '$DOWNLOAD_URL'" | tee -a "${LOG_FILE}"
	fi

	if [ -z ${2+x} ]; then
		echo "# ERROR ARG2 DOWNLOAD_FILE NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		DOWNLOAD_FILE="$2"
		echo "# INFO DOWNLOAD_FILE set to '$DOWNLOAD_FILE'" | tee -a "${LOG_FILE}"

	fi

	if [ -z ${3+x} ]; then
		echo "# ERROR ARG3 TARGET_DIR NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		TARGET_DIR="$3"
		echo "# INFO TARGET_DIR set to '$TARGET_DIR'" | tee -a "${LOG_FILE}"

	fi

	if [ -e "${TARGET_DIR}/${DOWNLOAD_FILE}" ]; then
		echo "# INFO file ${TARGET_DIR}/${DOWNLOAD_FILE} already downloaded"
		echo "# INFO we used this"
	else
		echo "# INFO file ${TARGET_DIR}/${DOWNLOAD_FILE} missing => we must downloaded first"
		$DRY_RUN curl "$DOWNLOAD_URL/${DOWNLOAD_FILE}" -o "$TARGET_DIR/${DOWNLOAD_FILE}"
	fi

	echo "# INFO we extract $TARGET_DIR/${DOWNLOAD_FILE} to ${TARGET_DIR}"
	$DRY_RUN tar xzf "$TARGET_DIR/${DOWNLOAD_FILE}" -C "${TARGET_DIR}"

}

function configure-package() {

	# ARG1 = TARGET_DIR
	# ARG2 = name of config script e.g. configure, config
	# ARG3 = ARRAY of AUTOCONF option

	echo "# INFO call configure-package" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 TARGET_DIR NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		TARGET_DIR="$1"

		echo "# INFO TARGET_DIR set to '$TARGET_DIR'" | tee -a "${LOG_FILE}"

	fi

	if [ -z ${2+x} ]; then
		echo "# ERROR ARG2 = name of config script e.g. configure, config NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		NAME_OF_CONFIG_SCRIPT="$2"
		echo "# INFO ARG2 = name of config script set to '$NAME_OF_CONFIG_SCRIPT'" | tee -a "${LOG_FILE}"
	fi

	if [ -z ${3+x} ]; then
		echo "# ERROR ARG3 ARRAY of AUTOCONF option NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		# for first parameter
		shift
		# for second parameter
		shift
		# see SC2124
		ARRAY_OF_AUTOCONF_OPTION=("$@")
		echo "# INFO ARRAY of AUTOCONF option set to '${ARRAY_OF_AUTOCONF_OPTION[*]}'" | tee -a "${LOG_FILE}"
		echo "# DEBUG receive n count of elements ${#ARRAY_OF_AUTOCONF_OPTION[@]}" | tee -a "${LOG_FILE}"
	fi

	echo "# INFO change to ${TARGET_DIR}"
	cd "${TARGET_DIR}"

	# run configure
	# if ("./$NAME_OF_CONFIG_SCRIPT" "${ARRAY_OF_AUTOCONF_OPTION[@]}" 2>&1 | tee -a "${LOG_FILE}" | grep -v 'error:' >/dev/null); then
	if ($DRY_RUN "./$NAME_OF_CONFIG_SCRIPT" "${ARRAY_OF_AUTOCONF_OPTION[@]}" | tee -a "${LOG_FILE}" | grep -v 'error:' >/dev/null); then

		# if ("./$NAME_OF_CONFIG_SCRIPT" printf "%s" "${ARRAY_OF_AUTOCONF_OPTION[@]}" 2>&1 | tee -a "${LOG_FILE}" | grep -v 'error:' >/dev/null); then

		# printf "%s " "${ARR[@]}"
		echo "# OK $TARGET_DIR/$NAME_OF_CONFIG_SCRIPT ${ARRAY_OF_AUTOCONF_OPTION[*]} run without error" | tee -a "${LOG_FILE}"

		# print config.status -config
		if [ -e "$TARGET_DIR"/config.status ]; then
			"$TARGET_DIR"/config.status --config
		fi

	else
		echo "# ERROR $TARGET_DIR/$NAME_OF_CONFIG_SCRIPT ${ARRAY_OF_AUTOCONF_OPTION[*]} raise ERROR" | tee -a "${LOG_FILE}"
		echo "# INFO see log $LOG_FILE" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	fi

}

##
function configure-package-new-approach() {

	# ARG1 = TARGET_DIR
	# ARG2 = name of config script e.g. configure, config
	# ARG3 = ARRAY of AUTOCONF option

	echo "# INFO call configure-package-new-approach" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 TARGET_DIR NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		TARGET_DIR="$1"

		echo "# INFO TARGET_DIR set to '$TARGET_DIR'" | tee -a "${LOG_FILE}"

	fi

	if [ -z ${2+x} ]; then
		echo "# ERROR ARG2 = name of config script e.g. configure, config NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		NAME_OF_CONFIG_SCRIPT="$2"
		echo "# INFO ARG2 = name of config script set to '$NAME_OF_CONFIG_SCRIPT'" | tee -a "${LOG_FILE}"
	fi

	if [ -z ${3+x} ]; then
		echo "# ERROR ARG3 ARRAY of AUTOCONF option NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		# for first parameter
		shift
		# for second parameter
		shift
		# see SC2124
		ARRAY_OF_AUTOCONF_OPTION=("$@")
		echo "# INFO ARRAY of AUTOCONF option set to '${ARRAY_OF_AUTOCONF_OPTION[*]}'" | tee -a "${LOG_FILE}"
		echo "# DEBUG receive n count of elements ${#ARRAY_OF_AUTOCONF_OPTION[@]}" | tee -a "${LOG_FILE}"
	fi

	echo "# INFO change to ${TARGET_DIR}"
	cd "${TARGET_DIR}"

	# run configure
	if (
		export CPATH=/usr/local/include LIBRARY_PATH=/usr/local/lib LD_LIBRARY_PATH=/usr/local/lib
		$DRY_RUN "./$NAME_OF_CONFIG_SCRIPT" "${ARRAY_OF_AUTOCONF_OPTION[@]}" | tee -a "${LOG_FILE}" >/dev/null
		test ${PIPESTATUS[0]} -eq 0
	); then

		echo "# DEBUG rr $?"
		echo "# OK $TARGET_DIR/$NAME_OF_CONFIG_SCRIPT ${ARRAY_OF_AUTOCONF_OPTION[*]} run without error" | tee -a "${LOG_FILE}"
		# print config.status -config
		if [ -e "$TARGET_DIR"/config.status ]; then
			$DRY_RUN "$TARGET_DIR"/config.status --config
		fi
	else
		echo "# ERROR $TARGET_DIR/$NAME_OF_CONFIG_SCRIPT ${ARRAY_OF_AUTOCONF_OPTION[*]} raise ERROR" | tee -a "${LOG_FILE}"
		echo "# INFO see log $LOG_FILE" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	fi

}
##

function make-package() {

	# ARG1 = TARGET_DIR

	echo "# INFO call make-package" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 TARGET_DIR NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		TARGET_DIR="$1"
		echo "# INFO TARGET_DIR set to '$TARGET_DIR'" | tee -a "${LOG_FILE}"
	fi

	# change to build dir
	cd "${TARGET_DIR}"

	# calculate cpu count
	NB_CORES=$(grep -c '^processor' /proc/cpuinfo)

	# make
	echo "# ACTION start make with -j $((NB_CORES + 2)) -l ${NB_CORES}" | tee -a "${LOG_FILE}"

	if ($DRY_RUN make -j$((NB_CORES + 2)) -l"${NB_CORES}" | tee -a "${LOG_FILE}" | grep -v 'error:' >/dev/null); then
		echo "# OK make finished without error" | tee -a "${LOG_FILE}"
	else
		echo "# ERROR make raise a error" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	fi

	echo "# INFO make-packages finished" | tee -a "${LOG_FILE}"

}

function make-install-package() {

	# ARG1 = TARGET_DIR
	# ARG2 = MAKE_TARGET

	echo "# INFO call make-install-package" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 TARGET_DIR NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		TARGET_DIR="$1"
		echo "# INFO TARGET_DIR set to '$TARGET_DIR'" | tee -a "${LOG_FILE}"
	fi

	if [ -z ${2+x} ]; then
		echo "# ERROR ARG2 = MAKE_TARGET NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		MAKE_TARGET="$2"
		echo "# INFO MAKE_TARGET set to '$MAKE_TARGET'" | tee -a "${LOG_FILE}"
	fi

	echo "# ACTION make $MAKE_TARGET" | tee -a "${LOG_FILE}"

	if (sudo make "$MAKE_TARGET" | tee -a "${LOG_FILE}" | grep -v 'error:' >/dev/null); then
		echo "# OK make  $MAKE_TARGET finished without error" | tee -a "${LOG_FILE}"
	else
		echo "# ERROR make $MAKE_TARGET raise a error" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	fi

	echo "# INFO make-install-packages finished" | tee -a "${LOG_FILE}"
}

function run-ldconfig() {

	# NO ARGS
	echo "# INFO call run-ldconfig" | tee -a "${LOG_FILE}"

	if (sudo ldconfig); then
		echo "# INFO ldconfig run successful"
	else
		echo "# ERROR run  ldconfig raise a error"
		echo "# EXIT 1"
		exit 1
	fi
}

# call function
run-ldconfig

function install-packages() {

	# ARG1 = ARRAY OF INSTALL PACKAGES

	echo "# INFO call install-packages" | tee -a "${LOG_FILE}"

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 ARRAY OF INSTALL PACKAGES NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		ARRAY_OF_INSTALL_PACKAGES=("$@")
		echo "# INFO ARRAY of ARRAY OF INSTALL PACKAGES set to '${ARRAY_OF_INSTALL_PACKAGES[*]}'" | tee -a "${LOG_FILE}"
		echo "# DEBUG we will install ${#ARRAY_OF_INSTALL_PACKAGES[@]} package(s)" | tee -a "${LOG_FILE}"
	fi

	if (
		export DEBIAN_FRONTEND=noninteractive &&
			TERM=linux &&
			sudo apt-get update | tee -a "${LOG_FILE}" >/dev/null
		# TODO check it is nesseccary at each run
		# sudo apt-get upgrade -y | tee -a "${LOG_FILE}" >/dev/null
		# sudo apt-get autoremove -y | tee -a "${LOG_FILE}" >/dev/null

		echo "# DEBUG exec sudo apt-get install -y --no-install-recommends ${ARRAY_OF_INSTALL_PACKAGES[*]}" | tee -a "${LOG_FILE}" >/dev/null

		for install_package in "${ARRAY_OF_INSTALL_PACKAGES[@]}"; do
			echo "# ACTION  install package $install_package"
			export DEBIAN_FRONTEND=noninteractive && sudo apt-get install -y --no-install-recommends "$install_package" | tee -a "${LOG_FILE}" >/dev/null
		done

	); then
		echo "# OK package ${ARRAY_OF_INSTALL_PACKAGES[*]} installed" | tee -a "${LOG_FILE}"
	else
		echo "# ERROR packages NOT installed" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	fi

}

function file-download-from-url() {

	echo "# INFO call file-download" | tee -a "${LOG_FILE}"

	# ARG1 = DOWNLOAD_URL
	# ARG2 = DOWNLOAD_FILE
	# ARG3 = TARGET_DIR

	DOWNLOAD_URL=""

	if [ -z ${1+x} ]; then
		echo "# ERROR ARG1 DOWNLOAD_URL NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1"
		exit 1
	else
		DOWNLOAD_URL="$1"
		echo "# INFO DOWNLOAD_URL set to '$DOWNLOAD_URL'" | tee -a "${LOG_FILE}"
	fi

	if [ -z ${2+x} ]; then
		echo "# ERROR ARG2 DOWNLOAD_FILE NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		DOWNLOAD_FILE="$2"
		echo "# INFO DOWNLOAD_FILE set to '$DOWNLOAD_FILE'" | tee -a "${LOG_FILE}"

	fi

	if [ -z ${3+x} ]; then
		echo "# ERROR ARG3 TARGET_DIR NOT set" | tee -a "${LOG_FILE}"
		echo "# EXIT 1" | tee -a "${LOG_FILE}"
		exit 1
	else
		TARGET_DIR="$3"
		echo "# INFO TARGET_DIR set to '$TARGET_DIR'" | tee -a "${LOG_FILE}"

	fi

	echo "# ACTION  change to $TEMP_DIR"

	if [ -e "${TARGET_DIR}/${DOWNLOAD_FILE}" ]; then
		echo "# INFO file ${TARGET_DIR}/${DOWNLOAD_FILE} already downloaded"
		echo "# INFO we used this"
	else
		echo "# INFO file ${TARGET_DIR}/${DOWNLOAD_FILE} missing => we must downloaded first"
		curl "$DOWNLOAD_URL" -o "$TEMP_DIR/${DOWNLOAD_FILE}"

		echo "# ACTION copy ${DOWNLOAD_FILE} to $TARGET_DIR"
		sudo cp "$TEMP_DIR/${DOWNLOAD_FILE}" "$TARGET_DIR/${DOWNLOAD_FILE}"
	fi

}
