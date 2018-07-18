#!/bin/bash

# create one partition hole disk

# Exit immediately if a command returns a non-zero status
set -e

DEVICE="$1"
MOUNT_POINT="$2"

function create_partition_table() {

	set +e

	sudo fdisk -u "/dev/$1" <<EOF
n
p
1


w
EOF

	sync

	set -e

}

function make_filesystem() {

	sudo mkfs.ext4 "/dev/${1}1"

}

function create_mount_point() {

	sudo mkdir -p "${1}"

}

function mount_device_on_mount_point() {

	sudo mount -t ext4 "/dev/${1}1" "${2}"

}

function create_etc_ftab_entry() {

	UUID="$(find /dev/disk/by-uuid/ -name "*" -exec ls -l {} \; | grep "${1}"1 | awk '{print $9}')"
	echo "UUID=${UUID} /${2}               ext4    errors=remount-ro 0       1" | sudo tee -a /etc/fstab

}

# check if running on virtual box
if (lsmod | grep vboxguest); then

	echo "script run on a virtual box"

	create_partition_table "${DEVICE}"
	make_filesystem "${DEVICE}"
	create_mount_point "${MOUNT_POINT}"
	mount_device_on_mount_point "${DEVICE}" "${MOUNT_POINT}"
	create_etc_ftab_entry "${DEVICE}" "${MOUNT_POINT}"
	exit 0
else

	echo "No vboxguest kernel module found"
	echo "ERROR This script should run only of a virtual box"
	exit 1

fi
