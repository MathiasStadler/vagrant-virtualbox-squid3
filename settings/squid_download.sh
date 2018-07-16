#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

function squid_download_and_extract() {

	echo "=> call squid_download_and_extract"
	curl http://www.squid-cache.org/Versions/v3/3.5/${SQUID_TAR} -o /tmp/${SQUID_TAR}

	tar xzf /tmp/${SQUID_TAR} -C /tmp

}
