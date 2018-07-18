#!/bin/bash

# create one partition hole disk

# Exit immediately if a command returns a non-zero status
set -e
# from here
# https://stackoverflow.com/questions/192319/how-do-i-know-the-script-file-name-in-a-bash-script
echo
echo "# script name ------------>  ${0##*/} "
echo "# called with arguments -->  ${*}     "
echo "# argument \$1 ----------->  $1       "
echo "# argument \$2 ----------->  $2       "
echo "# script path ------------>  ${0}     "
echo "# script parent path ----->  ${0%/*}  "
echo

# argument
DEVICE="$1"
MOUNT_POINT="$2"

function create_partition_table() {

	echo "create partition table for device /dev/$1"
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

	echo "Create new file system /dev/${1}1"
	sudo mkfs.ext4 "/dev/${1}1"

}

function create_mount_point() {

	echo "Create new mount point ${1}"
	sudo mkdir -p "/${1}"

}

function mount_device_on_mount_point() {

	echo "mount /dev/${1}1 on ${2}"
	sudo mount -t ext4 "/dev/${1}1" "/${2}"

}

function create_etc_ftab_entry() {

	UUID="$(find /dev/disk/by-uuid/ -type l -exec ls -l {} \; | grep "${1}"1 | awk '{print $9}' | sed 's#/dev/disk/by-uuid/##g')"
	echo "create this item in /etc/fstab"
	echo "UUID=${UUID} /${2}               ext4    errors=remount-ro 0       1"
	echo "UUID=${UUID} /${2}               ext4    errors=remount-ro 0       1" | sudo tee -a /etc/fstab

}

function get_device_info() {

	# from here
	# https://unix.stackexchange.com/questions/52215/determine-the-size-of-a-block-device
	BLOCKSIZE="$(sudo blockdev --getbsz "/dev/${1}1")"
	DEVICE_SIZE="$(sudo fdisk -l /dev/"${1}" | grep -m1 ^Disk | awk '{print $3 " " $4}')"
	PARTITION_SIZE="$(sudo fdisk -l /dev/"${1}"1 | grep -m1 ^Disk | awk '{print $3 " " $4}')"

	echo
	echo "# block size of device -> /dev/${1} => ${BLOCKSIZE}      "
	echo "# size of device -------> /dev/${1} => ${DEVICE_SIZE}    "
	echo "# size of partition ----> /dev/${1} => ${PARTITION_SIZE} "
}

# check if running on virtual box
if (lsmod | grep vboxguest); then

	echo "# Script run on a virtual box"

	create_partition_table "${DEVICE}"
	make_filesystem "${DEVICE}"
	create_mount_point "${MOUNT_POINT}"
	mount_device_on_mount_point "${DEVICE}" "${MOUNT_POINT}"
	create_etc_ftab_entry "${DEVICE}" "${MOUNT_POINT}"
	get_device_info "${DEVICE}"
	exit 0
else

	echo "# No vboxguest kernel module found"
	echo "# ERROR This script should run only of a virtual box guest"
	exit 1

fi
