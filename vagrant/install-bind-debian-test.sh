#!/bin/bash

set -e

function check-function-bind-server() {

	echo "# INFO BIND server check function"
	if (dig heise.de @127.0.0.1); then
		echo "# INFO server resolv address successful "
	else
		echo "# ERROR address lookup raise a error"
		echo "# INFO Look at cat /var/log/syslog for hits and errors"
		echo "# EXIT 1"
		exit 1
	fi

	echo "# ACTION stop server"

	if (sudo service bind9 stop); then
		echo "# INFO bind9 stop"
	else
		echo "# ERROR bind9 stop raise a error"
		echo "# INFO Look at cat /var/log/syslog for hits and errors"
		echo "# EXIT 1"
		exit 1
	fi

	echo "# INFO Fail test BIND server check function"
	if ! (dig heise.de @127.0.0.1); then
		echo "# INFO Ok server not resolv address successful "
		echo "# INFO server should down"
	else
		echo "# ERROR address lookup works without running a server that is a error"
		echo "# ERROR check which server resolv this address"
		echo "# EXIT 1"
		exit 1
	fi

	echo "# ACTION start bind9 "

	if (sudo service bind9 start); then
		echo "# INFO bind9 started"
	else
		echo "# ERROR bind9 start raise a error"
		echo "# INFO Look at cat /var/log/syslog for hits and errors"
		echo "# EXIT 1"
		exit 1
	fi

	echo "# INFO BIND server check function 2nd Pass"
	if (dig heise.de @127.0.0.1); then
		echo "# INFO server resolv address successful "
	else
		echo "# ERROR address lookup raise a error"
		echo "# INFO Look at cat /var/log/syslog for hits and errors"
		echo "# EXIT 1"
		exit 1
	fi

}

check-function-bind-server
