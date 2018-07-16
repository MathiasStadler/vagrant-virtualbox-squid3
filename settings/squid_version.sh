#!/bin/bash
# settings will be import from other script

# Exit immediately if a command returns a non-zero status
set -e

SQUID_TAR="squid-3.5.27.tar.gz"
SQUID_VERSION=${SQUID_TAR//.tar.gz/}
# shellcheck disable=SC2034
SQUID_VERSION_STRING=${SQUID_VERSION//-//}
