#!/bin/bash

echo "# ACTION run test"

# generate a 12 char random string
RANDOM_STRING=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

# set variable
DDNS_NAME_SERVER="127.0.0.1"
DDNS_ZONE="TEST-${RANDOM_STRING}.com"

# regex from here
# https://stackoverflow.com/questions/15268987/bash-based-regex-domain-name-validation
# last entry

if (echo "DDNS_ZONE" | grep -P "^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$"); then
	echo "# INFO domain name $DDNS_ZONE valid"
else
	echo "# ERROR domain name $DDNS_ZONE no valid "
	echo "# EXIT 1"
	exit 1
fi

echo "# ACTION create zone"

bash -x ./static-zone-create.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE"

echo "# ACTION delete zone"

bash -x ./static-zone-delete.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE"

exit 0
