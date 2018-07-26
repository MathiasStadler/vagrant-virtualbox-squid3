#!/bin/bash

# install bind 9.12

# Exit immediately if a command returns a non-zero status
set -e

# message
echo "# OK ${0##*/} loaded"

readonly BIND_DOWNLOAD_SITE="ftp://ftp.isc.org/isc/bind9/"
readonly TEMP_FILE="/tmp/bind-version.txt"
#

curl -L $BIND_DOWNLOAD_SITE -o $TEMP_FILE

VERSION_NUMBER=$(cat "$TMP_FILE" | awk '{print $9}' | sed 's/-.*$//g' | sed 's/[^0-9.]*//' | sed 's/[a-z].*$//g' | sort -u | sort -V | tail -1)

BIND_TAR="bind-$VERSION_NUMBER.tar.gz"
BIND_VERSION=${SQUID_TAR//.tar.gz/}
# shellcheck disable=SC2034
SQUID_VERSION_STRING=${SQUID_VERSION//-//}
