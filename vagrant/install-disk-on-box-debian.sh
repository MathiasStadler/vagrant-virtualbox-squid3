#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# wait on parallel provision
# wait max 10
counter=1
until
	[ ! -e /home/vagrant/settings/setting-disk-on-box-debian.sh ]
do
	if [ $counter -le 10 ]; then
		break
	fi
	echo "Wait a second"
	sleep 1
	((counter++))
done

bash +x /home/vagrant/settings/setting-disk-on-box-debian.sh "sdb" "cache0"
bash +x /home/vagrant/settings/setting-disk-on-box-debian.sh "sdc" "cache1"
