#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

sudo /home/vagrant/settings/setting-disk-on-box-debian.sh "sdb" "cacheB"
sudo /home/vagrant/settings/setting-disk-on-box-debian.sh "sdc" "cacheC"
