#!/bin/bash

echo "# ACTION run test"

# generate a 12 char random string
RANDOM_STRING=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

# set variable
DDNS_NAME_SERVER="127.0.0.1"
DDNS_ZONE="TEST-$RANDOM_STRING"

echo "# ACTION create zone"

bash -x ./static-zone-create.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE"

echo "# ACTION delete zone"

bash -x ./static-zone-delete.sh "$DDNS_NAME_SERVER" "$DDNS_ZONE"
