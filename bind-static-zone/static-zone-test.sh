#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# shellcheck disable=SC1091
source ../settings/utility-bash.sh

# call function
ensure-sudo

# shellcheck disable=SC1091
source ./static-zone-parameter.sh

# shellcheck disable=SC1091
source ../settings/utility-dns-debian.sh

function test-nsupdate-round-trip-add-record() {

	TEST_FOLDER="/nsupdate_tests"

	echo "#ACTION create sub folder $TEST_FOLDER"
	mkdir -p "$HOME$TEST_FOLDER"

	# create NSUPDATE_ADD_HOST_SCRIPT
	NSUPDATE_ADD_HOST_SCRIPT="$HOME$TEST_FOLDER/nsupdate_add_host.sh"

	echo "# ACTION write $NSUPDATE_ADD_HOST_SCRIPT to $HOME$TEST_FOLDER"

	$SUDO tee -a "$NSUPDATE_ADD_HOST_SCRIPT" <<EOF
#!/bin/bash
#Defining Variables
DNS_SERVER="localhost"
DNS_ZONE="$DDNS_TEST_ZONE."
HOST="test.example.com"
IP="192.168.178.100"
TTL="60"
RECORD=" \$HOST \$TTL A \$IP"
echo "
server \$DNS_SERVER
zone \$DNS_ZONE
debug
update add \$RECORD
show
send" | nsupdate -k $ETC_BIND_DDNS_NSUPDATE_FILE
EOF

	echo "# ACTION set execute for $NSUPDATE_ADD_HOST_SCRIPT"
	# execute script NSUPDATE_ADD_HOST_SCRIPT
	$SUDO chmod +x "$NSUPDATE_ADD_HOST_SCRIPT"

	echo "# ACTION reload zone $DDNS_TEST_ZONE"
	# activate changes

	echo "# ACTION execute nsupdate of zone $DDNS_TEST_ZONE"
	if ("$SUDO" "$NSUPDATE_ADD_HOST_SCRIPT"); then
		echo "# OK nsupdate of zone "
	else
		echo "# ERROR nsupdate of zone"
		echo "# EXIT 1"
		exit 1
	fi

}

# call function
test-nsupdate-round-trip-add-record

function test-nsupdate-round-trip-delete-record() {

	# PTR
	# https://superuser.com/questions/977132/when-using-nsupdate-to-update-both-a-and-ptr-records-why-do-i-get-update-faile

	echo "# INFO call test-nsupdate-round-trip"

	TEST_FOLDER="/nsupdate_tests"

	echo "#ACTION create sub folder $TEST_FOLDER"
	mkdir -p "$HOME/$TEST_FOLDER"

	# delete test record
	NSUPDATE_DELETE_RECORD_SCRIPT="$HOME$TEST_FOLDER/nsupdate-delete-record.sh"

	cat <<EOF >"$NSUPDATE_DELETE_RECORD_SCRIPT"
#!/bin/bash
#Defining Variables
DNS_SERVER="localhost"
DNS_ZONE="$DDNS_TEST_ZONE."
HOST="test.$DDNS_TEST_ZONE."
IP="192.168.178.100"
echo "
server \$DNS_SERVER
zone \$DNS_ZONE
debug
update delete \$HOST A
show
send" | nsupdate -k $ETC_BIND_DDNS_NSUPDATE_FILE
EOF

	# set execute
	echo "#ACTION set execute $NSUPDATE_DELETE_RECORD_SCRIPT"
	chmod +x "$NSUPDATE_DELETE_RECORD_SCRIPT"

	# execute $NSUPDATE_DELETE_RECORD_SCRIPT

	if ($NSUPDATE_DELETE_RECORD_SCRIPT); then
		echo "# OK nsupdate delete host "
	else
		echo "# ERROR nsupdate delete host raise a error"
		echo "# INFO the return code was $?"
		echo "# INFO return code => 1:	nsupdate calling error"
		echo "# INFO return code => 2:	DDNS protocol error"
		#echo "# EXIT 1"
		#exit 1
	fi

}

# call function
test-nsupdate-round-trip-delete-record
